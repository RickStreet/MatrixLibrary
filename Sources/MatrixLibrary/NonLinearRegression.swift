//
//  NonLinearRegression.swift
//  Transform
//
//  Created by Rick Street on 7/10/19.
//  Copyright © 2019 Rick Street. All rights reserved.
//

import Foundation

/// Non-Linear Regression for X Y data
public class NLR {
    // Input vars
    var fn: ([Double], Double) -> Double
    var initParams: [Double]
    var xValues: [Double]
    var yValues: [Double]
    
    public var confidenceMultiplier = 2.0  // Standard Deviation multiplier for outlier calc (2 = 90% confidence)
    public var converged = false

    
    // Results
    public var params: Matrix
    public var r2 = 0.0
    public var iterations = 0
    public var variance = 0.0 // variance of redidules
    
    public var standardDeviation: Double {
        get {
            return sqrt(variance)
        }
    }
    
    public var outliers = [(x: Double, y: Double)]()

    let smallNumber = 1e-6

    
    func fit() {
        let maxNormG = 1.0e-12// max error for infinite norm of G
        let maxNormH = 1.0e-17
        let tau = 1.0e-6
        let maxIterations = 50000
        
        
        var k = 0 // ieteration
        var v = 2.0
        
        let numberParams = initParams.count
        let numberPoints = xValues.count
        
        // let params = Matrix(rows: numberParams, cols: 1)
        params.array = initParams  // set params to initial guess
        
        var j = Jacobian(fn: fn, params: params.array, xValues: xValues)
        // print("j:")
        // print(j.description)
        var jTranspose = j.transpose()
        
        var residuals = getResiduals(fn: fn, params: params.array, xValues: xValues, yValues: yValues)
        
        var a = jTranspose.multiplyMatrix(j)
        // print("a0:")
        // print(a.description)
        
        var g = jTranspose.multiplyMatrix(residuals)
        // print("g0:")
        // print(g.description)
        
        var aDiag = Matrix(rows: 0, cols: 0)
        
        if let d = a.diagonal {
            aDiag = d
        } else {
            print("Non square a")
        }
        
        var mu = tau * aDiag.maxValue   // damping parameter
        
        var found = g.infinityNorm <= maxNormG
        
        while !found && k <= maxIterations {
            k += 1
            // print("iteration \(k)")
            
            // print("mu\(k): \(mu)")
            
            // identity matrix with diagonal = mu: muI
            let muI = Matrix(rows: numberParams, cols: numberParams)
            for i in 0 ..< numberParams {
                muI[i, i] = mu
            }
            // print("muI")
            // print(muI.description)
            
            let muA = a.add(matrix: muI)
            // print("muA")
            // print(muA.description)
            // let nG = g.multiply(scalar: -1.0)
            
            let h = muA.invert().multiplyMatrix(g.multiply(scalar: -1.0))
            // print()
            // print("h\(k):")
            // print(h.description)
            
            // Check if found
            if h.l2Norm <= maxNormH * (params.l2Norm + maxNormH) {
                print("solution found")
                print(params.description)
                break  // found solution
            }
            
            
            let newParams = params.add(matrix: h)
            // print("new params\(k):")
            // print(newParams.description)
            
            
            let newResiduals = getResiduals(fn: fn, params: newParams.array, xValues: xValues, yValues: yValues)
            // print("new residuals\(k):")
            // print(newResiduals.description)
            
            let rhoNumerator = (residuals.dotProduct(residuals) / 2.0 - newResiduals.dotProduct(newResiduals) / 2.0)
            // print("residLS  \(residuals.dotProduct(residuals) / 2.0)")
            // print("newResidLS \(newResiduals.dotProduct(newResiduals) / 2.0)")
            
            let c = h.multiply(scalar: mu).subtract(matrix: g)
            let rhoDenominator = h.dotProduct(c) / 2.0
            
            // print("rNum \(rhoNumerator)")
            // print("rDen \(rhoDenominator)")
            let rho = rhoNumerator / rhoDenominator
            
            // print("rho \(rho)")
            
            if rho > 0.0 {
                // step acceptable
                params.array = newParams.array
                // print("params:")
                // print(params.description)
                
                j = Jacobian(fn: fn, params: params.array, xValues: xValues)
                jTranspose = j.transpose()
                
                residuals = getResiduals(fn: fn, params: params.array, xValues: xValues, yValues: yValues)
                
                a = jTranspose.multiplyMatrix(j)
                g = jTranspose.multiplyMatrix(residuals)
                
                found = g.infinityNorm <= maxNormG
                
                mu = mu * max(1.0 / 3.0, 1 - pow((2 * rho - 1), 3) )
                v = 2.0
                
            } else {
                mu = mu * v
                v *= 2.0
            }
            // print("new mu\(k): \(mu)")
        }
        print("Number of LM interations: \(k)")
        let yMatrix = Matrix(rows: numberPoints, cols: 1)
        yMatrix.array = yValues
        var r2Denominator = 0.0
        let yMean = yMatrix.meanValue
        for y in yValues {
            r2Denominator += (y - yMean) * (y - yMean)
        }
        
        let finalResiduals = getResiduals(fn: fn, params: params.array, xValues: xValues, yValues: yValues)
        // var r2: Double
        if k < maxIterations {
            let sSE = finalResiduals.dotProduct(finalResiduals) // Sum of squared residuals
            variance = sSE / Double((numberPoints + numberParams))
            r2 = 1.0 - sSE / r2Denominator
            converged = true
        } else {
            r2 = -1.0  // Neg r2 signifies soln did not converge
            converged = false
        }
        
        // round significant digits for error
        for i in 0 ..< numberParams {
            params.array[i] = params.array[i].roundTo(places: 9)
        }
        iterations = k
        
        // find outliers if converged
        if r2 > 0 {
            for (i, resid) in finalResiduals.array.enumerated() {
                if !(resid < standardDeviation * confidenceMultiplier || resid < smallNumber) {
                    outliers.append((xValues[i], yValues[i]))
                    print("outlier: \(xValues[i]), \(yValues[i])  resid \(resid)")
                }
            }
        }
    }
    
    private func Jacobian(fn: ([Double], Double) -> Double, params: [Double], xValues: [Double]) -> Matrix {
        let matrix = Matrix(rows: xValues.count, cols: params.count)
        for (i, x) in xValues.enumerated() {
            for j in 0 ..< params.count {
                let delta = params[j] / 100000.0
                var params1 = params
                var params2 = params
                params1[j] -= delta
                params2[j] += delta
                // for LM to work need the negative of the derivative
                matrix[i, j] = (fn(params1, x) - fn(params2, x)) / (2.0 * delta)
            }
        }
        return matrix
    }
    
    private func getResiduals(fn: ([Double], Double) -> Double, params: [Double], xValues: [Double], yValues: [Double]) -> Matrix {
        var resid = [Double]()
        for (i, x) in xValues.enumerated() {
            resid.append(yValues[i] - fn(params, x))
        }
        let rMatrix = Matrix(rows: xValues.count, cols: 1)
        rMatrix.array = resid
        return rMatrix
    }
    
    public init(fn: @escaping ([Double], Double) -> Double, initParams: [Double], xValues: [Double], yValues: [Double]) {
        self.fn = fn
        self.initParams = initParams
        self.xValues = xValues
        self.yValues = yValues
        params = Matrix(rows: initParams.count, cols: 1)
        fit()
    }
    
}

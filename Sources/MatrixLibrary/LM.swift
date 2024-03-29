//
//  LM.swift
//  Transform
//
//  Created by Rick Street on 5/4/17.
//  Copyright © 2017 Rick Street. All rights reserved.
//
//  Levenberg-Marquardt Method to find least squars fit for non-linear equations
//          "Mar-Quart"
//

import Foundation
import DialogKit

func Jacobian(fn: ([Double], Double) -> Double, params: [Double], xValues: [Double]) -> Matrix {
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

func getResiduals(fn: ([Double], Double) -> Double, params: [Double], xValues: [Double], yValues: [Double]) -> Matrix {
    var resid = [Double]()
    for (i, x) in xValues.enumerated() {
        resid.append(yValues[i] - fn(params, x))
    }
    let rMatrix = Matrix(rows: xValues.count, cols: 1)
    rMatrix.array = resid
    return rMatrix
}


/**
 LM finds the lest squars fit for a non-linear equation
 - Parameters:
 - fn: Funxtion to fit in form {(coef: [Double], x: Double) -> Double}
 - coef: Array of doubles holding coeficients for fn
 - x: x-value to evaluate fn
 - initParams: guess at parameter values
 - xValues: Array of x-values to fit
 - yValues: Array of y-values to fit
 - returns: Array with parameters that give best least squares fit
 */
func levenbergMarquardt(fn: ([Double], Double) -> Double, initParams: [Double], xValues: [Double], yValues: [Double]) -> (params: [Double], r2: Double, iterations: Int) {
    let maxNormG = 1.0e-12 // max error for infinite norm of G
    let maxNormH = 1.0e-17
    let tau = 1.0e-6
    let maxIterations = 10000
    
    
    var k = 0
    var v = 2.0
    
    let numberParams = initParams.count
    let numberPoints = xValues.count
    
    let params = Matrix(rows: numberParams, cols: 1)
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
    // end while
    
    print("Number of LM interations: \(k)")
    let yMatrix = Matrix(rows: numberPoints, cols: 1)
    yMatrix.array = yValues
    var r2Denominator = 0.0
    let yMean = yMatrix.meanValue
    for y in yValues {
        r2Denominator += (y - yMean) * (y - yMean)
    }
    
    let finalResiduals = getResiduals(fn: fn, params: params.array, xValues: xValues, yValues: yValues)
    var r2: Double
    if k < maxIterations {
        r2 = 1.0 - finalResiduals.dotProduct(finalResiduals) / r2Denominator
    } else {
        r2 = -1.0  // Neg r2 signifies soln did not converge
    }
    
    let _ = dialogOK("Warning", info: "Levenberg-Marquardt failed to converge!")
    
    // round significant digits for error
    for i in 0 ..< numberParams {
        params.array[i] = params.array[i].roundTo(digits: 9)
        
    }

    return (params: params.array, r2: r2, iterations: k)
    
}


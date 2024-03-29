//
//  LinearRegression.swift
//  Transform
//
//  Created by Rick Street on 7/8/19.
//  Copyright © 2019 Rick Street. All rights reserved.
//

import Foundation


/**
 leastSquaresFitForInd finds least square fit for ind matrix (1 or more columns) and dep Matrix (1 column)
 - Parameters:
 - ind: matrix of independent (x) values (one column for each coeficient to be determined)
 - dep: matrix of dependent (y) values (number of rows must match those in dep)
 - returns: Matrix determined coeficients for least square (first element is y intercept) along with r2 and r2SA (adjusted)
 */
public class LinearRegression {
    public var ind: Matrix
    public var dep: Matrix
    public var coefs = [Double]()
    public var slope = 0.0  // Slope
    public var intercept = 0.0  // Intercept
    public var rSquaredAdjusted = 0.0
    public var rSquared = 0.0
    public var variance = 0.0 // variance of redidules
    public var confidenceMultiplier = 1.96  // Standard Deviation multiplier for outlier calc (1.96 = 95% confidence)
    public var vifs = [Double]()  // Variance Inflation Factor for each ind
    public var corralationMatrix = Matrix(rows: 1, cols: 1)
    public var xMin = [Double]()
    public var xMax = [Double]()
    public var yMin = 0.0
    public var yMax = 0.0
    
    /*
     Conf   z
     90%    1.645
     95%    1.96
     99%    2.576
     */
    
    
    let smallNumber = 1e-10
    
    public var standardDeviation: Double {
        get {
            return sqrt(variance)
        }
    }
    
    public var outliers = [(x: Double, y: Double)]()
    public var outlierIndices = [Int]()
    public var residuals = [(x: Double, y: Double)]()
    public var predictions = [(x: Double, y: Double)]() // Ind0 vs depPredict
    public var xyPredictions = [(x: Double, y: Double)]() // Actual vs Predicted dep
    
    
    public var noCoef: Int {
        get {
            return ind.columnCount + 1
        }
    }
    
    public var nSamples: Int {
        get {
            return dep.rowCount
        }
    }
    
    
    func fit() {
        // print("fitting data...")
        residuals.removeAll()
        outliers.removeAll()
        outlierIndices.removeAll()
        predictions.removeAll()
        xyPredictions.removeAll()
        
        // get max and mins
        yMin = dep.minValue
        yMax = dep.maxValue
        for i in 0..<ind.columnCount {
            xMax.append(ind.maxValue(col: i))
            xMin.append(ind.minValue(col: i))
        }
        
        var b = Matrix(rows: noCoef, cols: 1) // Final coefs
        let x = Matrix(rows: noCoef, cols: noCoef) // X Matrix first column = 1.0
        let y = Matrix(rows: noCoef, cols: 1)  // Y Matrix
        var depMean = 0.0
        var sSE = 0.0   // Sum Square Errors
        var sSR = 0.0   // Sum Residules
        
        // get sample for x matrix for linear fit
        func sample(no: Int, coef: Int) -> Double {
            if coef < 0 {
                return 1.0
            } else {
                return ind[no, coef]
            }
        }
        
        // Buld x matrix with first column  = 1.0
        for i in 0 ..< noCoef {
            for j in 0 ..< noCoef {
                for s in 0 ..< nSamples {
                    x[i, j] += sample(no: s, coef: i - 1) * sample(no: s, coef: j - 1)
                }
            }
        }
        
        // Build y matrix
        for i in 0 ..< noCoef {
            var indSum = 0.0
            for s in 0 ..< nSamples {
                indSum += dep.array[s]
                y.array[i] += dep.array[s] * sample(no: s, coef: i - 1)
                // print("sample: \(sample(no: s, coef: i - 1)) dep: \(dep.array[s])  (\(y.array[i])")
            }
            depMean = indSum / Double(nSamples)
        }
        
        // Calc coeficients
        b = x.invert().multiplyMatrix(y)
        coefs = b.array
        
        intercept = coefs[0]
        slope = coefs[1]
        
        // Calc predicted Y first coef mult by 1 then the x values
        for s in 0 ..< nSamples {
            var yPredict = 0.0
            for c in -1 ..< noCoef - 1 {
                yPredict += b.array[c+1] * sample(no: s, coef: c)
            }
            sSE += (dep.array[s] - yPredict) * (dep.array[s] - yPredict)
            sSR += (depMean - yPredict) * (depMean - yPredict)
        }
        // print("SSE  \(sSE)")
        // print("SSR  \(sSR)")
        let sST = sSE + sSR // Total Sum Squares
        // print("SST  \(sST)")
        rSquared = sSR / sST
        rSquaredAdjusted = 1.0 - (1.0 - rSquared) * (Double(nSamples - 1) / Double(nSamples - noCoef - 1)) // R2 petalized for greater no coefs
        variance = sSE / (Double(nSamples) - Double(coefs.count))
        
        // build array of outliers and residuals
        for s in 0 ..< nSamples {
            var yPredict = 0.0
            for c in -1 ..< noCoef - 1 {
                // print("c \(c + 1)")
                yPredict += b.array[c+1] * sample(no: s, coef: c)
            }
            // print("\(s)  x \(ind[s, 0])  y \(dep.array[s])  yp \(yPredict)  r \(dep.array[s] - yPredict)")
            let residual = dep.array[s] - yPredict
            // residuals for first ind only
            residuals.append((x: ind[s, 0], residual))
            predictions.append((x: ind[s, 0], yPredict))
            xyPredictions.append((x: dep[s,0], yPredict))
            let absResidual = abs(residual)
            if !(absResidual < standardDeviation * confidenceMultiplier || absResidual < smallNumber)   {
                outliers.append((ind[s, 0], dep.array[s]))
                outlierIndices.append(s)
                // print("out row: \(s)")
            }
        }
        // print()
        // print("outliers")
        // print(outlierIndices)
        // print("fit complete")
        
        // Calc VIF (Variable Inflation Factor) for each ind
        let n = ind.columnCount
        vifs.removeAll()
        for i in 0..<n {
            if let array = ind.col(i) {
                let depInd = Matrix(rows: array.count, cols: 1)
                depInd.array = array
                let depInds = Matrix(rows: ind.rowCount, cols: ind.columnCount)
                depInds.array = ind.array
                depInds.removeCol(i)
                //print()
                //print("VIFs")
                //print("dep")
                //print(depInd.description)
                //print("inds")
                //print(depInds.description)
                let results = leastSquaresFit(ind: depInds, dep: depInd)
                //print("R2 X\(i): \(results.r2)")
                vifs.append(1.0 / (1.0 - results.r2))
            } // end if
            
        } // end for
        //print("vifs: \(vifs)")
        
        // Correlation Array
        correlationInds()
        

    }
    
    func correlationInds() {
        // print()
        // print("Correlation Array...")
        let noInds = ind.columnCount
        // print("no inds \(noInds)")
        corralationMatrix = Matrix(rows: noInds, cols: noInds)
        for i in 0..<noInds {
            for j in i..<noInds {
                if let depArray = ind.col(i), let indArray = ind.col(j) {
                    let depMatrix = Matrix(rows: indArray.count, cols: 1)
                    let indMatrix = Matrix(rows: indArray.count, cols: 1)
                    depMatrix.array = depArray
                    indMatrix.array = indArray
                    let results = leastSquaresFit(ind: indMatrix, dep: depMatrix)
                    corralationMatrix[i, j] = results.r2
                    //print()
                    //print("i /(i)  j /(j)  r2 \(results.r2)")
                    //print()
                }
            }
        }

    }
    
    
    
    /// Dependents Corrected for other independents
    /// - Parameter indIndex: independent index
    /// - Returns: dep corrected for other independents vs ind with index indIndexz
    public func correctedDeps(indIndex: Int) -> [(x: Double, y: Double)] {
        // print()
        // corIndIndex = index
        // print("ind index for corr \(index)")
        let yMinIndex = dep.indexOfMinValue
        // let yMin = dep.array[yMinIndex]
        // print("yMin \(yMinIndex)  \(yMin) \(dep.array[yMinIndex])")
        // print()
        // print("coefs")
        var correctedPlotData =  [(x: Double, y: Double)]()
        
        for i in 0..<dep.rowCount {
            var deltaY = 0.0
            for j in 0 ..< ind.columnCount {
                if j != indIndex {
                    deltaY += coefs[j + 1] * (ind[i, j] - ind[yMinIndex, j])
                }
            }
            correctedPlotData.append((ind[i, indIndex], dep[i, 0] - deltaY))
        }
        return correctedPlotData
    }
    
    
    public init(ind: Matrix, dep: Matrix) {
        self.ind = ind
        self.dep = dep
        fit()
    }
}

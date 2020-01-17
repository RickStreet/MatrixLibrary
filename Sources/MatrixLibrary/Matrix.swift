//
//  Matrix.swift
//  Transform
//
//  Created by Rick Street on 11/30/16.
//  Copyright © 2016 Rick Street. All rights reserved.
//

import Foundation
import Accelerate


/**
 Matix class is a two dimensional matrix addressable by indicies [i, j] that provides common matrix operations.  It uses the Accelerate library to do the operations.
 - Parameters:
 - rows: number of rows in matrix
 - cols: number of columns in matrix
 - array: Array of the elements as a single row (each row consecutively).
 - subscript: [i, j] index starts at 0
 - Note
            When the matrix is initiated, it fills the rows and columns with 0.0.  If you are appending values to array directly, make sure to remoffAll elelements.
 
 */
public class Matrix {
    /**
     Rows in matrix.
     */
    public var rows: Int
    
    /**
     Columns in matix.
     */
     public var cols: Int
    
    /**
     Array of elements as a single row (each row consecutively.
     */
    public var array: [Double]
    
    public init(rows:Int, cols:Int) {
        self.rows = rows
        self.cols = cols
        array = Array(repeating: 0.0, count: cols * rows)
    }
    
    
    public subscript(row:Int, col:Int) -> Double {
        get {
            return array[row * cols + col]
        }
        set {
            array[row * cols + col] = newValue
        }
    }
    
    
    /**
     addScalar adds a scalar to each element in a matrix
     - Parameters:
     - scalar: Scalar to add
     - returns: Matrix with Scalar added
     */
    public func add(scalar: Double) -> Matrix {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsaddD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultMatrix = Matrix(rows: rows, cols: cols)
        resultMatrix.array = vsresult
        return resultMatrix
    }
    
    /**
     add(matrix: Matrix) returns a matrix that is the result of matrix adding the matrix by the input matrix
     - Parameters:
     - matrix: the matrix to add
     - returns: matrix that is the result of adding matrix to self
     */
    public func add(matrix: Matrix) -> Matrix {
        var result = [Double](repeating: 0.0, count : array.count)
        vDSP_vaddD(self.array, 1, matrix.array, 1, &result, 1, vDSP_Length(self.array.count))
        let resultMatrix = Matrix(rows: self.rows, cols: self.cols)
        resultMatrix.array = result
        return resultMatrix
    }
    
    /**
     subtract(matrix: Matrix) returns a matrix that is the result of subtracting matrix fronm self
     - Parameters:
     - matrix: the matrix to subtract
     - returns: matrix that is the result of subtracting matrix fromn self
     */
    public func subtract(matrix: Matrix) -> Matrix {
        var result = [Double](repeating: 0.0, count : array.count)
        vDSP_vsubD(matrix.array, 1, self.array, 1, &result, 1, vDSP_Length(self.array.count))
        let resultMatrix = Matrix(rows: self.rows, cols: self.cols)
        resultMatrix.array = result
        return resultMatrix
    }
    
    
    /**
     divideByScalar divides each element in a matrix by a scalar
     - Parameters:
     - scalar: Scalar to divide by
     - returns: Matrix with elements divided by the scalar
     */
    public func divideBy(scalar: Double) -> Matrix {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsdivD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultMatrix = Matrix(rows: cols, cols: rows)
        resultMatrix.array = vsresult
        return resultMatrix
    }
    
    /**
     multiplyScalar multiplies each element in a matrix by a scalar
     - Parameters:
     - scalar: Scalar to multiply by
     - returns: Matrix with elements multiplied by the scalar
     */
    public func multiply(scalar: Double) -> Matrix {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsmulD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultMatrix = Matrix(rows: rows, cols: cols)
        resultMatrix.array = vsresult
        return resultMatrix
    }
    
    /**
     dotProduct calculates the dot product of a two matrixes
     - Parameters:
     - inMatrix: the matrix to dot multiply by
     - returns: Number that is the dot produce of the two matrixes
     
     */
    public func dotProduct(_ matrix: Matrix) -> Double {
        var dpresult = 0.0
        vDSP_dotprD(self.array, 1, matrix.array, 1, &dpresult, vDSP_Length(self.array.count))
        return dpresult
    }
    
    /**
     multiplyMatrix returns a matrix that is the result of matrix multipling the matrix by the input matrix
     - Parameters:
     - inMatrix: the matrix to multiply by
     - returns: matrix that is the result of matrix multiplication with tghe input matrix
     */
    public func multiplyMatrix(_ matrix: Matrix) -> Matrix {
        let mRows = UInt(self.rows)
        // let mInRows = UInt(inMatrix.rows)
        let mCols = UInt(self.cols)
        let mInCols = UInt(matrix.cols)
        var mresult = [Double](repeating: 0.0, count : self.rows * matrix.cols)
        vDSP_mmulD(self.array, 1, matrix.array, 1, &mresult, 1, mRows, mInCols, mCols)
        let resultMatrix = Matrix(rows: self.rows, cols: matrix.cols)
        resultMatrix.array = mresult
        return resultMatrix
    }
    
    /**
     transpose returns a matrix that is the transpose of the matrix
     - Parameters:
     - inMatrix: the matrix to dot multiply by
     - returns: Number that is the dot produce of the two matrixes
     
     */
    public func transpose() -> Matrix {
        var mtresult = [Double](repeating: 0.0, count : self.array.count)
        let tRows = UInt(self.cols)
        let tCols = UInt(self.rows)
        vDSP_mtransD(self.array, 1, &mtresult, 1, tRows, tCols)
        let resultMatrix = Matrix(rows: cols, cols: rows)
        resultMatrix.array = mtresult
        return resultMatrix
    }
    
    
    /**
     inverse returns a matrix that is the inverse of the matrix
     - Parameters:
     - inMatrix: the matrix to dot multiply by
     - returns: Number that is the dot produce of the two matrixes
     
     */
    public func invert() -> Matrix {
        var inMatrix = self.array
        var N1 = __CLPK_integer(sqrt(Double(self.array.count)))
        var N2 = N1
        var N3 = N1
        
        var pivots = [__CLPK_integer](repeating: 0, count: Int(N1))
        var workspace = [Double](repeating: 0.0, count: Int(N1))
        var error : __CLPK_integer = 0
        
        dgetrf_(&N1, &N2, &inMatrix, &N3, &pivots, &error)
        dgetri_(&N1, &inMatrix, &N2, &pivots, &workspace, &N3, &error)
        let resultMatrix = Matrix(rows: self.rows, cols: self.cols)
        resultMatrix.array = inMatrix
        return resultMatrix
    }
    

    public var diagonal: Matrix? {
        if self.rows == self.cols {
            // Square Matrix
            let result = Matrix(rows: self.cols, cols: self.rows)
            for i in 0 ..< self.rows {
                result[i, i] = self[i, i]
            }
            return result
        }
        return nil
    }

    /**
     meanValue returns maximum element value in matrix
     - returns: mean value of elementts
     */
    public var meanValue: Double {
        var result: Double = 0.0
        vDSP_meanvD(self.array, 1, &result, vDSP_Length(self.array.count))
        return result
    }

    /**
     maxValue returns maximum element value in matrix
     - returns: max value of elementts
     */
    public var maxValue: Double {
        var index: UInt = 0
        var result: Double = 0.0
        vDSP_maxviD(self.array, 1, &result, &index, vDSP_Length(self.array.count))
        return result
    }
    
    /**
     infinityNorm returns the Infinity Norm array (vector) i.e. The max absolute value
     - returns: Infinity Norm
     */
    public var infinityNorm: Double {
        var index: UInt = 0
        var result: Double = 0.0
        var absArray = [Double](repeating: 0.0, count : self.array.count)
        vDSP_vabsD(self.array, 1, &absArray, 1, vDSP_Length(self.array.count))
        vDSP_maxviD(absArray, 1, &result, &index, vDSP_Length(self.array.count))
        return result
    }
    
    
    /**
     l2Norm returns the L2 Norm (Eulcidian Length) of the array (vector)
     - returns: L2 Norm
     */
    public var l2Norm: Double {
        return cblas_dnrm2(Int32(self.rows * self.cols), self.array, 1)
    }
    
    public var description: String {
        get {
            var descr = ""
            for i in 0 ..< rows{
                descr += "["
                for j in 0 ..< cols {
                    if j > 0 {
                        descr += ", \(self[i, j])"
                    } else {
                        descr += "\(self[i, j])"
                    }
                    
                }
                descr += "]\n"
            }
            return descr
        }
    }
}

public class Vector {
    public var array = [Double]()
    public func mean() -> Double {
        var result = 0.0
        vDSP_meanvD(array, 1, &result, vDSP_Length(array.count))
        return result
    }
    
}


/**
 leastSquaresFitForInd finds least square fit for ind matrix (1 or more columns) and dep Matrix (1 column)
 - Parameters:
 - ind: matrix of independent (x) values (one column for each coeficient to be determined)
 - dep: matrix of dependent (y) values (number of rows must match those in dep)
 - returns: Matrix determined coeficients for least square (first element is y intercept) along with r2 and r2SA (adjusted)
 */
public func leastSquaresFit(ind: Matrix, dep: Matrix) -> (coefs: [Double], r2: Double, r2A: Double) {
    let noCoef = ind.cols + 1
    let nSamples = dep.rows
    var b = Matrix(rows: noCoef, cols: 1) // Final coefs
    var x = Matrix(rows: noCoef, cols: noCoef) // X Matrix first column = 1.0
    var y = Matrix(rows: noCoef, cols: 1)  // Y Matrix
    var depMean = 0.0
    var sSE = 0.0   // Sum Square Errors
    var sSR = 0.0   // Sum Residules
    var rSquared = 0.0
    var rSquaredAdjusted = 0.0
    
    
    // get sample
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
    let coefs = b.array
    
    // Calc R squared
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
    rSquaredAdjusted = 1.0 - (Double(nSamples - 1) / Double(nSamples - noCoef)) * (1.0 - rSquared)  // R2 petalized for greater no coefs
    
    
    return (coefs: coefs, r2: rSquared, r2A: rSquaredAdjusted)
}



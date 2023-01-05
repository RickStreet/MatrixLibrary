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
 - rows:    number of rows in matrix
 - cols:    number of columns in matrix
 - array:   Array of the elements as a single row (each row consecutively).
 - subscript:   [i, j] index starts at 0
 - Note
 When the matrix is initiated, it fills the rows and columns with 0.0.  If you are appending values to array directly, make sure to remoffAll elelements.
 
 */
public class Matrix {
    /**
     Rows in matrix.
     */
    public var rowsCount: Int
    
    /**
     Columns in matix.
     */
    public var columnsCount: Int
    
    /**
     Array of elements as a single row (each row consecutively.
     */
    public var array: [Double]
    
    public init(rows:Int, cols:Int) {
        self.rowsCount = rows
        self.columnsCount = cols
        array = Array(repeating: 0.0, count: cols * rows)
    }
    
    /// Sets dimension of Matrix.  Fills Matrix with zeros
    /// - Parameters:
    ///   - rows: total number of rows
    ///   - cols: total number of columns
    public func dimension(rows: Int, cols: Int) {
        self.rowsCount = rows
        self.columnsCount = cols
        array = Array(repeating: 0.0, count: cols * rows)
    }
    
    public subscript(row:Int, col:Int) -> Double {
        get {
            return array[row * columnsCount + col]
        }
        set {
            array[row * columnsCount + col] = newValue
        }
    }
    
    
    /// Returns row with index
    /// - Parameter row: row index for row to return
    /// - Returns: Row with index i
    public func row(_ row: Int) -> [Double]? {
        guard row >= 0 && row < rowsCount else {
            return nil
        }
        let range = (row * columnsCount)..<(row * columnsCount + columnsCount)
        return Array(array[range])
    }
    
    /// Returns column with index
    /// - Parameter col: column index for column to return.
    /// - Returns: Column with index i
    public func col(_ col: Int) -> [Double]? {
        guard col >= 0 || col < columnsCount else {
            return nil
        }
        var selectedCol = [Double]()
        for i in stride(from: col, through: array.count - (columnsCount - col), by: columnsCount) {
            // print("i \(i)")
            selectedCol.append(array[i])
        }
        return selectedCol
    }

    
    
    /// Remove row at row index
    /// - Parameter row: row to remove
    public func removeRow(_ row: Int) {
        print("Matrix: removing row \(row)")
        let range = (row * columnsCount)..<(row * columnsCount + columnsCount)
        print("Matrix: remove range \(range)")
        array.removeSubrange(range)
        rowsCount -= 1
    }
    
    /// Removes all rows for row indicies in supplied array
    /// - Parameter rows: array of rows to remove
    public func removeRows(_ rows: [Int]) {
        print("Matrix: removing row \(rows)")
        for i in rows.sorted(by: {$0 > $1}) {
            removeRow(i)
        }
    }
    
    /// Remove column at index
    /// - Parameter col: Column index
    public func removeCol(_ col: Int) {
        print("Matrix: removing col \(col)")
        guard col >= 0 || col < columnsCount else { // Start with largest row index
            return
        }
        print("cols \(columnsCount)")
        print("count - cols \(array.count - columnsCount)")
        for i in stride(from: (array.count - (columnsCount - col)), to: -1, by: -columnsCount) {
            
            // print("remove index \(i), \(array[i])")
            array.remove(at: i)
        }
        columnsCount -= 1
    }

    
    /**
     addScalar adds a scalar to each element in a matrix
     - Parameters:
     - scalar: Scalar to add
     - returns: fMatrix with Scalar added
     */
    public func add(scalar: Double) -> Matrix {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsaddD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultMatrix = Matrix(rows: rowsCount, cols: columnsCount)
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
        let resultMatrix = Matrix(rows: self.rowsCount, cols: self.columnsCount)
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
        let resultMatrix = Matrix(rows: self.rowsCount, cols: self.columnsCount)
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
        let resultMatrix = Matrix(rows: columnsCount, cols: rowsCount)
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
        let resultMatrix = Matrix(rows: rowsCount, cols: columnsCount)
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
        let mRows = UInt(self.rowsCount)
        // let mInRows = UInt(inMatrix.rows)
        let mCols = UInt(self.columnsCount)
        let mInCols = UInt(matrix.columnsCount)
        var mresult = [Double](repeating: 0.0, count : self.rowsCount * matrix.columnsCount)
        vDSP_mmulD(self.array, 1, matrix.array, 1, &mresult, 1, mRows, mInCols, mCols)
        let resultMatrix = Matrix(rows: self.rowsCount, cols: matrix.columnsCount)
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
        let tRows = UInt(self.columnsCount)
        let tCols = UInt(self.rowsCount)
        vDSP_mtransD(self.array, 1, &mtresult, 1, tRows, tCols)
        let resultMatrix = Matrix(rows: columnsCount, cols: rowsCount)
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
        let resultMatrix = Matrix(rows: self.rowsCount, cols: self.columnsCount)
        resultMatrix.array = inMatrix
        return resultMatrix
    }
    
    
    public var diagonal: Matrix? {
        if self.rowsCount == self.columnsCount {
            // Square Matrix
            let result = Matrix(rows: self.columnsCount, cols: self.rowsCount)
            for i in 0 ..< self.rowsCount {
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
     minValue returns minimum element value in matrix
     - returns: min value of elementts
     */
    public var minValue: Double {
        var index: UInt = 0
        var result: Double = 0.0
        vDSP_minviD(self.array, 1, &result, &index, vDSP_Length(self.array.count))
        return result
    }
    
    public func minValue(col: Int) -> Double {
        var min = self[0, col]
        for i in  1 ..< self.rowsCount {
            if self[i, col] < min {
                min = self[i, col]
            }
        }
        return min
    }
    
    public func maxValue(col: Int) -> Double {
        var max = self[0, col]
        for i in  1 ..< self.rowsCount {
            if self[i, col] > max {
                max = self[i, col]
            }
        }
        return max
    }
    
    public func averageValue(col: Int) -> Double {
        var total = 0.0
        for i in 0 ..< rowsCount {
            total += self[i, col]
        }
        return total / Double(rowsCount)
    }
    
    /**
     minValue returns minimum element index in matrix
     - returns: min value index 
     */
    public var indexOfMinValue: Int {
        var minValue = array[0]
        var minIndex = 0
        for (i, value) in array.enumerated() {
            if value < minValue {
                minValue = value
                minIndex = i
            }
        }
        return minIndex
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
        return cblas_dnrm2(Int32(self.rowsCount * self.columnsCount), self.array, 1)
    }
    
    public var description: String {
        get {
            var descr = ""
            for i in 0 ..< rowsCount{
                descr += "["
                for j in 0 ..< columnsCount {
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



/**
 leastSquaresFitForInd finds least square fit for ind matrix (1 or more columns) and dep Matrix (1 column)
 - Parameters:
 - ind: matrix of independent (x) values (one column for each coeficient to be determined)
 - dep: matrix of dependent (y) values (number of rows must match those in dep)
 - returns: Matrix determined coeficients for least square (first element is y intercept) along with r2 and r2SA (adjusted)
 */
public func leastSquaresFit(ind: Matrix, dep: Matrix) -> (coefs: [Double], r2: Double, r2A: Double) {
    let noCoef = ind.columnsCount + 1
    let nSamples = dep.rowsCount
    var b = Matrix(rows: noCoef, cols: 1) // Final coefs
    let x = Matrix(rows: noCoef, cols: noCoef) // X Matrix first column = 1.0
    let y = Matrix(rows: noCoef, cols: 1)  // Y Matrix
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



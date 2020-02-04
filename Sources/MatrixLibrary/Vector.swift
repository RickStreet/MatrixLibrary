//
//  File.swift
//  
//
//  Created by Rick Street on 2/3/20.
//

import Foundation
import Accelerate

public class Vector {
    public var array = [Double]()
    
    /**
     mean returns the mean value for the  array (vector)
     - returns: mean (average)
     */
    public func mean() -> Double {
        var result = 0.0
        vDSP_meanvD(array, 1, &result, vDSP_Length(array.count))
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
        return cblas_dnrm2(Int32(self.array.count), self.array, 1)
    }

    /**
     addScalar adds a scalar to each element in a vector
     - Parameters:
     - scalar: Scalar to add
     - returns: Vector with Scalar added
     */
    public func add(scalar: Double) -> Vector {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsaddD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultVector = Vector(array.count)
        resultVector.array = vsresult
        return resultVector
    }

    /**
     add(vector: Vector) returns a vector that is the result of vector adding the vector by the input vector
     - Parameters:
     - vector: the vector to add
     - returns: vector that is the result of adding vector to self
     */
    public func add(vector: Vector) -> Vector {
        var result = [Double](repeating: 0.0, count : array.count)
        vDSP_vaddD(self.array, 1, vector.array, 1, &result, 1, vDSP_Length(self.array.count))
        let resultVector = Vector(array.count)
        resultVector.array = result
        return resultVector
    }
    
    /**
     subtract(vector: Vector) returns a vector that is the result of subtracting vector fronm self
     - Parameters:
     - matrix: the vector to subtract
     - returns: Vector that is the result of subtracting vector fromn self
     */
    public func subtract(vector: Vector) -> Vector {
        var result = [Double](repeating: 0.0, count : array.count)
        vDSP_vsubD(vector.array, 1, self.array, 1, &result, 1, vDSP_Length(self.array.count))
        let resultVector = Vector(array.count)
        resultVector.array = result
        return resultVector
    }
    
    /**
     divideBy(scalar) divides each element in a vector by a scalar
     - Parameters:
     - scalar: Scalar to divide by
     - returns: Vector with elements divided by the scalar
     */
    public func divideBy(scalar: Double) -> Vector {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsdivD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultVector = Vector(self.array.count)
        resultVector.array = vsresult
        return resultVector
    }
    
    /**
     multiplyScalar multiplies each element in a vector by a scalar
     - Parameters:
     - scalar: Scalar to multiply by
     - returns: Vector with elements multiplied by the scalar
     */
    public func multiply(scalar: Double) -> Vector {
        var inScalar = scalar
        var vsresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vsmulD(array, 1, &inScalar, &vsresult, 1, vDSP_Length(array.count))
        let resultVector = Vector(self.array.count)
        resultVector.array = vsresult
        return resultVector
    }

    /**
     dotProduct calculates the dot product of a two vectors
     - Parameters:
     - inVector: the matrix to dot multiply by
     - returns: Number that is the dot produce of the two vectors
     */
    public func dotProduct(_ vector: Vector) -> Double {
        var dpresult = 0.0
        vDSP_dotprD(self.array, 1, vector.array, 1, &dpresult, vDSP_Length(self.array.count))
        return dpresult
    }
    
    /**
     multiplyVector returns a vector that is the result of vector multipling the vector by the input vector
     - Parameters:
     - vector: the vector to multiply by
     - returns: vector that is the result of vector (x) multiplication with tgh input vector
     */
    public func multiplyVector(_ vector: Vector) -> Vector {
        var mresult = [Double](repeating: 0.0, count : array.count)
        vDSP_vmulD(self.array, 1, vector.array, 1, &mresult, 1, vDSP_Length(self.array.count))
        let resultVector = Vector(array.count)
        resultVector.array = mresult
        return resultVector
    }
    
    /**
     maxValue returns maximum element value in the vector
     - returns: max value of elementts
     */
    public var maxValue: Double {
        var index: UInt = 0
        var result: Double = 0.0
        vDSP_maxviD(self.array, 1, &result, &index, vDSP_Length(self.array.count))
        return result
    }
    
    /**
     minValue returns minimum element value in the vector
     - returns: min value of elementts
     */
    public var minValue: Double {
        var index: UInt = 0
        var result: Double = 0.0
        vDSP_minviD(self.array, 1, &result, &index, vDSP_Length(self.array.count))
        return result
    }

    public var description: String {
        get {
            var descr = "["
            for i in 0 ..< self.array.count - 1 {
                descr += "\(array[i]), "
            }
            descr += "\(array.last ?? 0.0)] "
            return descr
        }
    }
    
    public init(_ array: [Double]) {
        self.array = array
    }

    public init(_ numberElements: Int) {
        array = Array(repeating: 0.0, count: numberElements)
    }
    
}

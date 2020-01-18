//
//  File.swift
//  
//
//  Created by Rick Street on 1/17/20.
//

import Foundation

extension Double {
    // Rounds the double to 'places' significant digits
    func roundTo(digits:Int) -> Double {
        guard self != 0.0 else {
            return 0
        }
        let divisor = pow(10.0, Double(places) - ceil(log10(fabs(self))))
        return (self * divisor).rounded() / divisor
    }
}

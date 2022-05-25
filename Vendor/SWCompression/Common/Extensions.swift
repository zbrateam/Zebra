// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

extension UInt8 {

    func toInt() -> Int {
        return Int(bitPattern: UInt(self))
    }

}

extension Int {

    func toUInt8() -> UInt8 {
        return UInt8(truncatingIfNeeded: UInt(self))
    }

}

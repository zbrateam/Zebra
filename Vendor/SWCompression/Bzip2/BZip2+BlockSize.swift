// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

public extension BZip2 {

    /**
     Represents size of blocks in which data is split during BZip2 compression.
     */
    enum BlockSize: Int {
        /// 100 KB.
        case one = 1
        /// 200 KB.
        case two = 2
        /// 300 KB.
        case three = 3
        /// 400 KB.
        case four = 4
        /// 500 KB.
        case five = 5
        /// 600 KB.
        case six = 6
        /// 700 KB.
        case seven = 7
        /// 800 KB.
        case eight = 8
        /// 900 KB.
        case nine = 9

        func headerByte() -> Int {
            switch self {
            case .one:
                return 0x31
            case .two:
                return 0x32
            case .three:
                return 0x33
            case .four:
                return 0x34
            case .five:
                return 0x35
            case .six:
                return 0x36
            case .seven:
                return 0x37
            case .eight:
                return 0x38
            case .nine:
                return 0x39
            }
        }

    }
}

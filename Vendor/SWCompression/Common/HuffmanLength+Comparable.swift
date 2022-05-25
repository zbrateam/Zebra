// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

extension HuffmanLength: Comparable {

    static func < (left: HuffmanLength, right: HuffmanLength) -> Bool {
        if left.codeLength == right.codeLength {
            return left.symbol < right.symbol
        } else {
            return left.codeLength < right.codeLength
        }
    }

    static func == (left: HuffmanLength, right: HuffmanLength) -> Bool {
        return left.codeLength == right.codeLength && left.symbol == right.symbol
    }

}

// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

class BurrowsWheeler {

    static func transform(bytes: [Int]) -> ([Int], Int) {
        let doubleBytes = bytes + bytes
        let suffixArray = SuffixArray.make(from: doubleBytes, with: 256)
        var bwt = [Int]()
        var pointer = 0
        for i in 1..<suffixArray.count {
            if suffixArray[i] < bytes.count {
                if suffixArray[i] > 0 {
                    bwt.append(bytes[suffixArray[i] - 1])
                } else {
                    bwt.append(bytes.last!)
                }
            } else if suffixArray[i] == bytes.count {
                pointer = (i - 1) / 2
            }
        }
        return (bwt, pointer)
    }

    static func reverse(bytes: [UInt8], _ pointer: Int) -> [UInt8] {
        var resultBytes: [UInt8] = []
        var end = pointer
        if bytes.count > 0 {
            let T = bwt(transform: bytes)
            for _ in 0..<bytes.count {
                end = T[end]
                resultBytes.append(bytes[end])
            }
        }
        return resultBytes
    }

    private static func bwt(transform bytes: [UInt8]) -> [Int] {
        let sortedBytes = bytes.sorted()
        var base: [Int] = Array(repeating: -1, count: 256)

        var byteType = -1
        for i in 0..<sortedBytes.count {
            if byteType < sortedBytes[i].toInt() {
                byteType = sortedBytes[i].toInt()
                base[byteType] = i
            }
        }

        var pointers: [Int] = Array(repeating: -1, count: bytes.count)
        for (i, char) in bytes.enumerated() {
            pointers[base[char.toInt()]] = i
            base[char.toInt()] += 1
        }

        return pointers
    }

}

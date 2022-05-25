// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

class DataWithPointer {

    let size: Int
    let data: Data
    var index: Int

    var isAtTheEnd: Bool {
        return self.data.endIndex == self.index
    }

    var previousByte: UInt8 {
        return self.data[self.index - 1]
    }

    convenience init(array: inout [UInt8]) {
        self.init(data: Data(array))
    }

    init(data: Data) {
        self.size = data.count
        self.data = data
        self.index = data.startIndex
    }

    func byte() -> UInt8 {
        self.index += 1
        return self.data[self.index - 1]
    }

    func bytes(count: Int) -> [UInt8] {
        var result: [UInt8] = Array(repeating: 0, count: count)
        for i in 0..<count {
            result[i] = self.data[self.index]
            self.index += 1
        }
        return result
    }

    func uint64(count: UInt64 = 8) -> UInt64 {
        precondition(count <= 8, "UInt64 cannot store more than 8 bytes of data!")
        var result: UInt64 = 0
        for i: UInt64 in 0..<count {
            result |= UInt64(self.data[self.index]) << (8 * i)
            self.index += 1
        }
        return result
    }

    func uint32(count: UInt32 = 4) -> UInt32 {
        precondition(count <= 4, "UInt32 cannot store more than 4 bytes of data!")
        var result: UInt32 = 0
        for i: UInt32 in 0..<count {
            result |= UInt32(self.data[self.index]) << (8 * i)
            self.index += 1
        }
        return result
    }

    func uint16(count: UInt16 = 2) -> UInt16 {
        precondition(count <= 2, "UInt16 cannot store more than 2 bytes of data!")
        var result: UInt16 = 0
        for i: UInt16 in 0..<count {
            result |= UInt16(self.data[self.index]) << (8 * i)
            self.index += 1
        }
        return result
    }

}

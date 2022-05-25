// Copyright (c) 2017 Timofey Solomko
// Licensed under MIT License
//
// See LICENSE for license information

import Foundation

class BitReader: DataWithPointer {

    enum BitOrder {
        case straight
        case reversed
    }

    let bitOrder: BitOrder
    private(set) var bitMask: UInt8

    var isAligned: Bool {
        switch self.bitOrder {
        case .reversed:
            return self.bitMask == 1
        case .straight:
            return self.bitMask == 128
        }
    }

    convenience init(array: inout [UInt8], bitOrder: BitOrder) {
        self.init(data: Data(array), bitOrder: bitOrder)
    }

    init(data: Data, bitOrder: BitOrder) {
        self.bitOrder = bitOrder
        switch self.bitOrder {
        case .reversed:
            self.bitMask = 1
        case .straight:
            self.bitMask = 128
        }
        super.init(data: data)
    }

    func bits(count: Int) -> [UInt8] {
        guard count > 0 else {
            return []
        }

        var array: [UInt8] = Array(repeating: 0, count: count)
        for i in 0..<count {
            array[i] = self.data[self.index] & self.bitMask > 0 ? 1 : 0

            switch self.bitOrder {
            case .reversed:
                if self.bitMask == 128 {
                    self.index += 1
                    self.bitMask = 1
                } else {
                    self.bitMask <<= 1
                }
            case .straight:
                if self.bitMask == 1 {
                    self.index += 1
                    self.bitMask = 128
                } else {
                    self.bitMask >>= 1
                }
            }
        }

        return array
    }

    func intFromBits(count: Int) -> Int {
        guard count > 0 else {
            return 0
        }

        var result = 0
        for i in 0..<count {
            let power: Int
            switch self.bitOrder {
            case .straight:
                power = count - i - 1
            case .reversed:
                power = i
            }

            let bit = self.data[self.index] & self.bitMask > 0 ? 1 : 0
            result += (1 << power) * bit

            switch self.bitOrder {
            case .reversed:
                if self.bitMask == 128 {
                    self.index += 1
                    self.bitMask = 1
                } else {
                    self.bitMask <<= 1
                }
            case .straight:
                if self.bitMask == 1 {
                    self.index += 1
                    self.bitMask = 128
                } else {
                    self.bitMask >>= 1
                }
            }
        }

        return result
    }

    func bit() -> Int {
        let bit = self.data[self.index] & self.bitMask > 0 ? 1 : 0

        switch self.bitOrder {
        case .reversed:
            if self.bitMask == 128 {
                self.index += 1
                self.bitMask = 1
            } else {
                self.bitMask <<= 1
            }
        case .straight:
            if self.bitMask == 1 {
                self.index += 1
                self.bitMask = 128
            } else {
                self.bitMask >>= 1
            }
        }

        return bit
    }

    func align() {
        switch self.bitOrder {
        case .reversed:
            guard self.bitMask != 1 else {
                return
            }
            self.bitMask = 1
        case .straight:
            guard self.bitMask != 128 else {
                return
            }
            self.bitMask = 128
        }
        self.index += 1
    }

    override func byte() -> UInt8 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.byte()
    }

    override func bytes(count: Int) -> [UInt8] {
        precondition(isAligned, "BitReader is not aligned.")
        return super.bytes(count: count)
    }

    override func uint64(count: UInt64 = 8) -> UInt64 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint64(count: count)
    }

    override func uint32(count: UInt32 = 4) -> UInt32 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint32(count: count)
    }

    override func uint16(count: UInt16 = 2) -> UInt16 {
        precondition(isAligned, "BitReader is not aligned.")
        return super.uint16(count: count)
    }

}

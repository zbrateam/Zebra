//
//  Dictionary+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 14/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension Dictionary {
	static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
		lhs.merging(rhs, uniquingKeysWith: { $1 })
	}

	static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
		lhs.merge(rhs, uniquingKeysWith: { $1 })
	}
}

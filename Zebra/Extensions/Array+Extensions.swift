//
//  Array+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

extension Array {
	func compact<ElementOfResult>() -> [ElementOfResult] where Element == ElementOfResult? {
		compactMap { $0 }
	}
}

extension Array where Element == String {
	var cStringArray: [UnsafeMutablePointer<CChar>?] {
		map { item in item.cString }
	}
}

extension Array where Element == Optional<UnsafeMutablePointer<CChar>> {
	func deallocate() {
		for item in self {
			item?.deallocate()
		}
	}
}

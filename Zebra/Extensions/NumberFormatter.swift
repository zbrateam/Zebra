//
//  NumberFormatter.swift
//  Zebra
//
//  Created by Adam Demasi on 6/7/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension NumberFormatter {
	static let count: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.locale = .autoupdatingCurrent
		formatter.numberStyle = .decimal
		formatter.usesGroupingSeparator = true
		return formatter
	}()
}

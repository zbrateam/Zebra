//
//  URL+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 3/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension URL {
	static func / (lhs: URL, rhs: String) -> URL {
		lhs.appendingPathComponent(rhs)
	}
}

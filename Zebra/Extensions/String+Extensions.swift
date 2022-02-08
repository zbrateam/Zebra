//
//  String+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

extension String {
	var cString: UnsafeMutablePointer<CChar>? {
		withCString(strdup)
	}
}

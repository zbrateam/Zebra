//
//  HTTPTypes.swift
//  Zebra
//
//  Created by Adam Demasi on 11/7/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

import HTTPTypes
import HTTPTypesFoundation

extension HTTPFields {
	var dictionary: [String: String] { Dictionary(map { ($0.name.rawName, $0.value) },
																								uniquingKeysWith: { $1 }) }

	static func + (lhs: HTTPFields, rhs: HTTPFields) -> HTTPFields {
		var result = lhs
		result.append(contentsOf: rhs)
		return result
	}
}

extension HTTPField.Name {

	// Client Hints
	static let chUserAgent       = Self("Sec-CH-UA")!
	static let chPlatform        = Self("Sec-CH-UA-Platform")!
	static let chPlatformVersion = Self("Sec-CH-UA-Platform-Version")!
	static let chFullVersion     = Self("Sec-CH-UA-Full-Version")!
	static let chFullVersionList = Self("Sec-CH-UA-Full-Version-List")!
	static let chArch            = Self("Sec-CH-UA-Arch")!
	static let chBitness         = Self("Sec-CH-UA-Bitness")!
	static let chModel           = Self("Sec-CH-UA-Model")!
	static let chIsMobile        = Self("Sec-CH-UA-Mobile")!
	static let chDPR             = Self("Sec-CH-DPR")!
	static let dpr               = Self("DPR")!

	// Zebra headers
	static let paymentProvider   = Self("Payment-Provider")!
	static let tintColor         = Self("Tint-Color")!

	// Legacy Cydia headers
	static let xFirmware         = Self("X-Firmware")!
	static let xMachine          = Self("X-Machine")!
	static let xUniqueID         = Self("X-Unique-Id")!
	static let xCydiaID          = Self("X-Cydia-Id")!

}

extension HTTPResponse.Status {

	/// 0 Invalid
	public static var invalid: Self { .init(code: 0, reasonPhrase: "Invalid") }

	/// 402 Payment Required
	public static var paymentRequired: Self { .init(code: 402, reasonPhrase: "Payment Required") }

}

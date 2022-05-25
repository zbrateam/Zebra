//
//  RFC822DateFormatter.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class RFC822DateFormatter: DateFormatter {

	override init() {
		super.init()
		timeZone = TimeZone(secondsFromGMT: 0)
		dateFormat = "E, d MMM yyyy HH:mm:ss 'GMT'"
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension DateFormatter {
	static let rfc822 = RFC822DateFormatter()
}

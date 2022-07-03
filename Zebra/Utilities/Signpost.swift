//
//  Signpost.swift
//  Zebra
//
//  Created by Adam Demasi on 4/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log

struct Signpost {

	let log: OSLog
	let subsystem: String
	let signpostID: OSSignpostID
	let name: StaticString
	let format: StaticString
	let arguments: [CVarArg]

	init(subsystem: String, signpostID: OSSignpostID? = nil, name: StaticString, format: StaticString, _ arguments: CVarArg...) {
		self.subsystem = subsystem
		self.log = OSLog(subsystem: subsystem, category: .pointsOfInterest)
		self.signpostID = signpostID ?? OSSignpostID(log: log)
		self.name = name
		self.format = format
		self.arguments = arguments
	}

	func begin(dso: UnsafeRawPointer = #dsohandle) {
		os_signpost(.begin, dso: dso, log: log, name: name, signpostID: signpostID, format, arguments)
	}

	func end(dso: UnsafeRawPointer = #dsohandle) {
		os_signpost(.end, dso: dso, log: log, name: name, signpostID: signpostID, format, arguments)
	}

	func event(dso: UnsafeRawPointer = #dsohandle, format: StaticString, _ arguments: CVarArg...) {
		os_signpost(.event, dso: dso, log: log, name: name, signpostID: signpostID, format, arguments)
	}

}

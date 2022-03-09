//
//  SourceHTTPClient.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

@objc class SourceHTTPClient: NSObject {

	private struct Job {
		let sourceURL: URL
		let destinationURL: URL
		let sourceUUID: String
	}

	static let shared = SourceHTTPClient()

	private let queue = DispatchQueue(label: "xyz.willy.Zebra.source-http-client-queue", qos: .utility)
	private var jobQueues = [DispatchQueue]()

	private var pendingJobs = [Job]()

	override private init() {
		super.init()
	}

	func process() {
		queue.async {
			while !self.pendingJobs.isEmpty {
				let job = self.pendingJobs.removeLast()
				print("XXX job: \(job)")
			}
			print("XXX queue empty")
		}
	}

}

extension SourceHTTPClient: PLDownloadDelegate {

	func addDownloadURL(_ downloadURL: URL, withDestinationURL destinationURL: URL, forSourceUUID sourceUUID: String) {
		queue.async {
			self.pendingJobs.append(Job(sourceURL: downloadURL,
																	destinationURL: destinationURL,
																	sourceUUID: sourceUUID))
			if self.pendingJobs.count == 1 {
				self.process()
			}
		}
	}

}

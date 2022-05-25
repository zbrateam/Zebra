//
//  SourceHTTPClient.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

//@objc class SourceHTTPClient: NSObject {
//
//	static let shared = SourceHTTPClient()
//
//	private let queue = DispatchQueue(label: "xyz.willy.Zebra.source-http-client-queue", qos: .utility)
//	private var jobQueues = [DispatchQueue]()
//
//	private var pendingJobs = [Job]()
//
//	override private init() {
//		super.init()
//	}
//
//	func process() {
//		queue.async {
//			while !self.pendingJobs.isEmpty {
//				let job = self.pendingJobs.removeLast()
//				print("XXX job: \(job)")
//			}
//			print("XXX queue empty")
//		}
//	}
//
//}

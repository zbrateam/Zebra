//
//  JobQueue.swift
//  Zebra
//
//  Created by Adam Demasi on 19/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class JobQueue<Job: Hashable> {

	typealias QueueProcessor = (Job) -> Void

	let queue: DispatchQueue
	let taskLimit: Int
	let queueProcessor: QueueProcessor

	private(set) var pendingJobs = [Job]()
	private(set) var runningJobs = [Job]()

	init(queue: DispatchQueue, taskLimit: Int, queueProcessor: @escaping QueueProcessor) {
		self.queue = queue
		self.taskLimit = taskLimit
		self.queueProcessor = queueProcessor
	}

	private func tick() {
		queue.async {
			if !self.pendingJobs.isEmpty && self.runningJobs.count < self.taskLimit {
				let job = self.pendingJobs.removeFirst()
				self.runningJobs.append(job)
				self.queueProcessor(job)
				self.tick()
			}
		}
	}

	func enqueue(job: Job) {
		pendingJobs.append(job)
		tick()
	}

	func complete(job: Job) {
		if let index = runningJobs.firstIndex(of: job) {
			runningJobs.remove(at: index)
		}
		tick()
	}

}

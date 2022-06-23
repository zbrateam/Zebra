//
//  SourceRefreshController+BackgroundRefresh.swift
//  Zebra
//
//  Created by Adam Demasi on 6/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import BackgroundTasks
import os.log

extension SourceRefreshController {

	private static let refreshTaskIdentifier = "com.getzbra.zebra.source-refresh-task"

	// Background refresh every 6 hours or so
	private static let refreshTaskInterval: TimeInterval = 6 * 60 * 60

	internal func registerBackgroundTask() {
		BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskIdentifier, using: nil) { task in
			// This block is called when the background task has fired.
			task.expirationHandler = {
				if self.isRefreshing {
					self.progress.cancel()
				}
			}
			self.backgroundTask = task

			self.refresh(priority: .background)
		}
	}

	internal func scheduleNextRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
		request.earliestBeginDate = Date(timeIntervalSinceNow: Self.refreshTaskInterval)

		do {
			let scheduler = BGTaskScheduler.shared
			scheduler.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
			try scheduler.submit(request)
		} catch {
			logger.warning("Source refresh task registration failed: \(String(describing: error))")
		}
	}

	internal func completeBackgroundRefresh() {
		// If we were launched from a background task, we need to tell the OS we’ve finished.
		backgroundTask?.setTaskCompleted(success: true)
		backgroundTask = nil
	}

}

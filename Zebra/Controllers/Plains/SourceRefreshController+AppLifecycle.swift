//
//  SourceRefreshController+AppLifecycle.swift
//  Zebra
//
//  Created by Adam Demasi on 10/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

extension SourceRefreshController {

	private static let backgroundContinuationTaskIdentifier = "com.getzbra.zebra.source-refresh-continuation-task"
	private static let appActivationSourceRefreshInterval: TimeInterval = 15 * 60

	internal func registerNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
	}

	// MARK: - Notifications

	@objc private func appDidBecomeActive() {
		// If the app was in the background for a while, the data is likely to be outdated. Kick off
		// another refresh now if it’s been long enough.
		if Preferences.refreshSourcesAutomatically && Preferences.lastSourceUpdate.distance(to: Date()) > Self.appActivationSourceRefreshInterval {
			refresh()
		}
	}

	@objc private func appWillResignActive() {
		// Tell the OS we want to keep going in the background.
		UIApplication.shared.beginBackgroundTask(withName: Self.backgroundContinuationTaskIdentifier) {
			// Timer expired, cancel now.
			if self.isRefreshing {
				self.progress.cancel()
			}
		}
	}

}

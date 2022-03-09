//
//  SourceRefreshController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

enum SourceRefreshState {
	case idle
	case loading(progress: Double)
	case failed(errors: [String])
}

class SourceRefreshController {

	static let automaticSourceRefreshInterval: TimeInterval = 5 * 60

	static let shared = SourceRefreshController()

	private(set) var states = [String: SourceRefreshState]()

	private let queue = DispatchQueue(label: "xyz.willy.Zebra.source-refresh-queue", qos: .utility)

	private init() {
		NotificationCenter.default.addObserver(self, selector: #selector(sourcesListDidUpdate), name: PLSourceManager.sourceListDidUpdateNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sourcesListDidBeginUpdating), name: PLSourceManager.sourceListDidBeginUpdatingNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sourceDidBeginUpdating), name: PLSourceManager.sourceDidBeginUpdatingNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sourceDidFinishUpdating), name: PLSourceManager.sourceDidFinishUpdatingNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sourceDidFailUpdating), name: PLSourceManager.sourceDidFailUpdatingNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sourceDidFinishRefreshing), name: PLSourceManager.sourceDidFinishRefreshingNotification, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

		PLSourceManager.shared.downloadDelegate = SourceHTTPClient.shared
	}

	func refresh(isUserRequested: Bool = true) {
		queue.async {
			if !isUserRequested && ZBSettings.lastSourceUpdate().distance(to: Date()) < Self.automaticSourceRefreshInterval {
				// Don’t refresh, we already refreshed very recently.
				return
			}
			PLSourceManager.shared.refreshSources()
			ZBSettings.updateLastSourceUpdate()
		}
	}

	// MARK: - Refresh state handling

	@objc private func sourcesListDidUpdate(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) \(PLConfig.shared.errorMessages)")
		PLConfig.shared.clearErrors()
	}

	@objc private func sourcesListDidBeginUpdating(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) [\(PLConfig.shared.errorMessages)]")
		PLConfig.shared.clearErrors()
	}

	@objc private func sourceDidBeginUpdating(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) [\(PLConfig.shared.errorMessages)]")
		PLConfig.shared.clearErrors()
	}

	@objc private func sourceDidFinishUpdating(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) [\(PLConfig.shared.errorMessages)]")
		PLConfig.shared.clearErrors()
	}

	@objc private func sourceDidFailUpdating(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) [\(PLConfig.shared.errorMessages)]")
		PLConfig.shared.clearErrors()
	}

	@objc private func sourceDidFinishRefreshing(_ notification: Notification) {
		print("XXX \(notification.name) \(String(describing: notification.object)) \(notification.userInfo ?? [:]) [\(PLConfig.shared.errorMessages)]")
		PLConfig.shared.clearErrors()
	}

	// MARK: - App lifecycle

	@objc private func appDidBecomeActive() {
		// If the app was in the background for a while, the data is likely to be outdated. Kick off
		// another refresh now.
		refresh(isUserRequested: false)
		print("XXX app became active")
	}

	@objc private func appWillResignActive() {
		// TODO: Cancel any active refresh, although maybe we can continue in the background for a bit?
		print("XXX app resigned active")
	}

}

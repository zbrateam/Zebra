//
//  WakeLock.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

struct WakeLock {

	private(set) static var currentLocks = Set<String>()
	private static var lockLock = os_unfair_lock()

	private static var isIdleTimerDisabled: Bool {
		get { UIApplication.shared.isIdleTimerDisabled }
		set {
			if Thread.isMainThread {
				UIApplication.shared.isIdleTimerDisabled = newValue
			} else {
				DispatchQueue.main.sync {
					UIApplication.shared.isIdleTimerDisabled = newValue
				}
			}
		}
	}

	let label: String

	func lock() {
		os_unfair_lock_lock(&Self.lockLock)
		Self.currentLocks.insert(label)
		Self.isIdleTimerDisabled = true
		os_unfair_lock_unlock(&Self.lockLock)
	}

	func unlock() {
		os_unfair_lock_lock(&Self.lockLock)
		Self.currentLocks.remove(label)
		if Self.currentLocks.isEmpty {
			Self.isIdleTimerDisabled = false
		}
		os_unfair_lock_unlock(&Self.lockLock)
	}

}

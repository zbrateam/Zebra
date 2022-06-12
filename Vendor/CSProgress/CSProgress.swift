//
//  CSProgress.swift
//
//  Created by Charles Srstka on 1/10/16.
//  Copyright © 2016-2020 Charles Srstka. All rights reserved.
//

import Foundation

// 'final' is apparently needed to conform to _ObjectiveCBridgeable. It also results in better performance.
public final class CSProgress: CustomDebugStringConvertible {
	// We allow increments as an atomic operation, for better performance.
	private enum UnitCountChangeType {
		case set(UnitCount)
		case increment(UnitCount)
	}

	// By default, we'll update 100 times over the course of our progress. This should provide a decent user experience without compromising too much on performance.
	public static let defaultGranularity: Double = 0.01

	// Declare our own unit count type instead of hard-coding it to Int64, for future flexibility.
	public typealias UnitCount = Int64

	// Notification types. These will all be executed on the progress's queue.

	/// This closure will be executed if the progress is cancelled.
	public typealias CancellationNotification = () -> ()

	/// This closure will be executed whenever the change in fractionCompleted exceeds the granularity.
	public typealias FractionCompletedNotification = (_ completedUnitCount: UnitCount, _ totalUnitCount: UnitCount, _ fractionCompleted: Double) -> ()

	/// This closure will be executed when the progress's description is changed.
	public typealias DescriptionNotification = (_ localizedDescription: String, _ localizedAdditionalDescription: String) -> ()

	/// Convenience struct for passing a CSProgress to a child function explicitly, encapsulating the parent progress and its pending unit count.
	/// Create one of these by calling .pass() on the parent progress.
	public struct ParentReference {
		public let progress: CSProgress
		public let pendingUnitCount: UnitCount

		public init<Count: BinaryInteger>(progress: CSProgress, pendingUnitCount: Count) {
			self.progress = progress
			self.pendingUnitCount = UnitCount(pendingUnitCount)
		}

		/// This creates a child progress, attached to the parent progress with the pending unit count specified when this struct was created.
		public func makeChild<Count: BinaryInteger>(totalUnitCount: Count) -> CSProgress {
			return CSProgress(totalUnitCount: totalUnitCount, parent: self.progress, pendingUnitCount: self.pendingUnitCount)
		}

		/// For the case where the child operation is atomic, just mark the pending units as complete rather than
		/// going to the trouble of creating a child progress.
		/// Can also be useful for error conditions where the operation should simply be skipped.
		public func markComplete() {
			self.progress.completedUnitCount += self.pendingUnitCount
		}

		/// Convenience methods to quickly cancel a progress, and check whether the progress is cancelled
		public func cancel() { self.progress.cancel() }
		public var isCancelled: Bool { return self.progress.isCancelled }

		/// Convenience methods to quickly make the parent progress the current progress object, in order to add something implicitly
		public func becomeCurrent() { self.progress.becomeCurrent(withPendingUnitCount: self.pendingUnitCount) }
		public func resignCurrent() { self.progress.resignCurrent() }
	}

	// The backing for a native Swift CSProgress.
	private final class SwiftBacking {
		private(set) var totalUnitCount: UnitCount
		private(set) var completedUnitCount: UnitCount = 0
		var isCompleted: Bool { return self.completedUnitCount == self.totalUnitCount }

		var fractionCompleted: Double {
			if self.completedUnitCount >= self.totalUnitCount {
				return 1.0
			}

			if self.totalUnitCount == 0 {
				return 0.0
			}

			let myPortion = Double(self.completedUnitCount)
			let childrenPortion = self.children.reduce(0) { $0 + $1.backing.fractionCompleted * Double($1._portionOfParent) }

			return (myPortion + childrenPortion) / Double(self.totalUnitCount)
		}

		private(set) var localizedDescription: String = ""
		private(set) var localizedAdditionalDescription: String = ""

		var isIndeterminate: Bool { return self.totalUnitCount == 0 && self.completedUnitCount == 0 }
		private(set) var isCancelled = false

		private(set) var children: [CSProgress] = []

		init(totalUnitCount: UnitCount) {
			self.totalUnitCount = totalUnitCount
		}

		// Setter for the properties affecting fractionCompleted. Pass nil to leave a property untouched.
		// Returning the new fraction in the completion handler allows us to save a switch by avoiding an extra
		// call to the backing, which helps eke out a little extra performance (this made more difference back
		// when this was a protocol and involved vtable dispatch; it may be possible to simplify now without
		// losing too much)

		func set(totalUnitCount: UnitCount?,
						 completedUnitCount changeType: UnitCountChangeType?,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping (_ fractionCompleted: Double, _ isCompleted: Bool) -> ()) {
			setupHandler()

			if let totalUnitCount = totalUnitCount {
				self.totalUnitCount = totalUnitCount
			}

			if let changeType = changeType {
				switch changeType {
				case let .set(newValue):
					self.completedUnitCount = newValue
				case let .increment(delta):
					self.completedUnitCount += delta
				}
			}

			completionHandler(self.fractionCompleted, self.isCompleted)
		}

		// General-purpose setter for the less frequently changed properties.

		func set(localizedDescription: String?,
						 localizedAdditionalDescription: String?,
						 cancel: Bool,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping () -> ()) {
			setupHandler()

			if let localizedDescription = localizedDescription {
				self.localizedDescription = localizedDescription
			}

			if let localizedAdditionalDescription = localizedAdditionalDescription {
				self.localizedAdditionalDescription = localizedAdditionalDescription
			}

			if cancel {
				self.isCancelled = true
			}

			completionHandler()
		}

		func addChild(_ child: CSProgress, pendingUnitCount: UnitCount) {
			if !self.children.contains(where: { $0 === child }) {
				self.children.append(child)
				child.portionOfParent = pendingUnitCount
			}
		}

		func removeChild(_ child: CSProgress) {
			self.children = self.children.filter { $0 !== child }
		}

		let debugDescriptionSuffix = "(native)"
	}

	/**
	 Corresponds to NSProgress's -discreteProgressWithTotalUnitCount:.

	 - parameter totalUnitCount: The total unit count for this progress.

	 - parameter granularity: Specifies the amount of change that should occur to the progress's fractionCompleted property before its notifications are fired.
	 This eliminates notifications that are too small to be noticeable, increasing performance.
	 Default value is 0.01.
	 */
	public class func discreteProgress<Count: BinaryInteger>(totalUnitCount: Count, granularity: Double = CSProgress.defaultGranularity) -> CSProgress {
		return self.init(totalUnitCount: totalUnitCount, parent: nil, pendingUnitCount: 0, granularity: granularity)
	}

	/**
	 Corresponds to NSProgress's -initWithTotalUnitCount:parent:pendingUnitCount:.

	 - parameter totalUnitCount: The total unit count for this progress.

	 - parameter parent: The progress's parent. Can be nil.

	 - parameter pendingUnitCount: The portion of the parent's totalUnitCount that this progress object represents. Pass zero for a nil parent.

	 - parameter granularity: Specifies the amount of change that should occur to the progress's fractionCompleted property before its notifications are fired.
	 This eliminates notifications that are too small to be noticeable, increasing performance.
	 Default value is 0.01.
	 */
	public init<Total: BinaryInteger, Pending: BinaryInteger>(totalUnitCount: Total, parent: CSProgress?, pendingUnitCount: Pending, granularity: Double = CSProgress.defaultGranularity) {
		self.backing = .swift(SwiftBacking(totalUnitCount: UnitCount(totalUnitCount)))
		self.parent = parent
		self._portionOfParent = UnitCount(totalUnitCount)
		self.granularity = granularity

		self.parent?.addChild(self, withPendingUnitCount: pendingUnitCount)
	}

	// The backing for this progress. All calls to methods and properties on the backing should be protected by our semaphore.
	private var backing: Backing

	// The access semaphore, allowing us to be thread-safe. A semaphore was chosen, because it performs better here than an NSLock or a dispatch queue.
	private var accessSemaphore = DispatchSemaphore(value: 1)

	// The parent progress object.
	private weak var parent: CSProgress?

	/// The total number of units of work to be carried out.
	public var totalUnitCount: UnitCount {
		get {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			return self.backing.totalUnitCount
		}
		set {
			self.updateUnitCount(totalUnitCount: newValue, completedUnitCount: nil)
		}
	}

	/// The number of units of work for the current job that have already been completed.
	public var completedUnitCount: UnitCount {
		get {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			return self.backing.completedUnitCount
		}
		set {
			self.updateUnitCount(totalUnitCount: nil, completedUnitCount: .set(newValue))
		}
	}

	/// Perform increment as one atomic operation, eliminating an unnecessary semaphore wait and increasing performance.
	public func incrementCompletedUnitCount<Count: BinaryInteger>(by interval: Count) {
		self.updateUnitCount(totalUnitCount: nil, completedUnitCount: .increment(UnitCount(interval)))
	}

	// The portion of the parent's unit count represented by the progress object.
	private var portionOfParent: UnitCount {
		get {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			return self._portionOfParent
		}
		set {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			self._portionOfParent = newValue
		}
	}
	private var _portionOfParent: UnitCount

	/// The fraction of the overall work completed by this progress object, including work done by any children it may have.
	public var fractionCompleted: Double {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self.backing.fractionCompleted
	}

	//// Indicates whether the tracked progress is indeterminate.
	public var isIndeterminate: Bool {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self.backing.isIndeterminate
	}

	/// Indicates whether the receiver is tracking work that has been cancelled.
	public var isCancelled: Bool {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self._isCancelled
	}

	private var _isCancelled: Bool {
		if let parent = self.parent, parent._isCancelled { return true }

		return self.backing.isCancelled
	}

	/// Cancel progress tracking.
	public func cancel() {
		self.updateMetadata(localizedDescription: nil, localizedAdditionalDescription: nil, cancel: true)
	}

	/// A localized description of progress tracked by the receiver.
	public var localizedDescription: String {
		get {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			return self.backing.localizedDescription
		}
		set {
			self.updateMetadata(localizedDescription: newValue, localizedAdditionalDescription: nil, cancel: false)
		}
	}

	/// A more specific localized description of progress tracked by the receiver.
	public var localizedAdditionalDescription: String {
		get {
			self.accessSemaphore.wait()
			defer { self.accessSemaphore.signal() }

			return self.backing.localizedAdditionalDescription
		}
		set {
			self.updateMetadata(localizedDescription: nil, localizedAdditionalDescription: newValue, cancel: false)
		}
	}

	private func updateUnitCount(totalUnitCount: UnitCount?, completedUnitCount: UnitCountChangeType?) {
		// For the NSProgress-backed type, the setters will be called asynchronously, to prevent KVO notifications from being fired on our own thread (and to improve performance).
		// Therefore, pass closures to .set() to let it take and release the semaphore rather than doing it ourselves.

		let setupHandler = { self.accessSemaphore.wait() }

		let completionHandler = { (fractionCompleted: Double, isCompleted: Bool) in
			// If our progress is finished, clean up a bit. Remove ourselves from the tree, and update the parent's change count.

			self.sendFractionCompletedNotifications(fractionCompleted: fractionCompleted, isCompleted: isCompleted) {
				self.accessSemaphore.signal()
			}
		}

		self.backing.set(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, setupHandler: setupHandler, completionHandler: completionHandler)
	}

	private func updateMetadata(localizedDescription: String?, localizedAdditionalDescription: String?, cancel: Bool) {
		let setupHandler = { self.accessSemaphore.wait() }

		let completionHandler = {
			self.sendDescriptionNotifications()

			if cancel {
				self.sendCancellationNotifications()
			}

			self.accessSemaphore.signal()
		}

		self.backing.set(localizedDescription: localizedDescription, localizedAdditionalDescription: localizedAdditionalDescription, cancel: cancel, setupHandler: setupHandler, completionHandler: completionHandler)
	}

	/**
	 Specifies the amount of change that should occur to the progress's fractionCompleted property before its notifications are fired.
	 This eliminates notifications that are too small to be noticeable, increasing performance.
	 Default value is 0.01.
	 */
	public let granularity: Double

	/**
	 Create a reference to a parent progress, encapsulating both it and its pending unit count.
	 This allows the child function to attach a new progress without knowing details about the parent progress and its unit count.
	 */
	public func pass<Count: BinaryInteger>(pendingUnitCount: Count) -> ParentReference {
		return ParentReference(progress: self, pendingUnitCount: UnitCount(pendingUnitCount))
	}

	/**
	 Add a progress object as a child of a progress tree. The inUnitCount indicates the expected work for the progress unit.

	 - parameter child: The NSProgress instance to add to the progress tree.

	 - parameter pendingUnitCount: The number of units of work to be carried out by the new child.
	 */
	public func addChild<Count: BinaryInteger>(_ child: CSProgress, withPendingUnitCount pendingUnitCount: Count) {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		// Progress objects in the same family tree share a semaphore to keep their values synced and to prevent shenanigans
		// (particularly when calculating fractionCompleted values).
		self.backing.addChild(child, pendingUnitCount: UnitCount(pendingUnitCount))
		child.accessSemaphore = self.accessSemaphore
	}

	// Remove a progress object from our progress tree.
	private func removeChild(_ child: CSProgress) {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		self.backing.removeChild(child)
		child.parent = nil
		child.accessSemaphore = DispatchSemaphore(value: 1)
	}

	private struct CancellationNotificationWrapper {
		let notification: CancellationNotification
		let queue: OperationQueue
	}

	private struct FractionCompletedNotificationWrapper {
		let notification: FractionCompletedNotification
		let queue: OperationQueue
	}

	private struct DescriptionNotificationWrapper {
		let notification: DescriptionNotification
		let queue: OperationQueue
	}

	private var cancellationNotifications: [UUID : CancellationNotificationWrapper] = [:]
	private var fractionCompletedNotifications: [UUID : FractionCompletedNotificationWrapper] = [:]
	private var descriptionNotifications: [UUID : DescriptionNotificationWrapper] = [:]
	private var lastNotifiedFractionCompleted: Double = 0.0

	// The add...Notification() methods return an identifier which can be later sent to remove...Notification() to remove the notification.

	private func _addCancellationNotification(onQueue queue: OperationQueue, notification: @escaping CancellationNotification) -> Any {
		let uuid = UUID()

		self.cancellationNotifications[uuid] = CancellationNotificationWrapper(notification: notification, queue: queue)

		return uuid
	}

	/**
	 Add a notification which will be called if the progress object is cancelled.

	 - parameter queue: Specifies an operation queue on which the notification will be fired.
	 The queue should either be a serial queue, or should have its maxConcurrentOperationCount set to something low
	 to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.

	 - parameter notification: A notification that will be called if the progress object is cancelled.

	 - returns: An opaque value that can be passed to removeCancellationNotification() to de-register the notification.
	 */
	@discardableResult
	public func addCancellationNotification(onQueue queue: OperationQueue = .main, notification: @escaping CancellationNotification) -> Any {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self._addCancellationNotification(onQueue: queue, notification: notification)
	}

	private func _removeCancellationNotification(identifier: Any) {
		guard let uuid = identifier as? UUID else { return }

		self.cancellationNotifications[uuid] = nil
	}

	/**
	 Remove a notification previously added via addCancellationNotification().

	 - parameter identifier: The identifier previously returned by addCancellationNotification() for the notification you wish to remove.
	 */
	public func removeCancellationNotification(identifier: Any) {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		self._removeCancellationNotification(identifier: identifier)
	}

	private func _addFractionCompletedNotification(onQueue queue: OperationQueue, notification: @escaping FractionCompletedNotification) -> Any {
		let uuid = UUID()

		self.fractionCompletedNotifications[uuid] = FractionCompletedNotificationWrapper(notification: notification, queue: queue)

		return uuid
	}

	/**
	 Add a notification which will be called when the progress object's fractionCompleted property changes by an amount greater than the progress object's granularity.

	 - parameter queue: Specifies an operation queue on which the notification will be fired.
	 The queue should either be a serial queue, or should have its maxConcurrentOperationCount set to something low
	 to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.

	 - parameter notification: A notification that will be called when the fractionCompleted property is significantly changed.
	 This notification will be called on the progress object's queue.

	 - returns: An opaque value that can be passed to removeFractionCompletedNotification() to de-register the notification.
	 */
	@discardableResult public func addFractionCompletedNotification(onQueue queue: OperationQueue = .main, notification: @escaping FractionCompletedNotification) -> Any {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return _addFractionCompletedNotification(onQueue: queue, notification: notification)
	}

	private func _removeFractionCompletedNotification(identifier: Any) {
		guard let uuid = identifier as? UUID else { return }

		self.fractionCompletedNotifications[uuid] = nil
	}

	/**
	 Remove a notification previously added via addFractionCompletedNotification().

	 - parameter identifier: The identifier previously returned by addFractionCompletedNotification() for the notification you wish to remove.
	 */
	public func removeFractionCompletedNotification(identifier: Any) {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		self._removeFractionCompletedNotification(identifier: identifier)
	}

	private func _addDescriptionNotification(onQueue queue: OperationQueue, notification: @escaping DescriptionNotification) -> Any {
		let uuid = UUID()

		self.descriptionNotifications[uuid] = DescriptionNotificationWrapper(notification: notification, queue: queue)

		return uuid
	}

	/**
	 Add a notification which will be called when the progress object's localizedDescription or localizedAdditionalDescription property changes.

	 - parameter queue: Specifies an operation queue on which the notification will be fired.
	 The queue should either be a serial queue, or should have its maxConcurrentOperationCount set to something low
	 to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.

	 - parameter notification: A notification that will be called when the fractionComplocalizedDescription or localizedAdditionalDescriptionleted property is changed.
	 This notification will be called on the progress object's queue.

	 - returns: An opaque value that can be passed to removeDescriptionNotification() to de-register the notification.
	 */
	@discardableResult public func addDescriptionNotification(onQueue queue: OperationQueue = .main, notification: @escaping DescriptionNotification) -> Any {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return _addDescriptionNotification(onQueue: queue, notification: notification)
	}

	private func _removeDescriptionNotification(identifier: Any) {
		guard let uuid = identifier as? UUID else { return }

		self.descriptionNotifications[uuid] = nil
	}

	/**
	 Remove a notification previously added via addDescriptionNotification().

	 - parameter identifier: The identifier previously returned by addDescriptionNotification() for the notification you wish to remove.
	 */
	public func removeDescriptionNotification(identifier: Any) {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		self._removeDescriptionNotification(identifier: identifier)
	}

	// Fire our cancellation notifications.
	// This method should be protected by our semaphore before calling it.
	private func sendCancellationNotifications() {
		let notifications = self.cancellationNotifications.values
		let children = self.backing.children

		for eachNotification in notifications {
			eachNotification.queue.addOperation {
				eachNotification.notification()
			}
		}

		for eachChild in children {
			eachChild.sendCancellationNotifications()
		}
	}

	// Fire our fractionCompleted notifications.
	// This method should be protected by our semaphore before calling it.
	private func sendFractionCompletedNotifications(fractionCompleted: Double, isCompleted: Bool, completionHandler: @escaping () -> ()) {
		let lastNotifiedFractionCompleted = self.lastNotifiedFractionCompleted
		let notifications = self.fractionCompletedNotifications.values
		let parent = self.parent

		if isCompleted, let parent = self.parent {
			parent.backing.removeChild(self)
			self.parent = nil

			parent.backing.set(totalUnitCount: nil, completedUnitCount: .increment(self._portionOfParent), setupHandler: {}) { _, _ in
				self.sendFractionCompletedNotifications(fractionCompleted: fractionCompleted, isCompleted: isCompleted) {
					parent.sendFractionCompletedNotifications(fractionCompleted: parent.backing.fractionCompleted, isCompleted: parent.backing.isCompleted, completionHandler: completionHandler)
				}
			}
		} else if abs(fractionCompleted - lastNotifiedFractionCompleted) >= self.granularity {
			let completedUnitCount = self.backing.completedUnitCount
			let totalUnitCount = self.backing.totalUnitCount

			for eachNotification in notifications {
				eachNotification.queue.addOperation {
					eachNotification.notification(completedUnitCount, totalUnitCount, fractionCompleted)
				}
			}

			self.lastNotifiedFractionCompleted = fractionCompleted

			if let parent = parent {
				parent.sendFractionCompletedNotifications(fractionCompleted: parent.backing.fractionCompleted, isCompleted: parent.backing.isCompleted, completionHandler: completionHandler)
			} else {
				completionHandler()
			}
		} else {
			completionHandler()
		}
	}

	// Fire our description notifications.
	// This method should be protected by our semaphore before calling it.
	private func sendDescriptionNotifications() {
		let description = self.backing.localizedDescription
		let additionalDescription = self.backing.localizedAdditionalDescription
		let notifications = self.descriptionNotifications.values

		for eachNotification in notifications {
			eachNotification.queue.addOperation {
				eachNotification.notification(description, additionalDescription)
			}
		}
	}

	public var debugDescription: String {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self._debugDescription
	}

	private var _debugDescription: String {
		let address = UInt(bitPattern: ObjectIdentifier(self).hashValue)
		let parentAddress = self.parent.map { UInt(bitPattern: ObjectIdentifier($0).hashValue) }

		var desc = "<\(String(describing: type(of: self))) 0x\(String(address, radix: 16)))>"

		desc += " : Parent: " + (parentAddress.map { "0x\(String($0, radix: 16))" } ?? "nil")
		desc += " / Fraction completed: \(self.backing.fractionCompleted)"
		desc += " / Completed: \(self.backing.completedUnitCount) of \(self.backing.totalUnitCount)"

		if self.parent != nil {
			desc += " (\(self._portionOfParent) of parent)"
		}

		desc += " \(self.backing.debugDescriptionSuffix)"

		for eachChild in self.backing.children {
			for eachLine in eachChild._debugDescription.components(separatedBy: "\n") {
				desc += "\n\t\(eachLine)"
			}
		}

		return desc
	}

	// MARK: Implicit Composition Crud
	// Note: The methods below exist to support implicit progress tree composition, which is necessary to make this class a drop-in replacement for NSProgress.
	// Note: This code contains some Objective-C compatibility crud as well which can be deleted if Objective-C compatibility is not important.

	// The key used to retrieve the current progress from Foundation's thread-specific dictionary.
	private static let currentProgressKey = "com.charlessoft.CSProgress.current"

	/// Returns the CSProgress instance, if any, associated with the current thread by a previous invocation of becomeCurrent(withPendingUnitCount:).
	public static func current() -> CSProgress? {
		return self._current?.progress
	}

	// Underlying storage for the current progress and its pending unit count.
	private static var _current: ParentReference? {
		get {
			return Thread.current.threadDictionary.object(forKey: self.currentProgressKey) as? ParentReference
		}
		set {
			if let parentRef = newValue {
				Thread.current.threadDictionary.setObject(parentRef, forKey: self.currentProgressKey as NSString)
			} else {
				Thread.current.threadDictionary.removeObject(forKey: self.currentProgressKey)
			}
		}
	}

	/**
	 Creates a new CSProgress object and attaches it to the CSProgress instance, if any, associated with the current thread
	 by a previous invocation of becomeCurrent(withPendingUnitCount:).
	 Will attach to NSProgress's current progress, if one is set and a current CSProgress is not.
	 This method is intended for backwards compatibility; it is recommended to explicitly build progress trees where possible.
	 Corresponds to NSProgress's -initWithTotalUnitCount:.

	 - parameter totalUnitCount: The total number of units of work to be carried out.

	 - parameter granularity: Specifies the amount of change that should occur to the progress's fractionCompleted property before its notifications are fired.
	 This eliminates notifications that are too small to be noticeable, increasing performance.
	 However, an operation to update the underlying NSProgress object will still be enqueued on every update.
	 Default value is 0.01.

	 - parameter queue: Specifies an operation queue on which the underlying NSProgress object, if there is one, will be updated.
	 The queue's maxConcurrentOperationCount should be set to something low to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.
	 */
	public convenience init<Count: BinaryInteger>(totalUnitCount: Count, granularity: Double = CSProgress.defaultGranularity, queue: OperationQueue = .main) {
		if let parentRef = CSProgress._current {
			let parent = parentRef.progress
			let pendingUnitCount = parentRef.pendingUnitCount

			self.init(totalUnitCount: totalUnitCount, parent: parent, pendingUnitCount: pendingUnitCount, granularity: granularity)

			// Prevent double-attaching
			parent.resignCurrent()
		} else if Foundation.Progress.current() != nil {
			// We have no way of knowing the current progress's pending unit count, so put a shim in between it and us
			let shim = Foundation.Progress(totalUnitCount: 1)

			let parent = CSProgress.bridge(from: shim, queue: queue)

			self.init(totalUnitCount: totalUnitCount, parent: parent, pendingUnitCount: 1, granularity: granularity)
		} else {
			self.init(totalUnitCount: totalUnitCount, parent: nil, pendingUnitCount: 0, granularity: granularity)
		}
	}

	/**
	 Sets the receiver as the current progress object of the current thread and specifies the portion of work to be performed by the next child progress object of the receiver.
	 Also sets its bridged NSProgress as the current NSProgress, with the same pending unit count.
	 Do not attach both an NSProgress and a CSProgress implicitly after calling this method; the result is undefined behavior.
	 This method is intended for backwards compatibility; it is recommended to explicitly build progress trees where possible.
	 Corresponds to NSProgress's -becomeCurrentWithPendingUnitCount:.

	 - parameter unitCount: The number of units of work to be carried out by the next progress object that is initialized by invoking the init(parent:userInfo:) method in the current thread with the receiver set as the parent. This number represents the portion of work to be performed in relation to the total number of units of work to be performed by the receiver (represented by the value of the receiver’s totalUnitCount property). The units of work represented by this parameter must be the same units of work that are used in the receiver’s totalUnitCount property.

	 - parameter queue: Specifies an operation queue on which to update any NSProgress objects that may be implicitly added as children.
	 The queue's maxConcurrentOperationCount should be set to something low to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.
	 */
	public func becomeCurrent<Count: BinaryInteger>(withPendingUnitCount unitCount: Count, queue: OperationQueue = .main) {
		CSProgress._current = ParentReference(progress: self, pendingUnitCount: UnitCount(unitCount))

		let ns: Foundation.Progress = {
			switch self.backing {
			case .swift:
				let ns = Foundation.Progress(totalUnitCount: Int64(unitCount))
				let wrapper = CSProgress(wrappedNSProgress: ns, parent: self, pendingUnitCount: unitCount, queue: queue)

				self.addChild(wrapper, withPendingUnitCount: unitCount)

				return ns
			case .objectiveC:
				return self.bridgeToNSProgress()
			}
		}()

		ns.becomeCurrent(withPendingUnitCount: Int64(unitCount))
	}

	/**
	 Balance the most recent previous invocation of becomeCurrent(withPendingUnitCount:) on the same thread by restoring the current progress object to what it was before becomeCurrent(withPendingUnitCount:) was invoked.
	 Also invokes resignCurrent() on its bridged NSProgress object.
	 Corresponds to NSProgress's -resignCurrent.
	 */
	public func resignCurrent() {
		if CSProgress.current() === self {
			CSProgress._current = nil
		}

		if let currentNS = Foundation.Progress.current() {
			switch self.backing {
			case let .swift(backing):
				self.accessSemaphore.wait()
				defer { self.accessSemaphore.signal() }

				if backing.children.contains(where: { $0._bridgeToNSProgress() === currentNS }) {
					currentNS.resignCurrent()
				}
			case .objectiveC:
				self.bridgeToNSProgress().resignCurrent()
			}
		}
	}

	// If Objective-C compatibility is not needed, uncomment the following line and delete everything below it.
	// private typealias Backing = SwiftBacking

	// MARK: Objective-C Compatibility Crud
	// Note: Everything below this point exists for Objective-C interoperability. If Objective-C compatibility is not important, feel free to delete everything below.
	// Warning: The code gets notably uglier beyond this point. All hope abandon, ye who enter here!

	private enum Backing {
		// Since we are going for source compatibility with NSProgress and thus need to use standard init() methods, and since we can't have factory initializers,
		// separate the backing out into a separate private structure. We have separate implementations for an all-native CSProgress and one that's wrapping an NSProgress.
		// All calls to methods on the backing should be protected by the progress's semaphore.

		case swift(SwiftBacking)
		case objectiveC(ObjectiveCBacking)

		var totalUnitCount: UnitCount {
			switch self {
			case let .swift(backing):
				return backing.totalUnitCount
			case let .objectiveC(backing):
				return backing.totalUnitCount
			}
		}

		var completedUnitCount: UnitCount {
			switch self {
			case let .swift(backing):
				return backing.completedUnitCount
			case let .objectiveC(backing):
				return backing.completedUnitCount
			}
		}

		var fractionCompleted: Double {
			switch self {
			case let .swift(backing):
				return backing.fractionCompleted
			case let .objectiveC(backing):
				return backing.fractionCompleted
			}
		}

		var isCompleted: Bool {
			switch self {
			case let .swift(backing):
				return backing.isCompleted
			case let .objectiveC(backing):
				return backing.isCompleted
			}
		}

		var localizedDescription: String {
			switch self {
			case let .swift(backing):
				return backing.localizedDescription
			case let .objectiveC(backing):
				return backing.localizedDescription
			}
		}

		var localizedAdditionalDescription: String {
			switch self {
			case let .swift(backing):
				return backing.localizedAdditionalDescription
			case let .objectiveC(backing):
				return backing.localizedAdditionalDescription
			}
		}

		var isIndeterminate: Bool {
			switch self {
			case let .swift(backing):
				return backing.isIndeterminate
			case let .objectiveC(backing):
				return backing.isIndeterminate
			}
		}

		var isCancelled: Bool {
			switch self {
			case let .swift(backing):
				return backing.isCancelled
			case let .objectiveC(backing):
				return backing.isCancelled
			}
		}

		// Setter for the properties affecting fractionCompleted. Pass nil to leave a property untouched.
		// Returning the new fraction in the completion handler allows us to reduce dynamic dispatch by avoiding an extra
		// call to the backing, which helps eke out a little extra performance.

		func set(totalUnitCount: UnitCount?,
						 completedUnitCount: UnitCountChangeType?,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping (_ fractionCompleted: Double, _ isCompleted: Bool) -> ()) {
			switch self {
			case let .swift(backing):
				backing.set(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, setupHandler: setupHandler, completionHandler: completionHandler)
			case let .objectiveC(backing):
				backing.set(totalUnitCount: totalUnitCount, completedUnitCount: completedUnitCount, setupHandler: setupHandler, completionHandler: completionHandler)
			}
		}

		// General-purpose setter for the less frequently changed properties.
		func set(localizedDescription: String?,
						 localizedAdditionalDescription: String?,
						 cancel: Bool,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping () -> ()) {
			switch self {
			case let .swift(backing):
				backing.set(localizedDescription: localizedDescription, localizedAdditionalDescription: localizedAdditionalDescription, cancel: cancel, setupHandler: setupHandler, completionHandler: completionHandler)
			case let .objectiveC(backing):
				backing.set(localizedDescription: localizedDescription, localizedAdditionalDescription: localizedAdditionalDescription, cancel: cancel, setupHandler: setupHandler, completionHandler: completionHandler)
			}
		}

		var children: [CSProgress] {
			switch self {
			case let .swift(backing):
				return backing.children
			case let .objectiveC(backing):
				return backing.children
			}
		}

		func addChild(_ child: CSProgress, pendingUnitCount: UnitCount) {
			switch self {
			case let .swift(backing):
				backing.addChild(child, pendingUnitCount: pendingUnitCount)
			case let .objectiveC(backing):
				backing.addChild(child, pendingUnitCount: pendingUnitCount)
			}
		}

		func removeChild(_ child: CSProgress) {
			switch self {
			case let .swift(backing):
				backing.removeChild(child)
			case let .objectiveC(backing):
				backing.removeChild(child)
			}
		}

		var debugDescriptionSuffix: String {
			switch self {
			case let .swift(backing):
				return backing.debugDescriptionSuffix
			case let .objectiveC(backing):
				return backing.debugDescriptionSuffix
			}
		}
	}

	// The backing for a CSProgress wrapping an NSProgress.
	private final class ObjectiveCBacking: NSObject {
		let progress: Foundation.Progress
		let queue: OperationQueue

		private var isUpdatingKey: pthread_key_t = 0

		init(progress: Foundation.Progress, queue: OperationQueue) {
			self.progress = progress
			self.queue = queue

			super.init()

			// Create a thread-local key to keep track of whether we are in the middle of an update.
			// This is to suppress KVO notifications caused by ourselves and prevent infinite loops.
			// We use a thread-local variable to avoid race conditions that could inadvertently cause
			// the suppression of KVO notifications sent from other threads.
			// Use pthread specific values rather than NSThread's threadDictionary here, for performance
			// reasons.

			pthread_key_create(&self.isUpdatingKey) {
				let ptr = $0.bindMemory(to: Bool.self, capacity: 1)

				ptr.deinitialize(count: 1)
				ptr.deallocate()
			}

			self.startWatching()
		}

		deinit {
			self.stopWatching()
		}

		// Returns whether we're in the middle of an update of one of our properties on this thread.
		// If this is true, we want to ignore any KVO notifications that come in, because they'll just be caused by us.
		private var isUpdating: Bool {
			get {
				return pthread_getspecific(self.isUpdatingKey)?.bindMemory(to: Bool.self, capacity: 1).pointee ?? false
			}
			set {
				if let ptr = pthread_getspecific(self.isUpdatingKey)?.bindMemory(to: Bool.self, capacity: 1) {
					ptr.pointee = newValue
				} else {
					let ptr = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
					ptr.initialize(to: newValue)

					pthread_setspecific(self.isUpdatingKey, ptr)
				}
			}
		}

		// Pass through all these properties to the underlying progress object.
		var totalUnitCount: UnitCount { return self.progress.totalUnitCount }
		var completedUnitCount: UnitCount { return self.progress.completedUnitCount }
		var fractionCompleted: Double { return self.progress.fractionCompleted }
		var isCompleted: Bool { return self.completedUnitCount == self.totalUnitCount }
		var localizedDescription: String { return self.progress.localizedDescription }
		var localizedAdditionalDescription: String { return self.progress.localizedAdditionalDescription }
		var isIndeterminate: Bool { return self.progress.isIndeterminate }
		var isCancelled: Bool { return self.progress.isCancelled }

		func set(totalUnitCount: UnitCount?,
						 completedUnitCount changeType: UnitCountChangeType?,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping (_ fractionCompleted: Double, _ isCompleted: Bool) -> ()) {
			// Make our changes on the queue, to avoid jamming up the worker thread with KVO notifications.
			queue.addOperation {
				setupHandler()

				self.isUpdating = true

				if let totalUnitCount = totalUnitCount {
					self.progress.totalUnitCount = Int64(totalUnitCount)
				}

				if let changeType = changeType {
					switch changeType {
					case let .set(newValue):
						if newValue != self.progress.completedUnitCount {
							self.progress.completedUnitCount = Int64(newValue)
						}
					case let .increment(delta):
						self.progress.completedUnitCount += Int64(delta)
					}
				}

				self.isUpdating = false

				completionHandler(self.fractionCompleted, self.isCompleted)
			}
		}

		func set(localizedDescription: String?,
						 localizedAdditionalDescription: String?,
						 cancel: Bool,
						 setupHandler: @escaping () -> (),
						 completionHandler: @escaping () -> ()) {
			queue.addOperation {
				setupHandler()

				self.isUpdating = true

				if let localizedDescription = localizedDescription {
					self.progress.localizedDescription = localizedDescription
				}

				if let localizedAdditionalDescription = localizedAdditionalDescription {
					self.progress.localizedAdditionalDescription = localizedAdditionalDescription
				}

				if cancel {
					self.progress.cancel()
				}

				self.isUpdating = false

				completionHandler()
			}
		}

		var children: [CSProgress] { return [] }

		func addChild(_ child: CSProgress, pendingUnitCount: UnitCount) {
			if #available(macOS 10.11, *) {
				self.progress.addChild(child.bridgeToNSProgress(queue: self.queue), withPendingUnitCount: Int64(pendingUnitCount))
			} else {
				// Since we can't addChild on older OS versions, create a shim for our child, implicitly add the child to the shim, and explicitly add the shim to us.
				// FIXME: this has not been tested yet.
				self.progress.becomeCurrent(withPendingUnitCount: Int64(pendingUnitCount))
				let shim = Foundation.Progress(totalUnitCount: 1)
				self.progress.resignCurrent()

				CSProgress.bridge(from: shim).addChild(child, withPendingUnitCount: 1)
			}
		}

		func removeChild(_ child: CSProgress) {}

		var fractionCompletedUpdatedHandler: (() -> ())?
		var indeterminateHandler: (() -> ())?
		var descriptionUpdatedHandler: (() -> ())?
		var cancellationHandler: (() -> ())?

		var debugDescriptionSuffix: String {
			let address = UInt(bitPattern: ObjectIdentifier(self.progress).hashValue)

			return "(wrapping: 0x\(String(address, radix: 16)))"
		}

		private var kvoObservations: [NSKeyValueObservation] = []

		private func startWatching() {
			// For each observation, if this change was caused by something we did ourselves,
			// ignore the notification or we'll just keep going back and forth forever.

			self.kvoObservations.append(self.progress.observe(\.fractionCompleted) { [weak self] _, _ in
				if let sSelf = self, !sSelf.isUpdating, let handler = sSelf.fractionCompletedUpdatedHandler {
					sSelf.queue.addOperation(handler)
				}
			})

			self.kvoObservations.append(self.progress.observe(\.isIndeterminate) { [weak self] _, _ in
				if let sSelf = self, !sSelf.isUpdating, let handler = sSelf.indeterminateHandler {
					sSelf.queue.addOperation(handler)
				}
			})

			self.kvoObservations.append(self.progress.observe(\.isCancelled) { [weak self] _, _ in
				if let sSelf = self, !sSelf.isUpdating, let handler = sSelf.cancellationHandler {
					sSelf.queue.addOperation(handler)
				}
			})

			self.kvoObservations.append(self.progress.observe(\.localizedDescription) { [weak self] _, _ in
				if let sSelf = self, !sSelf.isUpdating, let handler = sSelf.descriptionUpdatedHandler {
					sSelf.queue.addOperation(handler)
				}
			})

			self.kvoObservations.append(self.progress.observe(\.localizedAdditionalDescription) { [weak self] _, _ in
				if let sSelf = self, !sSelf.isUpdating, let handler = sSelf.descriptionUpdatedHandler {
					sSelf.queue.addOperation(handler)
				}
			})
		}

		private func stopWatching() {
			self.kvoObservations.forEach { $0.invalidate() }
			self.kvoObservations = []
		}
	}

	/**
	 Create a CSProgress which wraps an NSProgress.
	 All updates to the underlying progress object will be performed on the provided queue, to keep NSProgress's KVO notifications out of the worker thread as much as possible.
	 However, due to the need to keep the underlying progress object in sync, an operation is enqueued on every update of completedUnitCount regardless of the granularity.
	 Therefore, performance is poor when using the resulting object as you would a normal CSProgress object, because this will result in excessive queued operations,
	 as well as many KVO notifications sent by NSOperation and NSOperationQueue.
	 Progress objects created in this way should therefore only be used as parents or children for native CSProgress objects, in order to attach to an existing NSProgress tree.
	 This is most useful when interacting with Objective-C code, or when using an NSProgress as the root of the tree in order to bind UI elements to it via KVO.

	 - parameter wrappedNSProgress: The underlying NSProgress object.

	 - parameter parent: The parent progress. Can be nil.

	 - parameter pendingUnitCount: The portion of the parent's totalUnitCount that this progress object represents. Pass zero for a nil parent.

	 - parameter granularity: Specifies the amount of change that should occur to the progress's fractionCompleted property before its notifications are fired.
	 This eliminates notifications that are too small to be noticeable, increasing performance.
	 However, an operation to update the underlying NSProgress object will still be enqueued on every update.
	 Default value is 0.01.

	 - parameter queue: Specifies an operation queue on which the underlying NSProgress object will also be updated.
	 The queue's maxConcurrentOperationCount should be set to something low to prevent excessive threads from being created.
	 This parameter defaults to the main operation queue.
	 */
	private init<Count: BinaryInteger>(wrappedNSProgress: Foundation.Progress, parent: CSProgress?, pendingUnitCount: Count, granularity: Double = CSProgress.defaultGranularity, queue: OperationQueue = .main) {
		let backing = ObjectiveCBacking(progress: wrappedNSProgress, queue: queue)

		self.backing = .objectiveC(backing)
		self.parent = parent
		self._portionOfParent = UnitCount(pendingUnitCount)
		self.granularity = granularity

		// These handlers are called as a result of KVO notifications sent by the underlying progress object.

		backing.fractionCompletedUpdatedHandler = { [weak self, weak backing] in
			guard let sSelf = self, let sBacking = backing else { return }

			sSelf.accessSemaphore.wait()

			sSelf.sendFractionCompletedNotifications(fractionCompleted: sBacking.fractionCompleted, isCompleted: sBacking.isCompleted) {
				sSelf.accessSemaphore.signal()
			}
		}

		backing.descriptionUpdatedHandler = { [weak self] in
			guard let sSelf = self else { return }

			sSelf.accessSemaphore.wait()
			defer { sSelf.accessSemaphore.signal() }

			sSelf.sendDescriptionNotifications()
		}

		backing.cancellationHandler = { [weak self] in
			guard let sSelf = self else { return }

			sSelf.accessSemaphore.wait()
			defer { sSelf.accessSemaphore.signal() }

			sSelf.sendCancellationNotifications()
		}

		self.parent?.addChild(self, withPendingUnitCount: pendingUnitCount)
	}

	// An NSProgress subclass that wraps a CSProgress.
	private final class BridgedNSProgress: Foundation.Progress {
		private(set) weak var progress: CSProgress?

		private var fractionCompletedIdentifier: Any?
		private var descriptionIdentifier: Any?
		private var cancellationIdentifier: Any?

		init(progress: CSProgress, queue: OperationQueue = .main) {
			self.progress = progress

			super.init(parent: nil, userInfo: nil)

			// Directly access the primitive accessors, because this class will only be created while already protected by the semaphore.
			super.totalUnitCount = progress.backing.totalUnitCount
			super.completedUnitCount = progress.backing.completedUnitCount
			super.localizedDescription = progress.backing.localizedDescription
			super.localizedAdditionalDescription = progress.backing.localizedAdditionalDescription
			if progress.backing.isCancelled { super.cancel() }

			// Register notifications on the underlying CSProgress, to update our properties.

			self.fractionCompletedIdentifier = progress._addFractionCompletedNotification(onQueue: queue) { completed, total, _ in
				super.completedUnitCount = completed
				super.totalUnitCount = total
			}

			self.descriptionIdentifier = progress._addDescriptionNotification(onQueue: queue) { desc, aDesc in
				super.localizedDescription = desc
				super.localizedAdditionalDescription = aDesc
			}

			self.cancellationIdentifier = progress._addCancellationNotification(onQueue: queue) {
				super.cancel()
			}
		}

		deinit {
			self.fractionCompletedIdentifier.map { self.progress?.removeFractionCompletedNotification(identifier: $0) }
			self.descriptionIdentifier.map { self.progress?.removeDescriptionNotification(identifier: $0) }
			self.cancellationIdentifier.map { self.progress?.removeCancellationNotification(identifier: $0) }
		}

		override var totalUnitCount: Int64 {
			didSet { self.progress?.totalUnitCount = UnitCount(self.totalUnitCount) }
		}

		override var completedUnitCount: Int64 {
			didSet { self.progress?.completedUnitCount = UnitCount(self.completedUnitCount) }
		}

		override var fractionCompleted: Double { return self.progress?.fractionCompleted ?? 0.0 }

		override var localizedDescription: String! {
			didSet { self.progress?.localizedDescription = self.localizedDescription }
		}

		override var localizedAdditionalDescription: String! {
			didSet { self.progress?.localizedAdditionalDescription = self.localizedAdditionalDescription }
		}
	}

	private var bridgedNSProgress: Foundation.Progress?

	/**
	 Return an NSProgress object bridged to the receiver.
	 If the receiver is already bridged to an NSProgress object, that object will be returned. Otherwise, one will be created.

	 - parameter queue: If a new NSProgress object is created, configure it to be updated on the provided queue.
	 This queue should either be a serial queue, or should have its maxConcurrentOperationCount property set to a low value
	 to avoid excessive threads being spawned.
	 Defaults to the main operation queue.
	 */
	public func bridgeToNSProgress(queue: OperationQueue = .main) -> Foundation.Progress {
		self.accessSemaphore.wait()
		defer { self.accessSemaphore.signal() }

		return self._bridgeToNSProgress(queue: queue)
	}

	private func _bridgeToNSProgress(queue: OperationQueue = .main) -> Foundation.Progress {
		// If we're wrapping an NSProgress, return that. Otherwise wrap ourselves in a BridgedNSProgress.

		switch self.backing {
		case let .objectiveC(backing):
			return backing.progress
		case .swift:
			if let bridged = self.bridgedNSProgress {
				return bridged
			} else {
				let bridged = BridgedNSProgress(progress: self, queue: queue)

				self.bridgedNSProgress = bridged

				return bridged
			}
		}
	}

	/**
	 Return a CSProgress object bridged to the provided NSProgress object.
	 If the given NSProgress object is already bridged to a CSProgress object, that object will be returned. Otherwise, one will be created.

	 - parameter ns: The NSProgress object to be bridged to CSProgress.

	 - parameter granularity: If a new CSProgress object is created, its granularity will be set to this value.

	 - parameter queue: If a new CSProgress object is created, configure it to update the original NSProgress object on the provided queue.
	 This queue should either be a serial queue, or should have its maxConcurrentOperationCount property set to a low value
	 to avoid excessive threads being spawned.
	 Defaults to the main operation queue.
	 */
	public static func bridge(from ns: Foundation.Progress, granularity: Double = CSProgress.defaultGranularity, queue: OperationQueue = .main) -> CSProgress {
		// If it's wrapping a CSProgress, return that. Otherwise, wrap that sucker

		if let bridged = ns as? BridgedNSProgress, let bridgedProgress = bridged.progress {
			return bridgedProgress
		} else {
			return CSProgress(wrappedNSProgress: ns, parent: nil, pendingUnitCount: 0, granularity: granularity, queue: queue)
		}
	}
}

extension CSProgress: _ObjectiveCBridgeable {
	public typealias _ObjectiveCType = Foundation.Progress

	public func _bridgeToObjectiveC() -> Foundation.Progress {
		return self.bridgeToNSProgress()
	}

	public static func _forceBridgeFromObjectiveC(_ ns: Foundation.Progress, result: inout CSProgress?) {
		result = self.bridge(from: ns)
	}

	public static func _conditionallyBridgeFromObjectiveC(_ ns: Foundation.Progress, result: inout CSProgress?) -> Bool {
		result = self.bridge(from: ns)
		return true
	}

	public static func _unconditionallyBridgeFromObjectiveC(_ ns: Foundation.Progress?) -> CSProgress {
		return self.bridge(from: ns!)
	}
}

//
//  SourceRefreshController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
import os.log
import Plains
import BackgroundTasks
import HTTPTypes
import HTTPTypesFoundation

class SourceRefreshController: NSObject {

	enum Priority {
		case foreground, background

		var qos: DispatchQoS {
			switch self {
			case .foreground: return .default
			case .background: return .background
			}
		}

		var taskPriority: TaskPriority {
			switch self {
			case .foreground: return .medium
			case .background: return .background
			}
		}

		var maximumThreads: Int {
			switch self {
			case .foreground: return UIDevice.current.performanceThreads
			case .background: return UIDevice.current.efficiencyThreads
			}
		}
	}

	struct JobGroup {
		let signpost: Signpost
		let dispatchGroup: DispatchGroup
		let sourceUUID: String
	}

	struct Job: Identifiable, Hashable, Equatable {
		let group: JobGroup
		let request: URLRequest
		let sourceFile: SourceFile

		var id: Int { request.hashValue }
		var url: URL { request.url! }

		var filename: String { group.sourceUUID + sourceFile.name }
		var destinationURL: URL { listsURL/filename }
		var partialURL: URL { partialListsURL/filename }

		func hash(into hasher: inout Hasher) {
			hasher.combine(request)
			hasher.combine(filename)
		}

		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.id == rhs.id
		}
	}

	struct SourceState {
		let sourceUUID: String
		let progress: Progress
		var errors = [RefreshError]()

		fileprivate mutating func addError(_ error: RefreshError) {
			errors.append(error)
		}
	}

	enum RefreshError: Error, LocalizedError {
		case httpError(sourceUUID: String, url: URL, httpError: HTTPError)
		case invalidContentType(sourceUUID: String, url: URL, contentType: String)
		case generalError(sourceUUID: String, url: URL, error: Error)

		var localizedDescription: String {
			switch self {
			case .httpError(_, _, let httpError):
				switch httpError {
				case .status(let response):
					switch response.status {
					case .notFound: return .localize("Source not found. A repository may no longer exist at this address.")
					default:        return httpError.localizedDescription
					}

				case .cancelled:
					return httpError.localizedDescription

				case .badResponse:
					return .localize("The server returned an invalid response.")

				case .general(let error):
					let nsError = error as NSError
					switch (nsError.domain, nsError.code) {
					case (NSURLErrorDomain, NSURLErrorAppTransportSecurityRequiresSecureConnection):
						return .localize("The server doesn’t use a secure (HTTPS) connection. Zebra requires a secure connection to load this source.")

					case (NSURLErrorDomain, NSURLErrorSecureConnectionFailed):
						return .localize("The server failed to establish a secure (HTTPS) connection. Zebra requires a secure connection to load this source.")

					default:
						return (error as? LocalizedError)?.localizedDescription ?? nsError.localizedDescription
					}
				}

			case .invalidContentType(_, _, let contentType):
				return String(format: .localize("The server returned an invalid response (MIME type: %@). A repository may no longer exist at this address."), contentType)

			case .generalError(_, _, let error):
				return (error as? LocalizedError)?.localizedDescription ?? (error as NSError).localizedDescription
			}
		}
	}

	static let refreshProgressDidChangeNotification = Notification.Name(rawValue: "SourceRefreshProgressDidChangeNotification")
	static let refreshDidFinishNotification = Notification.Name(rawValue: "SourceRefreshDidFinishNotification")

	private static let legacySourceHosts = ["repo.dynastic.co", "apt.bingner.com"]

	static let listsURL = PlainsConfig.shared.fileURL(forKey: "Dir::State::lists")!
	static let partialListsURL = PlainsConfig.shared.fileURL(forKey: "Dir::State::lists")!/"partial"

	private static let packagesTypePriority: [SourceFileKind] = {
		let order = PlainsConfig.shared.compressionTypes
			.compactMap(SourceFileKind.init(aptCompressorName:))
		if !order.isEmpty {
			return order
		}
		return [.zstd, .xz, .lzma, .bzip2, .gzip]
	}()

	static let shared = SourceRefreshController()

	private(set) var priority: Priority = .foreground
	private var parallelJobsCount: Int {
		switch priority {
		case .foreground: return 16
		case .background: return 8
		}
	}
	private var parallelDecompressJobsCount: Int { priority.maximumThreads * 2 }

	private(set) var progress = Progress(totalUnitCount: 1)
	private var innerProgress: Progress?
	private(set) var sourceStates = [String: SourceState]()

	private var controlQueue: DispatchQueue!
	private var workQueue: DispatchQueue!
	private var jobQueue: JobQueue<Job>!
	private var decompressJobQueue: JobQueue<Job>!
	private var operationQueue: OperationQueue!
	private var dispatchGroup: DispatchGroup!
	private let wakeLock = WakeLock(label: "com.getzbra.zebra.source-refresh-wake-lock")

	private var session: URLSession?
	private var currentRefreshJobs = [String: Set<Job>]()
	internal var backgroundTask: BGTask?

	internal let logger = Logger(subsystem: "com.getzbra.zebra", category: "SourceRefreshOperation")
	private let signpost = Signpost(subsystem: "com.getzbra.zebra", name: "SourceRefreshOperation", format: "Refresh")

	var isRefreshing: Bool { !progress.isFinished && !progress.isCancelled }
	var refreshErrors: [RefreshError] { sourceStates.values.reduce([], { $0 + $1.errors }) }

	private override init() {
		super.init()

		registerNotifications()
		registerBackgroundTask()
	}

	func refresh(priority: Priority = .foreground) {
		if isRefreshing {
			self.progress.addCancellationNotification {
				self.refresh(priority: priority)
			}
			self.progress.cancel()
			return
		}

		self.priority = priority

		controlQueue = DispatchQueue(label: "com.getzbra.zebra.source-refresh-control-queue", qos: priority.qos)
		workQueue = DispatchQueue(label: "com.getzbra.zebra.source-refresh-work-queue", qos: priority.qos)

		workQueue.async {
			// TODO: Work out why this happens?
			guard self.controlQueue != nil && self.workQueue != nil else {
				self.refresh(priority: priority)
				return
			}

			let sources = SourceManager.shared.sources

			self.jobQueue = JobQueue(queue: self.workQueue, taskLimit: self.parallelJobsCount, queueProcessor: self.fetch)
			self.decompressJobQueue = JobQueue(queue: self.workQueue, taskLimit: self.parallelDecompressJobsCount, queueProcessor: self.decompress)

			self.operationQueue = OperationQueue()
			self.operationQueue.maxConcurrentOperationCount = self.parallelJobsCount
			self.operationQueue.underlyingQueue = self.workQueue

			self.dispatchGroup = DispatchGroup()

			Preferences.lastSourceUpdate = Date()
			self.scheduleNextRefresh()

			self.signpost.begin()

			self.sourceStates.removeAll()
			self.currentRefreshJobs.removeAll()

			let configuration = URLSession.download.configuration.copy() as! URLSessionConfiguration
			configuration.timeoutIntervalForRequest = Preferences.sourceRefreshTimeout
			self.session = URLSession(configuration: configuration,
																delegate: nil,
																delegateQueue: self.operationQueue)

			self.wakeLock.lock()

			// Notify in 0.1% increments, i.e. at most 1000 notifications will be posted
			self.progress = Progress(totalUnitCount: 100, granularity: 0.001, queue: self.operationQueue)
			self.progress.addFractionCompletedNotification { _, _, _ in
				NotificationCenter.default.post(name: Self.refreshProgressDidChangeNotification, object: nil)
			}

			// Start at 10% so the user knows we’re doing stuff.
			self.progress.completedUnitCount = 10

			self.innerProgress = Progress(totalUnitCount: SourceManager.shared.sources.count + 1,
																		parent: self.progress,
																		pendingUnitCount: 90,
																		granularity: 0.001)
			self.innerProgress!.addCancellationNotification { self.cancel() }

			// Start the state machine for each source with InRelease.
			for source in sources {
				let group = JobGroup(signpost: Signpost(subsystem: self.signpost.subsystem, name: "SourceRefreshJob", format: "%@", source.uuid),
														 dispatchGroup: DispatchGroup(),
														 sourceUUID: source.uuid)
				group.signpost.begin()

				let progress = Progress(totalUnitCount: 1000, parent: self.innerProgress!, pendingUnitCount: 1)
				progress.addCancellationNotification {
					self.dispatchGroup.leave()
				}

				self.sourceStates[group.sourceUUID] = SourceState(sourceUUID: group.sourceUUID, progress: progress)
				self.currentRefreshJobs[group.sourceUUID] = Set()
				self.dispatchGroup.enter()
				self.continueJob(group: group, withSourceFile: .inRelease)
				self.continueJob(group: group, withSourceFile: .featured)
				self.continueJob(group: group, withSourceFile: .paymentEndpoint)
			}

			self.dispatchGroup.notify(queue: self.workQueue) {
				if self.isRefreshing {
					self.finishRefresh()
				}
			}
		}
	}

	// MARK: - Job Lifecycle

	private func continueJob(group: JobGroup, withSourceFile sourceFile: SourceFile) {
		guard let source = SourceManager.shared.source(forUUID: group.sourceUUID) else {
			return
		}

		var baseURLs = [URL]()
		switch sourceFile {
		case .inRelease, .release, .releaseGpg, .paymentEndpoint, .featured:
			baseURLs.append(source.baseURI)

		case .packages(_):
			if source.components.isEmpty {
				baseURLs.append(source.baseURI)
			} else {
				// TODO: The state machine isn’t compatible with splitting off into multiple requests here
				for component in source.components {
					for architecture in source.architectures {
						if architecture != "all" {
							baseURLs.append(source.baseURI/component/"binary-\(architecture)")
						}
					}
				}
			}
		}

		for baseURL in baseURLs {
			let downloadURL = baseURL/sourceFile.name
			let destinationURL = Self.partialListsURL/(group.sourceUUID + sourceFile.name)

			let request = self.request(for: downloadURL, destinationURL: destinationURL)
			let newJob = Job(group: group,
											 request: request,
											 sourceFile: sourceFile)

			currentRefreshJobs[group.sourceUUID]?.insert(newJob)
			jobQueue.enqueue(job: newJob)
			group.dispatchGroup.enter()
			group.signpost.event(format: "Queued: %@", downloadURL.absoluteString)
		}
	}

	private func request(for downloadURL: URL, destinationURL: URL) -> URLRequest {
		guard let url = downloadURL.secureURL?.standardized else {
			fatalError("Insecure URL was passed")
		}

		var request = HTTPRequest(method: .get,
															url: url,
															headerFields: URLController.aptHeaders)

		// Handle legacy headers for specific repos that require them.
		if Self.legacySourceHosts.contains(downloadURL.host ?? "") {
			request.headerFields.append(contentsOf: URLController.legacyAPTHeaders)
		}

		// If we already have an old version of this file, set If-None-Match or If-Modified-Since so the
		// server can give us a 304 Not Modified response.
		if let etag = try? destinationURL.extendedAttribute(forKey: URL.etagXattr) {
			request.headerFields[.ifNoneMatch] = etag
		} else if let values = try? destinationURL.resourceValues(forKeys: [.contentModificationDateKey]),
							let date = values.contentModificationDate {
			request.headerFields[.ifModifiedSince] = DateFormatter.rfc822.string(from: date)
		}

		// Just go ahead and try HTTP/3 first without probing for whether it’s supported by the
		// server. Since most repos are hosted on GitHub or Cloudflare, this is a safe-ish bet.
		var urlRequest = URLRequest(httpRequest: request)!
		urlRequest.assumesHTTP3Capable = true
		urlRequest.timeoutInterval = Preferences.sourceRefreshTimeout
		return urlRequest
	}

	private func fetch(job: Job) {
		guard let session = session else {
			return
		}

		#if DEBUG
		logger.debug("👉 Fetching: \(job.url.absoluteString, privacy: .public)")
		#endif

		let group = job.group
		group.signpost.event(format: "Fetch %@", job.url.absoluteString)

		session.download(with: job.request) { response in
			defer {
				group.dispatchGroup.leave()
				self.jobQueue?.complete(job: job)
			}

			group.signpost.event(format: "Fetch completed: %@", job.url.absoluteString)

			// If cancelled, bail here so we don’t bother processing it further.
			if let error = response.error,
				 case HTTPError.cancelled = error {
				return
			}

			let httpResponse = response.response
			let status = httpResponse?.status ?? .invalid
			let headers = httpResponse?.headerFields ?? HTTPFields()
			let rawContentType = headers[.contentType] ?? "application/octet-stream"
			let contentType = String(rawContentType[..<(rawContentType.firstIndex(of: ";") ?? rawContentType.endIndex)])

			#if DEBUG
			let prefixes: [HTTPResponse.Status: String] = [
				.ok:          "🆗",
				.notModified: "👍",
				.notFound:    "🤷‍♀️"
			]
			let logBits = [
				prefixes[status] ?? "❌",
				job.request.httpMethod ?? "?",
				job.url.absoluteString,
				"→",
				"\(status.code)",
				contentType,
				response.error?.localizedDescription ?? ""
			]
			self.logger.debug("\(logBits.joined(separator: " "), privacy: .public)")
			#endif

			group.signpost.event(format: "Process: %@", job.url.absoluteString)

			// If this was a positive response, move the file to its destination. Otherwise we don’t want
			// the file.
			if let downloadURL = response.data {
				do {
					switch status {
					case .ok:
						if (try? job.partialURL.checkResourceIsReachable()) ?? false {
							try FileManager.default.removeItem(at: job.partialURL)
						}
						try FileManager.default.moveItem(at: downloadURL, to: job.partialURL)

						// Set etag if we got one.
						if let etag = headers[.eTag] {
							try job.partialURL.setExtendedAttribute(etag, forKey: URL.etagXattr)
						}

						// Set last modified date if we have it.
						if let date = DateFormatter.rfc822.date(from: headers[.lastModified] ?? "") {
							var values = URLResourceValues()
							values.contentModificationDate = date
							var url = job.partialURL
							try url.setResourceValues(values)
						}

					default:
						try FileManager.default.removeItem(at: downloadURL)
					}
				} catch {
					self.logger.warning("Failed to move job download to destination: \(String(describing: error), privacy: .public)")
					self.giveUp(group: group,
											error: RefreshError.generalError(sourceUUID: group.sourceUUID,
																											 url: job.url,
																											 error: error))
					return
				}
			}

			if let error = response.error {
				// Don’t bother continuing to try anything with this repo, it’ll probably just keep failing.
				if let error = error as? HTTPError {
					self.giveUp(group: group,
											error: RefreshError.httpError(sourceUUID: group.sourceUUID,
																										url: job.url,
																										httpError: error))
				} else {
					self.giveUp(group: group,
											error: RefreshError.generalError(sourceUUID: group.sourceUUID,
																											 url: job.url,
																											 error: error))
				}
				return
			}

			switch status {
			case .ok:
				// Ok! Let’s do what we need to do next for this type.
				let validContentTypes = job.sourceFile.kind.contentTypes
				if !validContentTypes.contains(contentType) {
					self.giveUp(group: group,
											error: RefreshError.invalidContentType(sourceUUID: group.sourceUUID,
																														 url: job.url,
																														 contentType: contentType))
					self.logger.warning("Invalid content type \(contentType, privacy: .public); not in \(validContentTypes, privacy: .public)")
					break
				}

				self.sourceStates[group.sourceUUID]?.progress.incrementCompletedUnitCount(by: job.sourceFile.progressWeight)

				switch job.sourceFile {
				case .inRelease, .releaseGpg:
					if self.validateRelease(group: group) {
						// Not modified. Nothing to be done.
						self.cleanUp(group: group)
					} else {
						// Start fetching Packages and supplementary files.
						self.continueJob(group: group, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))
					}

				case .release:
					// Start fetching Release.gpg.
					self.continueJob(group: group, withSourceFile: .releaseGpg)

				case .paymentEndpoint, .featured:
					// Nothing needs to be done.
					break

				case .packages(_):
					// Decompress
					self.decompressJobQueue.enqueue(job: job)
				}
				return

			case .notModified:
				// Not modified. Nothing to be done.
				self.cleanUp(group: group)
				return

			default:
				// Unexpected status code. Fall through.
				break
			}

			switch job.sourceFile {
			case .inRelease:
				// Try split Release + Release.gpg.
				self.currentRefreshJobs[group.sourceUUID]?.remove(job)
				self.continueJob(group: group, withSourceFile: .release)

			case .release, .releaseGpg:
				// Continue without the signature.
				self.currentRefreshJobs[group.sourceUUID]?.remove(job)
				self.continueJob(group: group, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))

			case .paymentEndpoint, .featured:
				// Continue assuming repo has no payment endpoint/featured list.
				self.currentRefreshJobs[group.sourceUUID]?.remove(job)

			case .packages(let kind):
				// Try next file kind. If we’ve reached the end, the repo is unusable.
				if let index = Self.packagesTypePriority.firstIndex(of: kind)?.advanced(by: 1),
					 index < Self.packagesTypePriority.endIndex {
					self.continueJob(group: group, withSourceFile: .packages(kind: Self.packagesTypePriority[index]))
				} else {
					self.cleanUp(group: group)
				}
			}
		}
	}

	private func validateRelease(group: JobGroup) -> Bool {
		// False means modified (or unknown state), true means unmodified.
		guard let source = SourceManager.shared.source(forUUID: group.sourceUUID),
					let jobs = currentRefreshJobs[group.sourceUUID] else {
			return false
		}

		let releaseFile = jobs.first(where: { job in
			switch job.sourceFile {
			case .release, .inRelease:
				return (try? job.partialURL.checkResourceIsReachable()) == true &&
					(try? job.destinationURL.checkResourceIsReachable()) == true

			default:
				return false
			}
		})
		guard let releaseFile = releaseFile else {
			return false
		}

		// Compare old and new Release file to determine if a Packages update is necessary.
		// Return true if both match.
		let newRelease = TagFile(url: releaseFile.partialURL)
		let keys = ["SHA512", "SHA256", "SHA1", "MD5Sum", "Date"]
		for key in keys {
			let old = source[key]
			let new = newRelease[key]
			if old == nil && new == nil {
				continue
			}
			return old != new
		}
		return false
	}

	private func decompress(job: Job) {
		let group = job.group

		if !job.sourceFile.kind.isCompressed {
			// Nothing to do, file is probably not compressed or shouldn’t be decompressed now.
			finalize(group: group)
			return
		}

		Task.detached(priority: priority.taskPriority) {
			do {
				let newSourceFile: SourceFile
				switch job.sourceFile {
				case .packages(_):
					newSourceFile = .packages(kind: .text)
				default:
					newSourceFile = job.sourceFile
				}

				let uncompressedURL = job.partialURL/".."/(group.sourceUUID + newSourceFile.name)

				group.signpost.event(format: "Decompress: %@", job.partialURL.lastPathComponent)

				#if DEBUG
				self.logger.debug("🗂 Decompressing: \(job.partialURL.lastPathComponent, privacy: .public)")
				let start = Date()
				#endif

				try await Decompressor.decompress(url: job.partialURL,
																					destinationURL: uncompressedURL,
																					format: job.sourceFile.kind.decompressorFormat)

				#if DEBUG
				let delta = Date().timeIntervalSince(start) * 1000
				self.logger.debug("📄 Decompressed in \(delta, format: .fixed(precision: 3), privacy: .public)ms: \(job.partialURL.lastPathComponent, privacy: .public)")
				#endif

				group.signpost.event(format: "Decompress done: %@", job.partialURL.lastPathComponent)

				self.workQueue.async {
					// If that worked, we do a quick switcharoo to make the job now “uncompressed”
					self.currentRefreshJobs[group.sourceUUID]?.remove(job)

					let newJob = Job(group: job.group,
													 request: job.request,
													 sourceFile: newSourceFile)
					self.currentRefreshJobs[group.sourceUUID]?.insert(newJob)

					self.decompressJobQueue.complete(job: job)
					self.finalize(group: group)
				}
			} catch {
				self.logger.warning("Error decompressing: \(String(describing: error), privacy: .public)")
				self.workQueue.async {
					self.giveUp(group: group,
											error: RefreshError.generalError(sourceUUID: group.sourceUUID,
																											 url: job.url,
																											 error: error))
				}
			}
		}
	}

	private func giveUp(group: JobGroup, error: RefreshError) {
		logger.warning("Refresh failed for \(group.sourceUUID, privacy: .public): \(String(describing: error), privacy: .public)")
		sourceStates[group.sourceUUID]?.addError(error)
		cleanUp(group: group)
	}

	private func cleanUp(group: JobGroup) {
		guard let jobs = currentRefreshJobs[group.sourceUUID] else {
			// Already cleaned up, nothing to do.
			return
		}

		group.signpost.event(format: "Cleanup: %@", group.sourceUUID)

		for job in jobs {
			do {
				if (try? job.partialURL.checkResourceIsReachable()) ?? false {
					try FileManager.default.removeItem(at: job.partialURL)
				}
			} catch {
				logger.warning("Error cleaning up for \(group.sourceUUID, privacy: .public): \(String(describing: error), privacy: .public)")
				sourceStates[group.sourceUUID]?.addError(RefreshError.generalError(sourceUUID: group.sourceUUID,
																																					 url: job.url,
																																					 error: error))
			}
		}

		currentRefreshJobs.removeValue(forKey: group.sourceUUID)

		if let sourceState = sourceStates[group.sourceUUID] {
			sourceState.progress.incrementCompletedUnitCount(by: sourceState.progress.totalUnitCount - sourceState.progress.completedUnitCount)
		}

		group.signpost.end()
		dispatchGroup.leave()

		#if DEBUG
		logger.debug("☑️ Done: \(group.sourceUUID, privacy: .public)")
		#endif
	}

	private func finalize(group: JobGroup) {
		group.dispatchGroup.notify(queue: self.workQueue) {
			for job in self.currentRefreshJobs[group.sourceUUID] ?? [] {
				do {
					if (try? job.destinationURL.checkResourceIsReachable()) ?? false {
						try FileManager.default.removeItem(at: job.destinationURL)
					}
					if (try? job.partialURL.checkResourceIsReachable()) ?? false,
						 !job.sourceFile.kind.isCompressed {
						try FileManager.default.moveItem(at: job.partialURL, to: job.destinationURL)
					}
				} catch {
					self.logger.warning("Error finalizing for \(group.sourceUUID, privacy: .public): \(String(describing: error), privacy: .public)")
					self.sourceStates[group.sourceUUID]?.addError(RefreshError.generalError(sourceUUID: group.sourceUUID,
																																									url: job.url,
																																									error: error))
				}
			}

			self.cleanUp(group: group)
		}
	}

	private func finishRefresh() {
		if progress.isCancelled {
			return
		}

		#if DEBUG
		logger.debug("⏱️ Reloading Data")
		#endif

		SourceManager.shared.rebuildCache()
		if let innerProgress = self.innerProgress {
			innerProgress.incrementCompletedUnitCount(by: innerProgress.totalUnitCount - innerProgress.completedUnitCount)
		}

		#if DEBUG
		logger.debug("✨ Completed")
		#endif

		endRefresh()

		DispatchQueue.main.async {
			NotificationCenter.default.post(name: Self.refreshDidFinishNotification, object: nil)
		}
	}

	private func cancel() {
		#if DEBUG
		logger.debug("🛑 Cancelled")
		#endif

		for job in self.currentRefreshJobs.values.compactMap(\.first) {
			cleanUp(group: job.group)
		}

		endRefresh()
	}

	private func endRefresh() {
		controlQueue = nil
		workQueue = nil
		jobQueue = nil
		decompressJobQueue = nil
		operationQueue = nil
		session?.invalidateAndCancel()
		session = nil
		currentRefreshJobs.removeAll()
		completeBackgroundRefresh()
		wakeLock.unlock()
		signpost.end()
	}

}

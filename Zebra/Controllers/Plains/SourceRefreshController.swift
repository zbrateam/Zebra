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

class SourceRefreshController: NSObject {

	struct Job: Identifiable, Hashable, Equatable {
		let signpost: Signpost
		let task: URLSessionTask
		let sourceUUID: String
		let sourceFile: SourceFile

		var id: Int { task.taskIdentifier }
		var url: URL { task.originalRequest!.url! }

		var filename: String { sourceUUID + sourceFile.name }
		var destinationURL: URL { listsURL/filename }
		var partialURL: URL { partialListsURL/filename }

		func hash(into hasher: inout Hasher) {
			hasher.combine(task.taskIdentifier)
			hasher.combine(filename.hashValue)
		}

		static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.id == rhs.id
		}
	}

	struct SourceState {
		let sourceUUID: String
		let progress: Progress
		var errors = [Error]()
	}

	enum RefreshError: Error {
		case errorResponse(sourceUUID: String, url: URL, statusCode: Int)
		case invalidContentType(sourceUUID: String, url: URL, contentType: String)
		case generalError(sourceUUID: String, url: URL, error: Error)
	}

	private static let subsystem = "com.getzbra.zebra.source-refresh"

	private static let legacySourceHosts = ["repo.dynastic.co", "apt.bingner.com"]
	private static let parallelJobsCount = 16

	private static let listsURL = PlainsConfig.shared.fileURL(forKey: "Dir::State::lists")!
	private static let partialListsURL = PlainsConfig.shared.fileURL(forKey: "Dir::State::lists")!/"partial"

	private static let packagesTypePriority: [SourceFileKind] = [.zstd, .xz, .lzma, .bzip2, .gzip]

	static let refreshProgressDidChangeNotification = Notification.Name(rawValue: "SourceRefreshProgressDidChangeNotification")

	static let shared = SourceRefreshController()

	private(set) var progress = Progress(totalUnitCount: 1)
	private(set) var sourceStates = [String: SourceState]()

	private let queue = DispatchQueue(label: "com.getzbra.zebra.source-refresh-queue", qos: .utility)
	private let decompressQueue = DispatchQueue(label: "com.getzbra.zebra.source-decompress-queue", qos: .utility)
	private let wakeLock = WakeLock(label: "com.getzbra.zebra.source-refresh-wake-lock")

	private lazy var operationQueue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = Self.parallelJobsCount
		operationQueue.underlyingQueue = self.queue
		return operationQueue
	}()

	private var session: URLSession?
	private var pendingJobs = [Job]()
	private var runningJobs = [Job]()
	private var currentRefreshJobs = [String: Set<Job>]()
	internal var backgroundTask: BGTask?

	internal let logger = Logger(subsystem: subsystem, category: "SourceRefreshOperation")
	private var signpost: Signpost?

	var isRefreshing: Bool { !progress.isFinished && !progress.isCancelled }
	var refreshErrors: [Error] { sourceStates.values.reduce([], { $0 + $1.errors }) }

	private override init() {
		super.init()

		registerNotifications()
		registerBackgroundTask()
	}

	func refresh() {
		queue.async {
			Preferences.lastSourceUpdate = Date()
			self.scheduleNextRefresh()

			if self.isRefreshing {
				self.progress.cancel()
			}

			// Give the cancel() a run loop tick for notifications to be dealt with before we reset state.
			self.queue.async {
				self.signpost = Signpost(subsystem: Self.subsystem, name: "SourceRefreshOperation", format: "Refresh")
				self.signpost!.begin()

				self.sourceStates.removeAll()
				self.pendingJobs.removeAll()
				self.runningJobs.removeAll()
				self.currentRefreshJobs.removeAll()

				let configuration = URLSession.download.configuration.copy() as! URLSessionConfiguration
				configuration.timeoutIntervalForRequest = Preferences.sourceRefreshTimeout
				self.session = URLSession(configuration: configuration,
																	delegate: self,
																	delegateQueue: self.operationQueue)

				self.wakeLock.lock()

				// TODO: Can we avoid needing to override granularity?
				self.progress = Progress(totalUnitCount: SourceManager.shared.sources.count + 1, granularity: .ulpOfOne)
				self.progress.addFractionCompletedNotification(onQueue: self.operationQueue) { completedUnitCount, totalUnitCount, _ in
					NotificationCenter.default.post(name: Self.refreshProgressDidChangeNotification, object: nil)
					if completedUnitCount == totalUnitCount - 1 && self.isRefreshing {
						self.finishRefresh()
					}
				}
				self.progress.addCancellationNotification(onQueue: self.operationQueue) {
					self.session?.invalidateAndCancel()
					self.session = nil
					self.wakeLock.unlock()
				}

				// Start the state machine for each source with InRelease.
				for source in SourceManager.shared.sources {
					let sourceFile = SourceFile.inRelease
					let downloadURL = source.baseURI/sourceFile.name
					let destinationURL = Self.partialListsURL/(source.uuid + sourceFile.name)
					let task = self.task(for: downloadURL, destinationURL: destinationURL)
					let signpost = Signpost(subsystem: Self.subsystem, name: "SourceRefreshJob", format: "%@", source.uuid)
					signpost.begin()

					let job = Job(signpost: signpost, task: task, sourceUUID: source.uuid, sourceFile: sourceFile)
					self.currentRefreshJobs[source.uuid] = [job]

					let sourceState = SourceState(sourceUUID: source.uuid,
																				progress: Progress(totalUnitCount: 1000, parent: self.progress, pendingUnitCount: 1))
					self.sourceStates[source.uuid] = sourceState
					self.continueJob(job, withSourceFile: .inRelease)
				}
			}
		}
	}

	// MARK: - Job Lifecycle

	private func processQueue() {
		queue.async {
			while self.runningJobs.count < Self.parallelJobsCount,
						let job = self.pendingJobs.popLast() {
				self.fetch(job: job)
			}
		}
	}

	private func fetch(job: Job) {
		#if DEBUG
		logger.debug("Fetching: \(job.url)")
		#endif

		job.signpost.event(format: "Fetch %@", String(describing: job.url))
		job.task.resume()
		runningJobs.append(job)
	}

	private func handleResponse(job: Job, response: HTTPURLResponse?, error: Error?) {
		let request = job.task.currentRequest ?? job.task.originalRequest!
		let statusCode = response?.statusCode ?? 0
		let rawContentType = response?.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
		let contentType = String(rawContentType[..<(rawContentType.firstIndex(of: ";") ?? rawContentType.endIndex)])

		#if DEBUG
		let prefixes = [
			200: "🆗",
			304: "👍",
			404: "🤷‍♀️"
		]
		logger.debug("\(prefixes[statusCode] ?? "❌") \(request.httpMethod ?? "?") \(response?.url ?? job.url) → \(statusCode) \(contentType) \(error == nil ? "" : String(describing: error!))")
		#endif

		job.signpost.event(format: "Process: %@", String(describing: job.url))

		if let error = error {
			// Don’t bother continuing to try anything with this repo, it’ll probably just keep failing.
			giveUp(job: job,
						 error: RefreshError.generalError(sourceUUID: job.sourceUUID,
																							url: job.url,
																							error: error))
			return
		}

		switch statusCode {
		case 200:
			// Ok! Let’s do what we need to do next for this type.
			let validContentTypes = job.sourceFile.kind.contentTypes
			if !validContentTypes.contains(contentType) {
				giveUp(job: job,
							 error: RefreshError.invalidContentType(sourceUUID: job.sourceUUID,
																											url: job.url,
																											contentType: contentType))
				logger.warning("Invalid content type \(contentType); not in \(validContentTypes)")
				break
			}

			sourceStates[job.sourceUUID]?.progress.incrementCompletedUnitCount(by: job.sourceFile.progressWeight)

			switch job.sourceFile {
			case .inRelease, .releaseGpg:
				// Start fetching Packages.
				continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))

			case .release:
				// Start fetching Release.gpg.
				continueJob(job, withSourceFile: .releaseGpg)

			case .packages(_):
				// Decompress
				decompress(job: job)
			}
			return

		case 304:
			// Not modified. Nothing to be done.
			cleanUp(sourceUUID: job.sourceUUID)
			return

		default:
			// Unexpected status code. Fall through.
			break
		}

		switch job.sourceFile {
		case .inRelease:
			// Try split Release + Release.gpg.
			currentRefreshJobs[job.sourceUUID]?.remove(job)
			continueJob(job, withSourceFile: .release)

		case .release, .releaseGpg:
			// Continue without the signature.
			currentRefreshJobs[job.sourceUUID]?.remove(job)
			continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))

		case .packages(let kind):
			// Try next file kind. If we’ve reached the end, the repo is unusable.
			if let index = Self.packagesTypePriority.firstIndex(of: kind)?.advanced(by: 1),
				 index < Self.packagesTypePriority.endIndex {
				continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority[index]))
			} else {
				giveUp(job: job,
							 error: RefreshError.errorResponse(sourceUUID: job.sourceUUID,
																								 url: job.url,
																								 statusCode: statusCode))
			}
		}
	}

	private func continueJob(_ job: Job, withSourceFile sourceFile: SourceFile) {
		queue.async {
			guard let source = SourceManager.shared.source(forUUID: job.sourceUUID) else {
				return
			}

			let baseURL: URL
			switch sourceFile {
			case .inRelease, .release, .releaseGpg:
				baseURL = source.baseURI

			case .packages(_):
				// TODO: Support multiple components/archs
				if let component = source.components.first {
					let architecture = source.architectures.first ?? Device.primaryDebianArchitecture
					baseURL = source.baseURI/component/"binary-\(architecture)"
				} else {
					baseURL = source.baseURI
				}
			}

			let downloadURL = baseURL/sourceFile.name
			let destinationURL = Self.partialListsURL/(job.sourceUUID + sourceFile.name)

			let task = self.task(for: downloadURL, destinationURL: destinationURL)
			let newJob = Job(signpost: job.signpost,
											 task: task,
											 sourceUUID: job.sourceUUID,
											 sourceFile: sourceFile)

			self.currentRefreshJobs[newJob.sourceUUID]?.insert(newJob)
			self.pendingJobs.append(newJob)
			job.signpost.event(format: "Queued: %@", String(describing: downloadURL))
			self.processQueue()
		}
	}

	private func task(for downloadURL: URL, destinationURL: URL) -> URLSessionDownloadTask {
		var request = URLRequest(url: downloadURL,
														 cachePolicy: .useProtocolCachePolicy,
														 timeoutInterval: Preferences.sourceRefreshTimeout)

		// Handle legacy headers for specific repos that require them.
		if Self.legacySourceHosts.contains(downloadURL.host ?? "") {
			for (key, value) in URLController.legacyAPTHeaders {
				request.setValue(value, forHTTPHeaderField: key)
			}
		}

		// If we already have an old version of this file, set If-Modified-Since so the server can
		// give us a 304 Not Modified response.
		if let values = try? destinationURL.resourceValues(forKeys: [.contentModificationDateKey]),
			 let date = values.contentModificationDate {
			request.setValue(DateFormatter.rfc822.string(from: date), forHTTPHeaderField: "If-Modified-Since")
		}

		return session!.downloadTask(with: request)
	}

	private func decompress(job: Job) {
		if !job.sourceFile.kind.isCompressed {
			// Nothing to do, file is probably not compressed or shouldn’t be decompressed now.
			self.finalize(sourceUUID: job.sourceUUID)
			return
		}

		decompressQueue.async {
			Task {
				do {
					let newSourceFile: SourceFile
					switch job.sourceFile {
					case .packages(_):
						newSourceFile = .packages(kind: .text)
					default:
						newSourceFile = job.sourceFile
					}

					let uncompressedURL = job.partialURL/".."/(job.sourceUUID + newSourceFile.name)

					job.signpost.event(format: "Decompress: %@", job.partialURL.lastPathComponent)

					#if DEBUG
					self.logger.debug("Decompressing: \(job.partialURL.lastPathComponent)")
					let start = Date()
					#endif

					try await Decompressor.decompress(url: job.partialURL,
																						destinationURL: uncompressedURL,
																						format: job.sourceFile.kind.decompressorFormat)

					#if DEBUG
					let delta = Date().timeIntervalSince(start) * 1000
					self.logger.debug("Decompressed in \(delta, format: .fixed(precision: 3))ms: \(job.partialURL.lastPathComponent)")
					job.signpost.event(format: "Decompress done: %@", job.partialURL.lastPathComponent)
					#endif

					self.queue.async {
						// If that worked, we do a quick switcharoo to make the job now “uncompressed”
						self.currentRefreshJobs[job.sourceUUID]?.remove(job)

						let newJob = Job(signpost: job.signpost,
														 task: job.task,
														 sourceUUID: job.sourceUUID,
														 sourceFile: newSourceFile)
						self.currentRefreshJobs[job.sourceUUID]?.insert(newJob)
						self.finalize(sourceUUID: job.sourceUUID)
					}
				} catch {
					self.logger.warning("Error decompressing: \(String(describing: error))")
					self.sourceStates[job.sourceUUID]?.errors.append(error)
				}
			}
		}
	}

	private func giveUp(job: Job, error: RefreshError) {
		queue.async {
			self.logger.warning("Refresh failed for \(job.sourceUUID): \(String(describing: error))")
			self.sourceStates[job.sourceUUID]?.errors.append(error)
			self.cleanUp(sourceUUID: job.sourceUUID)
		}
	}

	private func cleanUp(sourceUUID: String) {
		queue.async {
			let signpost = self.currentRefreshJobs[sourceUUID]?.first?.signpost
			signpost?.event(format: "Cleanup: %@", sourceUUID)

			for job in self.currentRefreshJobs[sourceUUID] ?? [] {
				do {
					if (try? job.partialURL.checkResourceIsReachable()) ?? false {
						try FileManager.default.removeItem(at: job.partialURL)
					}
				} catch {
					self.logger.warning("Error cleaning up for \(sourceUUID): \(String(describing: error))")
					self.sourceStates[sourceUUID]?.errors.append(error)
				}
			}

			self.currentRefreshJobs.removeValue(forKey: sourceUUID)

			if let sourceState = self.sourceStates[sourceUUID] {
				sourceState.progress.incrementCompletedUnitCount(by: sourceState.progress.totalUnitCount - sourceState.progress.completedUnitCount)
			}

			signpost?.end()

			#if DEBUG
			self.logger.debug("Done: \(sourceUUID)")
			#endif
		}
	}

	private func finalize(sourceUUID: String) {
		queue.async {
			for job in self.currentRefreshJobs[sourceUUID] ?? [] {
				do {
					if (try? job.destinationURL.checkResourceIsReachable()) ?? false {
						try FileManager.default.removeItem(at: job.destinationURL)
					}
					if (try? job.partialURL.checkResourceIsReachable()) ?? false,
						 !job.sourceFile.kind.isCompressed {
						try FileManager.default.moveItem(at: job.partialURL, to: job.destinationURL)
					}
				} catch {
					self.logger.warning("Error finalizing for \(sourceUUID): \(String(describing: error))")
					self.sourceStates[sourceUUID]?.errors.append(error)
				}
			}

			self.cleanUp(sourceUUID: sourceUUID)
		}
	}

	private func finishRefresh() {
		queue.async {
			#if DEBUG
			self.logger.debug("Rebuilding APT cache…")
			#endif

			SourceManager.shared.rebuildCache()
			self.progress.incrementCompletedUnitCount(by: self.progress.totalUnitCount - self.progress.completedUnitCount)

			#if DEBUG
			self.logger.debug("Completed")
			#endif

			self.wakeLock.unlock()
			self.completeBackgroundRefresh()
			self.signpost?.end()
		}
	}

}

extension SourceRefreshController: URLSessionTaskDelegate, URLSessionDownloadDelegate {

	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let job = runningJobs.first(where: { $0.id == downloadTask.taskIdentifier }),
					let response = downloadTask.response as? HTTPURLResponse else {
			logger.warning("Job for download task not found?")
			return
		}

		do {
			// If this was a positive response, move the file to its destination. Otherwise we don’t want
			// the file.
			if response.statusCode == 200 {
				if (try? job.partialURL.checkResourceIsReachable()) ?? false {
					try FileManager.default.removeItem(at: job.partialURL)
				}
				try FileManager.default.moveItem(at: location, to: job.partialURL)
			} else {
				try FileManager.default.removeItem(at: location)
			}
		} catch {
			logger.warning("Failed to move job download to destination: \(String(describing: error))")
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let index = runningJobs.firstIndex(where: { $0.id == task.taskIdentifier }) else {
			logger.warning("Job for task not found?")
			return
		}

		// This is the last delegate method fired, so we can consider the job done now.
		let job = runningJobs[index]
		job.signpost.event(format: "Fetch completed: %@", String(describing: job.url))
		runningJobs.remove(at: index)
		handleResponse(job: job, response: task.response as? HTTPURLResponse, error: error)

		// Process queue in case any jobs are pending.
		processQueue()
	}

}

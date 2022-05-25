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

class SourceRefreshController: NSObject, ProgressReporting {

	struct Job: Identifiable, Hashable, Equatable {
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

	private static let listsURL = Device.dataURL/"lists"
	private static let partialListsURL = Device.dataURL/"lists/partial"

	private static let automaticSourceRefreshInterval: TimeInterval = 5 * 60

	private static let packagesTypePriority: [SourceFileKind] = [.zstd, .xz, .lzma, .bzip2, .gzip]
	private static let parallelJobsCount = 16

	static let refreshProgressDidChangeNotification = Notification.Name(rawValue: "SourceRefreshProgressDidChangeNotification")

	static let shared = SourceRefreshController()

	let progress = Progress()
	private(set) var refreshErrors = [PLError]()

	private let queue = DispatchQueue(label: "xyz.willy.Zebra.source-refresh-queue", qos: .utility)
	private let decompressQueue = DispatchQueue(label: "xyz.willy.Zebra.source-decompress-queue", qos: .utility)
	private var session: URLSession!
	private var pendingJobs = [Job]()
	private var runningJobs = [Job]()
	private var currentRefreshJobs = [String: Set<Job>]()
	private var progressObserver: NSKeyValueObservation!

	private override init() {
		super.init()

		NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

		// TODO: Set user configured timeout
		let operationQueue = OperationQueue()
		operationQueue.underlyingQueue = queue
		session = URLSession(configuration: URLSession.download.configuration,
												 delegate: self,
												 delegateQueue: operationQueue)

		progressObserver = progress.observe(\.fractionCompleted) { progress, _ in
			NotificationCenter.default.post(name: Self.refreshProgressDidChangeNotification, object: nil)
			print("XXX progress: \(progress.fractionCompleted)")
		}
	}

	func refresh(isUserRequested: Bool = true) {
		queue.async {
			if !isUserRequested && ZBSettings.lastSourceUpdate().distance(to: Date()) < Self.automaticSourceRefreshInterval {
				// Don’t refresh, we already refreshed very recently.
				return
			}
			ZBSettings.updateLastSourceUpdate()

			self.progress.totalUnitCount = Int64(PLSourceManager.shared.sources.count) * 1000
			self.progress.completedUnitCount = 0

			// Start the state machine for each source with InRelease.
			for source in PLSourceManager.shared.sources {
				let sourceFile = SourceFile.inRelease
				let downloadURL = source.baseURI/sourceFile.name
				let destinationURL = Self.partialListsURL/(source.uuid + sourceFile.name)
				let task = self.task(for: downloadURL, destinationURL: destinationURL)
				let job = Job(task: task,
											sourceUUID: source.uuid,
											sourceFile: sourceFile)
				self.currentRefreshJobs[source.uuid] = [job]
				self.continueJob(job, withSourceFile: .inRelease)
			}
		}
	}

	// MARK: - App Lifecycle

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
		os_log("[SourceRefreshController] Fetching: %@", String(describing: job.url))
		#endif

		job.task.resume()
		runningJobs.append(job)
	}

	private func handleResponse(job: Job, response: HTTPURLResponse) {
		guard let request = job.task.currentRequest ?? job.task.originalRequest else {
			os_log("[SourceRefreshController] Invalid request?")
			return
		}
		let rawContentType = response.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
		let contentType = String(rawContentType[..<(rawContentType.firstIndex(of: ";") ?? rawContentType.endIndex)])

		#if DEBUG
		let prefixes = [
			200: "🆗",
			304: "👍",
			404: "🤷‍♀️"
		]
		os_log("[SourceRefreshController] %@ %@ %@ → %i (%@)",
					 prefixes[response.statusCode] ?? "❌",
					 request.httpMethod ?? "?",
					 String(describing: response.url ?? job.url),
					 response.statusCode,
					 contentType)
		#endif

		switch response.statusCode {
		case 200:
			// Ok! Let’s do what we need to do next for this type.
			let validContentTypes = job.sourceFile.kind.contentTypes
			if !validContentTypes.contains(contentType) {
				// TODO: Push this to the UI
				os_log("[SourceRefreshController] Invalid content type: %@ not in [%@]", contentType, validContentTypes.joined(separator: ", "))
				break
			}

			switch job.sourceFile {
			case .inRelease, .releaseGpg:
				// Start fetching Packages.
				continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))

			case .release:
				// Start fetching Release.gpg.
				continueJob(job, withSourceFile: .releaseGpg)

			case .packages(_):
				// Decompress
				self.decompress(job: job)
			}
			return

		case 304:
			// Not modified. Nothing to be done.
			let totalUnits = self.currentRefreshJobs[job.sourceUUID]?
				.map(\.sourceFile.progressWeight)
				.reduce(0, +) ?? 0
			self.progress.completedUnitCount += -totalUnits + 1000
			self.cleanUp(sourceUUID: job.sourceUUID)
			return

		default:
			// Unexpected status code. Fall through.
			break
		}

		switch job.sourceFile {
		case .inRelease:
			// Try split Release + Release.gpg.
			self.progress.completedUnitCount -= job.sourceFile.progressWeight
			self.currentRefreshJobs[job.sourceUUID]?.remove(job)
			continueJob(job, withSourceFile: .release)

		case .release, .releaseGpg:
			// Continue without the signature.
			self.currentRefreshJobs[job.sourceUUID]?.remove(job)
			continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority.first!))

		case .packages(let kind):
			// Try next file kind. If we’ve reached the end, the repo is unusable.
			if let index = Self.packagesTypePriority.firstIndex(of: kind)?.advanced(by: 1),
				 index < Self.packagesTypePriority.endIndex {
				self.progress.completedUnitCount -= job.sourceFile.progressWeight
				continueJob(job, withSourceFile: .packages(kind: Self.packagesTypePriority[index]))
			} else {
				// TODO: Push this to the UI
				os_log("[SourceRefreshController] Repo unusable: %@", job.sourceUUID)
				self.cleanUp(sourceUUID: job.sourceUUID)
			}
		}
	}

	private func continueJob(_ job: Job, withSourceFile sourceFile: SourceFile) {
		queue.async {
			let source = PLSourceManager.shared.source(forUUID: job.sourceUUID)
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
			let destinationURL = Self.listsURL/(job.sourceUUID + sourceFile.name)

			// TODO: Figure out how our progress unit counting works
			self.progress.becomeCurrent(withPendingUnitCount: job.sourceFile.progressWeight)
			let task = self.task(for: downloadURL, destinationURL: destinationURL)
			self.progress.resignCurrent()

			let newJob = Job(task: task,
											 sourceUUID: job.sourceUUID,
											 sourceFile: sourceFile)
			self.currentRefreshJobs[newJob.sourceUUID]?.insert(newJob)
			self.pendingJobs.append(newJob)
			self.processQueue()
		}
	}

	private func task(for downloadURL: URL, destinationURL: URL) -> URLSessionDownloadTask {
		var request = URLRequest(url: downloadURL,
														 cachePolicy: .useProtocolCachePolicy,
														 timeoutInterval: ZBSettings.sourceRefreshTimeout())

		// Handle legacy headers for specific repos that require them.
		if downloadURL.host == "repo.dynastic.co" {
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

		return session.downloadTask(with: request)
	}

	private func decompress(job: Job) {
		decompressQueue.async {
			Task {
				switch job.sourceFile.kind {
				case .gzip, .bzip2, .lzma, .xz, .zstd:
					do {
						let uncompressedURL = job.destinationURL.deletingPathExtension()
						try await Decompressor.decompress(url: job.partialURL,
																							destinationURL: uncompressedURL,
																							format: job.sourceFile.kind.decompressorFormat)

						self.queue.async {
							// If that worked, we do a quick switcharoo to make the job now “uncompressed”
							self.currentRefreshJobs[job.sourceUUID]?.remove(job)

							let newSourceFile: SourceFile
							switch job.sourceFile {
							case .packages(_):
								newSourceFile = .packages(kind: .text)
							default:
								newSourceFile = job.sourceFile
							}

							let newJob = Job(task: job.task,
															 sourceUUID: job.sourceUUID,
															 sourceFile: newSourceFile)
							self.currentRefreshJobs[job.sourceUUID]?.insert(newJob)
							self.finalize(sourceUUID: job.sourceUUID)
						}
					} catch {
						// TODO: Push this to the UI
						os_log("[SourceRefreshController] Error decompressing: %@", String(describing: error))
					}

				default:
					// Nothing to do, file is probably not compressed or shouldn’t be decompressed now.
					self.finalize(sourceUUID: job.sourceUUID)
					break
				}
			}
		}
	}

	private func cleanUp(sourceUUID: String) {
		queue.async {
			for job in self.currentRefreshJobs[sourceUUID] ?? [] {
				do {
					if (try? job.partialURL.checkResourceIsReachable()) ?? false {
						try FileManager.default.removeItem(at: job.partialURL)
					}
				} catch {
					// TODO: Push this to the UI
					os_log("[SourceRefreshController] Error cleaning up: %@", String(describing: error))
				}
			}

			self.currentRefreshJobs.removeValue(forKey: sourceUUID)

			#if DEBUG
			os_log("[SourceRefreshController] Done: %@", sourceUUID)
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
					try FileManager.default.moveItem(at: job.partialURL, to: job.destinationURL)
				} catch {
					// TODO: Push this to the UI
					os_log("[SourceRefreshController] Error finalizing: %@", String(describing: error))
				}
			}

			self.cleanUp(sourceUUID: sourceUUID)
		}
	}

}

extension SourceRefreshController: URLSessionTaskDelegate, URLSessionDownloadDelegate {

	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let job = runningJobs.first(where: { $0.id == downloadTask.taskIdentifier }),
					let response = downloadTask.response as? HTTPURLResponse else {
			os_log("[SourceRefreshController] Job for download task not found?")
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
			os_log("[SourceRefreshController] Failed to move job download to destination: %@", String(describing: error))
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let index = runningJobs.firstIndex(where: { $0.id == task.taskIdentifier }),
					let response = task.response as? HTTPURLResponse else {
			os_log("[SourceRefreshController] Job for task not found?")
			return
		}

		// This is the last delegate method fired, so we can consider the job done now.
		let job = runningJobs[index]
		runningJobs.remove(at: index)
		handleResponse(job: job, response: response)

		// Process queue in case any jobs are pending.
		processQueue()
	}

}

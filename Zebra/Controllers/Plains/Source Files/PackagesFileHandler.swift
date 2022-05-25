//
//  PackagesFileHandler.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

//class PackagesFileHandler: SourceFileHandlerProtocol {
//	func process(sourceFile: SourceFile, job: Job) async throws -> Job? {
//		return try await withCheckedThrowingContinuation { result in
//			Task {
//				switch job.sourceFile.kind {
//				case .gzip, .bzip2, .lzma, .xz, .zstd:
//					do {
//						let uncompressedURL = job.destinationURL.deletingPathExtension()
//						try await Decompressor.decompress(url: job.partialURL,
//																							destinationURL: uncompressedURL,
//																							format: job.sourceFile.kind.decompressorFormat)
//
//						self.queue.async {
//							// If that worked, we do a quick switcharoo to make the job now “uncompressed”
//							self.currentRefreshJobs[job.sourceUUID]?.remove(job)
//
//							let newSourceFile: SourceFile
//							switch job.sourceFile {
//							case .packages(_):
//								newSourceFile = .packages(kind: .text)
//							default:
//								newSourceFile = job.sourceFile
//							}
//
//							let newJob = Job(task: job.task,
//															 sourceUUID: job.sourceUUID,
//															 sourceFile: newSourceFile)
//							self.currentRefreshJobs[job.sourceUUID]?.insert(newJob)
//							self.finalize(sourceUUID: job.sourceUUID)
//						}
//					} catch {
//						// TODO: Push this to the UI
//						os_log("[SourceRefreshController] Error decompressing: %@", String(describing: error))
//					}
//
//				default:
//					// Nothing to do, file is probably not compressed or shouldn’t be decompressed now.
//					self.finalize(sourceUUID: job.sourceUUID)
//					break
//				}
//			}
//		}
//	}
//}

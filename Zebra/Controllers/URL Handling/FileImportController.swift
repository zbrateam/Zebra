//
//  FileImportController.swift
//  Zebra
//
//  Created by Adam Demasi on 10/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
	static let debArchive  = UTType(exportedAs: "org.debian.deb-archive",  conformingTo: .archive)
	static let sourcesList = UTType(exportedAs: "org.debian.sources-list", conformingTo: .plainText)
	static let sourcesFile = UTType(exportedAs: "org.debian.sources-file", conformingTo: .plainText)
}

class FileImportController {

	static let supportedTypes: [UTType] = [.debArchive, .sourcesList, .sourcesFile]

	class func isSupportedType(itemProvider: NSItemProvider) -> Bool {
		return supportedTypes.contains { type in itemProvider.hasRepresentationConforming(toTypeIdentifier: type.identifier) }
	}

	class func handleFile(itemProvider: NSItemProvider, filename: String?) async throws {
		if itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.debArchive.identifier) {
			try await handleDebFile(itemProvider: itemProvider, filename: filename)
		} else if itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.sourcesList.identifier)
								|| itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.sourcesFile.identifier) {
			try await handleSourcesFile(itemProvider: itemProvider)
		}
	}

	private class func handleDebFile(itemProvider: NSItemProvider, filename: String?) async throws {
		let url = try await withCheckedThrowingContinuation { (result: CheckedContinuation<URL, Error>) in
			itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.debArchive.identifier) { url, isInPlace, error in
				if let error = error {
					result.resume(throwing: error)
					return
				}
				let coordinator = NSFileCoordinator()
				var error2: NSError?
				coordinator.coordinate(readingItemAt: url!, options: [], error: &error2) { url in
					if isInPlace {
						result.resume(returning: url)
					} else {
						let newURL = FileManager.default.temporaryDirectory
							.appendingPathComponent(filename ?? "\(UUID().uuidString).deb")
						do {
							if (try? newURL.checkResourceIsReachable()) == true {
								try FileManager.default.removeItem(at: newURL)
							}
							try FileManager.default.moveItem(at: url, to: newURL)
							result.resume(returning: newURL)
						} catch {
							result.resume(throwing: error)
						}
					}
				}

				if let error2 = error2 {
					result.resume(throwing: error2)
				}
			}
		}

		await MainActor.run {
			let activity = NSUserActivity(activityType: PackageSceneDelegate.activityType)
			activity.userInfo = ["url": url.absoluteString]
			UIApplication.shared.activateScene(userActivity: activity,
																				 requestedBy: nil,
																				 asSingleton: false,
																				 withProminentPresentation: true)
		}
	}

	private class func handleSourcesFile(itemProvider: NSItemProvider) async throws {
		let data = try await withCheckedThrowingContinuation { (result: CheckedContinuation<Data, Error>) in
			let type = [UTType.sourcesList, UTType.sourcesFile].first(where: { type in itemProvider.hasRepresentationConforming(toTypeIdentifier: type.identifier) })!
			itemProvider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
				if let error = error {
					result.resume(throwing: error)
					return
				}
				// TODO
				print("got it \(String(describing: data))")
				result.resume(returning: data!)
			}
		}
	}

}

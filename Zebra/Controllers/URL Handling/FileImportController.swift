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
	static let debArchive  = UTType(importedAs: "org.debian.deb-archive", conformingTo: .archive)
	static let sourcesList = UTType(importedAs: "org.debian.sources-list", conformingTo: .plainText)
	static let sourcesFile = UTType(importedAs: "org.debian.sources-file", conformingTo: .plainText)
}

class FileImportController {

	static let supportedTypes: [UTType] = [.debArchive, .sourcesList, .sourcesFile]

	class func handleFile(itemProvider: NSItemProvider) async throws {
		if itemProvider.hasItemConformingToTypeIdentifier(UTType.debArchive.identifier) {
			let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.debArchive.identifier, options: nil)
			// TODO
			print("got it \(String(describing: item))")
		} else if itemProvider.hasItemConformingToTypeIdentifier(UTType.sourcesList.identifier) {
			let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.sourcesList.identifier, options: nil)
			// TODO
			print("got it \(String(describing: item))")
		} else if itemProvider.hasItemConformingToTypeIdentifier(UTType.sourcesFile.identifier) {
			let item = try await itemProvider.loadItem(forTypeIdentifier: UTType.sourcesFile.identifier, options: nil)
			// TODO
			print("got it \(String(describing: item))")
		}
	}

}

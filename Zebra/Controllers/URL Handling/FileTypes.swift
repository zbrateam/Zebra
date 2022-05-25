//
//  FileTypes.swift
//  Zebra
//
//  Created by Adam Demasi on 3/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
	// Package types
	static let debArchive  = UTType(exportedAs: "org.debian.deb-archive",  conformingTo: .archive)

	// Sources types
	static let sourcesList = UTType(exportedAs: "org.debian.sources-list", conformingTo: .plainText)
	static let sourcesFile = UTType(exportedAs: "org.debian.sources-file", conformingTo: .plainText)

	// Archive types
	static let lzma = UTType(importedAs: "org.tukaani.lzma-archive",  conformingTo: .archive)
	static let xz   = UTType(importedAs: "org.tukaani.xz-archive",    conformingTo: .archive)
	static let zstd = UTType(importedAs: "com.facebook.zstd-archive", conformingTo: .archive)
}

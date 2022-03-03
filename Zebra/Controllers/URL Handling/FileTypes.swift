//
//  FileTypes.swift
//  Zebra
//
//  Created by Adam Demasi on 3/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

let kUTTypeDebArchive  = "org.debian.deb-archive"
let kUTTypeSourcesList = "org.debian.sources-list"
let kUTTypeSourcesFile = "org.debian.sources-file"

@available(iOS 14, *)
extension UTType {
	static let debArchive  = UTType(exportedAs: kUTTypeDebArchive,  conformingTo: .archive)
	static let sourcesList = UTType(exportedAs: kUTTypeSourcesList, conformingTo: .plainText)
	static let sourcesFile = UTType(exportedAs: kUTTypeSourcesFile, conformingTo: .plainText)
}

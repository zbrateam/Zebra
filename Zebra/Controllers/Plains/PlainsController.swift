//
//  PlainsController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import os.log

class PlainsController {

	static let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
	static let dataURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
		.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)

	class func setUp() throws {
		let config = PLConfig.shared

		// Create directories
		for path in ["logs", "lists", "archives", "archives/partial"] {
			try FileManager.default.createDirectory(at: cacheURL.appendingPathComponent(path),
																							withIntermediateDirectories: true,
																							attributes: [:])
		}

		// Set directories
		config.set(string: cacheURL.appendingPathComponent("logs").path, forKey: "Dir::Log")
		config.set(string: cacheURL.appendingPathComponent("lists").path, forKey: "Dir::State::Lists")
		config.set(string: cacheURL.path, forKey: "Dir::Cache")
		config.set(string: cacheURL.appendingPathComponent("zebra.sources").path, forKey: "Plains::SourcesList")

		// Set slingshot path
		config.set(string: SlingshotController.superslingPath, forKey: "Plains::Slingshot")
		config.set(string: SlingshotController.superslingPath, forKey: "Dir::Bin::dpkg")

		// Allow unsigned repos only on iOS
		#if !targetEnvironment(macCatalyst)
		config.set(boolean: true, forKey: "Acquire::AllowInsecureRepositories")
		#endif

		// Configure http method
		config.set(string: URLController.aptUserAgent, forKey: "Acquire::http::User-Agent")

		// Configure finish fd
		var finishFds: [Int32] = [0, 0]
		if pipe(&finishFds) == 0 {
			config.set(integer: finishFds[0], forKey: "Plains::FinishFD::")
			config.set(integer: finishFds[1], forKey: "Plains::FinishFD::")
		} else {
			os_log("[Zebra] Unable to create file descriptors.")
		}

		// Reset the default compression type ordering
		let compressors: [(ext: String, program: String)] = [
			("zst", "zstd"),
			("xz", "xz"),
			("lzma", "lzma"),
			("lz4", "lz4"),
			("bz2", "bzip2"),
			("gz", "gzip")
		]
		for (ext, program) in compressors {
			config.set(string: program, forKey: "Acquire::CompressionTypes::\(ext)")
		}

		// Load the database
		PLPackageManager.shared.import()
	}

}

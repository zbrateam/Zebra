//
//  Decompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Compression
import os.log

internal protocol DecompressorProtocol: AnyObject {
	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws
}

class Decompressor {
	enum Format {
		case gzip, bzip2, lzma, xz, zstd

		internal var decompressorType: DecompressorProtocol.Type {
			switch self {
			case .gzip:
				return GzipDecompressor.self
			case .bzip2:
				return Bzip2Decompressor.self
			case .lzma, .xz:
				return AppleDecompressor.self
			case .zstd:
				return ZstdDecompressor.self
			}
		}

		internal var algorithm: Algorithm? {
			switch self {
			case .lzma, .xz:
				return .lzma
			case .gzip, .bzip2, .zstd:
				return nil
			}
		}
	}

	private static let subsystem = "com.getzbra.zebra.decompressor"

	class func decompress(url: URL, destinationURL: URL, format: Format) async throws {
		let signpost = Signpost(subsystem: Self.subsystem,
														name: "Decompress",
														format: "%@ (%@)", url.lastPathComponent, String(describing: format))
		signpost.begin()
		try await format.decompressorType.decompress(url: url, destinationURL: destinationURL, format: format)

		// Copy over the last modified date
		if let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
			 let date = values.contentModificationDate {
			var values = URLResourceValues()
			values.contentModificationDate = date
			var destinationURL = destinationURL
			try destinationURL.setResourceValues(values)
		}

		// Copy over ETag xattr
		if let value = try url.extendedAttribute(forKey: URL.etagXattr) {
			try destinationURL.setExtendedAttribute(value, forKey: URL.etagXattr)
		}

		try FileManager.default.removeItem(at: url)
		signpost.end()
	}
}

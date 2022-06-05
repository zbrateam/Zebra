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

	private static let signpostLog = OSLog(subsystem: "xyz.willy.zebra.decompressor", category: .pointsOfInterest)

	class func decompress(url: URL, destinationURL: URL, format: Format) async throws {
		let signpost = Signpost(log: signpostLog, name: "Decompress", format: "%@ (%@)", url.absoluteString, String(describing: format))
		signpost.begin()
		try await format.decompressorType.decompress(url: url, destinationURL: destinationURL, format: format)
		try FileManager.default.removeItem(at: url)
		signpost.end()
	}
}

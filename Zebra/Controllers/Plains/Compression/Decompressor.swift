//
//  Decompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Compression

internal protocol DecompressorProtocol: AnyObject {
	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws
}

class Decompressor {
	enum Format {
		case gzip, bzip2, lzma, xz, zstd

		internal var decompressorType: DecompressorProtocol.Type {
			switch self {
			case .gzip, .lzma, .xz:
				return AppleDecompressor.self
			case .bzip2:
				return Bzip2Decompressor.self
			case .zstd:
				return ZstdDecompressor.self
			}
		}

		internal var algorithm: Algorithm? {
			switch self {
			case .gzip, .bzip2:
				return .zlib
			case .lzma, .xz:
				return .lzma
			case .zstd:
				return nil
			}
		}
	}

	class func decompress(url: URL, destinationURL: URL, format: Format) async throws {
		try await format.decompressorType.decompress(url: url, destinationURL: destinationURL, format: format)
		try FileManager.default.removeItem(at: url)
	}
}

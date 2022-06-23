//
//  ZstdDecompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class ZstdDecompressor: DecompressorProtocol {
	struct ZstdError: Error, LocalizedError {
		private let errorString: String

		init(errno: errno_t) {
			errorString = String(utf8String: strerror(errno)) ?? "Unknown"
		}

		init?(error: size_t) {
			if ZSTD_isError(error) == 0 {
				return nil
			}
			if let cString = ZSTD_getErrorName(error),
				 let string = String(utf8String: cString) {
				errorString = string
			} else {
				errorString = "Zstd error \(error)"
			}
		}

		var localizedDescription: String { errorString }
	}

	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		guard let sourceHandle = fopen(url.path.cString, "rb") else {
			throw ZstdError(errno: errno)
		}
		defer { fclose(sourceHandle) }

		// Make an empty file at the destination.
		try Data().write(to: destinationURL)
		let destinationHandle = try FileHandle(forWritingTo: destinationURL)
		defer { try? destinationHandle.close() }

		let stream = ZSTD_createDStream()
		defer { ZSTD_freeDStream(stream) }
		var sourceRead = ZSTD_initDStream(stream)
		if let error = ZstdError(error: sourceRead) {
			throw error
		}

		let sourceBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: ZSTD_DStreamInSize())
		let destinationCapacity = ZSTD_DStreamOutSize()
		let destinationBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: destinationCapacity)

		while true {
			let sourceCount = fread(sourceBuffer, 1, sourceRead, sourceHandle)
			if sourceCount == 0 {
				break
			}

			let error = ferror(sourceHandle)
			if error != 0 {
				throw ZstdError(errno: error)
			}

			var inBuffer = ZSTD_inBuffer(src: sourceBuffer, size: sourceCount, pos: 0)
			var outBuffer = ZSTD_outBuffer(dst: destinationBuffer, size: destinationCapacity, pos: 0)

			while inBuffer.pos < inBuffer.size {
				sourceRead = ZSTD_decompressStream(stream, &outBuffer, &inBuffer)
				if let error = ZstdError(error: sourceRead) {
					throw error
				}

				let data = Data(bytes: outBuffer.dst, count: outBuffer.pos)
				try destinationHandle.write(contentsOf: data)
			}
		}

		try destinationHandle.close()
	}
}

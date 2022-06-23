//
//  GzipDecompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 5/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import zlib

class GzipDecompressor: DecompressorProtocol {
	private static let bufferSize = 65536

	struct ZlibError: Error, LocalizedError {
		private let errorString: String

		init(errno: errno_t) {
			errorString = String(utf8String: strerror(errno)) ?? "Unknown"
		}

		init?(stream: z_stream, error: Int32) {
			if error >= 0 {
				return nil
			}

			if let message = stream.msg {
				errorString = String(cString: message)
			} else {
				errorString = "zlib error \(error)"
			}
		}

		var localizedDescription: String { errorString }
	}

	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		guard let sourceHandle = fopen(url.path.cString, "rb") else {
			throw ZlibError(errno: errno)
		}
		defer { fclose(sourceHandle) }

		// Make an empty file at the destination.
		try Data().write(to: destinationURL)
		let destinationHandle = try FileHandle(forWritingTo: destinationURL)
		defer { try? destinationHandle.close() }

		var stream = z_stream()
		defer { inflateEnd(&stream) }
		var error = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))

		if let zlibError = ZlibError(stream: stream, error: error) {
			throw zlibError
		}

		let sourceBuffer = UnsafeMutablePointer<Bytef>.allocate(capacity: bufferSize)
		let destinationBuffer = UnsafeMutablePointer<Bytef>.allocate(capacity: bufferSize)

		while true {
			let sourceCount = uInt(fread(sourceBuffer, 1, Self.bufferSize, sourceHandle))
			if sourceCount == 0 {
				break
			}

			error = ferror(sourceHandle)
			if error != 0 {
				throw ZlibError(errno: error)
			}

			stream.next_in = sourceBuffer
			stream.avail_in = sourceCount

			while true {
				stream.avail_out = uInt(bufferSize)
				stream.next_out = destinationBuffer
				error = inflate(&stream, Z_NO_FLUSH)

				if error == Z_STREAM_END {
					break
				} else if let zlibError = ZlibError(stream: stream, error: error) {
					throw zlibError
				}

				let destinationBytes = bufferSize - Int(stream.avail_out)
				let data = Data(bytes: destinationBuffer, count: destinationBytes)
				try destinationHandle.write(contentsOf: data)
			}
		}

		try destinationHandle.close()
	}
}

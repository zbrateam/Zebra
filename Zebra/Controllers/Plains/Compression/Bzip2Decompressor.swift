//
//  Bzip2Decompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class Bzip2Decompressor: DecompressorProtocol {
	private static let bufferSize = 65536

	struct Bzip2Error: Error {
		private let errorString: String

		init?(error: inout Int32, handle: inout UnsafeMutableRawPointer?) {
			if error >= 0 {
				return nil
			}
			if let string = BZ2_bzerror(&handle, &error) {
				errorString = String(utf8String: string) ?? "Unknown"
			} else {
				errorString = "Unknown"
			}
		}

		var localizedDescription: String { errorString }
	}

	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		guard let sourceHandle = fopen(url.path.cString, "rb") else {
			throw NSError()
		}
		defer { fclose(sourceHandle) }

		// Make an empty file at the destination.
		try Data().write(to: destinationURL)
		let destinationHandle = try FileHandle(forWritingTo: destinationURL)
		defer { try? destinationHandle.close() }

		var error: Int32 = 0
		var bzipHandle = BZ2_bzReadOpen(&error, sourceHandle, 0, 0, nil, 0)
		defer { BZ2_bzReadClose(&error, bzipHandle) }

		if let bzipError = Bzip2Error(error: &error, handle: &bzipHandle) {
			throw bzipError
		}

		while true {
			var chunk = [CChar](repeating: 0, count: bufferSize)
			let count = BZ2_bzRead(&error, bzipHandle, &chunk, Int32(bufferSize))

			if error == BZ_STREAM_END {
				break
			} else if let bzipError = Bzip2Error(error: &error, handle: &bzipHandle) {
				throw bzipError
			}

			let data = Data(bytes: chunk, count: Int(count))
			try destinationHandle.write(contentsOf: data)
		}

		try destinationHandle.close()
	}
}

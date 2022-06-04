//
//  AppleDecompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Compression

class AppleDecompressor: DecompressorProtocol {
	private static let bufferSize = 65536

	class func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		let sourceHandle = try FileHandle(forReadingFrom: url)
		defer { try? sourceHandle.close() }

		// Make an empty file at the destination.
		try Data().write(to: destinationURL)
		let destinationHandle = try FileHandle(forWritingTo: destinationURL)
		defer { try? destinationHandle.close() }

		let outputFilter = try OutputFilter(.decompress, using: format.algorithm!) { data in
			if let data = data {
				destinationHandle.write(data)
			}
		}

		while true {
			let chunk = sourceHandle.readData(ofLength: bufferSize)
			try outputFilter.write(chunk)
			if chunk.count < bufferSize {
				break
			}
		}

		try outputFilter.finalize()
		try sourceHandle.close()
		try destinationHandle.close()
	}
}

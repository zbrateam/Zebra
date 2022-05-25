//
//  ZstdDecompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import SwiftZSTD

class ZstdDecompressor: DecompressorProtocol {
	private static let bufferSize = 32_768

	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		let sourceHandle = try FileHandle(forReadingFrom: url)
		defer { try? sourceHandle.close() }

		// Make an empty file at the destination.
		try Data().write(to: destinationURL)
		let destinationHandle = try FileHandle(forWritingTo: destinationURL)
		defer { try? destinationHandle.close() }

		let stream = ZSTDStream()
		try stream.startDecompression()

		while true {
			let chunk = sourceHandle.readData(ofLength: bufferSize)
			var isDone = false
			destinationHandle.write(try stream.decompressionProcess(dataIn: chunk, isDone: &isDone))
			if chunk.count < bufferSize || isDone {
				break
			}
		}
	}
}

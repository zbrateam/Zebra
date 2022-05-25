//
//  Bzip2Decompressor.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import SWCompression

class Bzip2Decompressor: DecompressorProtocol {
	static func decompress(url: URL, destinationURL: URL, format: Decompressor.Format) async throws {
		// TODO: Do it streamed instead of as a whole chunk. BigBoss still uses bz2.
		let data = try Data(contentsOf: url, options: .mappedIfSafe)
		let decompressed = try BZip2.decompress(data: data)
		try decompressed.write(to: destinationURL)
	}
}

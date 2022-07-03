//
//  SourceFile.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers

enum SourceFileKind {
	case any, text, json
	case deb
	case gzip, bzip2, lzma, xz, zstd

	init?(aptCompressorName: String) {
		switch aptCompressorName {
		case "gz":   self = .gzip
		case "bz2":  self = .bzip2
		case "lzma": self = .lzma
		case "xz":   self = .xz
		case "zst":  self = .zstd
		default:     return nil
		}
	}

	var type: UTType {
		switch self {
		case .any:   return .data
		case .text:  return .plainText
		case .deb:   return .debArchive
		case .json:  return .json
		case .gzip:  return .gzip
		case .bzip2: return .bz2
		case .lzma:  return .lzma
		case .xz:    return .xz
		case .zstd:  return .zstd
		}
	}

	var `extension`: String? {
		switch self {
		case .text:  return nil
		case .gzip:  return "gz"
		case .bzip2: return "bz2"
		case .lzma:  return "lzma"
		case .xz:    return "xz"
		case .zstd:  return "zst"
		default:     return type.preferredFilenameExtension
		}
	}

	var contentTypes: Set<String> {
		let types = Set(type.tags[.mimeType] ?? [])
		switch self {
		case .json:
			// JSON should always be of the appropriate content type.
			return types
		default:
			// Be lenient and allow some generic content types.
			return types
				.union(["application/octet-stream", "text/plain"])
		}
	}

	var isCompressed: Bool {
		switch self {
		case .gzip, .bzip2, .lzma, .xz, .zstd:
			return true
		case .any, .text, .json, .deb:
			return false
		}
	}

	var decompressorFormat: Decompressor.Format {
		switch self {
		case .gzip:  return .gzip
		case .bzip2: return .bzip2
		case .lzma:  return .lzma
		case .xz:    return .xz
		case .zstd:  return .zstd
		default:     fatalError("Not a compressed file kind")
		}
	}
}

enum SourceFile {
	case inRelease, release, releaseGpg
	case packages(kind: SourceFileKind)
	case paymentEndpoint
	case featured

	var kind: SourceFileKind {
		switch self {
		case .inRelease:       return .any
		case .release:         return .text
		case .releaseGpg:      return .any
		case .packages(let kind): return kind
		case .paymentEndpoint: return .any
		case .featured:        return .json
		}
	}

	var name: String {
		switch self {
		case .inRelease:       return "InRelease"
		case .release:         return "Release"
		case .releaseGpg:      return "Release.gpg"
		case .paymentEndpoint: return "payment_endpoint"
		case .featured:        return "sileo-featured.json"
		case .packages(let kind):
			if let ext = kind.extension {
				return "Packages.\(ext)"
			}
			return "Packages"
		}
	}

	var progressWeight: Int64 {
		switch self {
		// Either InRelease or Release + Release.gpg.
		case .inRelease:       return 200

		// 80 + 20 = 100
		case .release:         return 150
		case .releaseGpg:      return 50

		case .paymentEndpoint: return 100
		case .featured:        return 100

		// The majority of the time will be spent on Packages.
		case .packages(_):     return 400
		}
	}
}

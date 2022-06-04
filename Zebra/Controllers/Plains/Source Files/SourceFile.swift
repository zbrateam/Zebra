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
	case any, text, deb, gzip, bzip2, lzma, xz, zstd

	var type: UTType {
		switch self {
		case .any:   return .data
		case .text:  return .plainText
		case .deb:   return .debArchive
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
		Set(type.tags[.mimeType] ?? []).union(["application/octet-stream", "text/plain"])
	}

	var isCompressed: Bool {
		switch self {
		case .gzip, .bzip2, .lzma, .xz, .zstd:
			return true
		case .any, .text, .deb:
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

	var kind: SourceFileKind {
		switch self {
		case .inRelease:  return .any
		case .release:    return .text
		case .releaseGpg: return .any
		case .packages(let kind): return kind
		}
	}

	var name: String {
		switch self {
		case .inRelease:  return "InRelease"
		case .release:    return "Release"
		case .releaseGpg: return "Release.gpg"
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
		case .inRelease:   return 100

		// 80 + 20 = 100
		case .release:     return 80
		case .releaseGpg:  return 20

		// The remainder is the Packages file.
		case .packages(_): return 800
		}
	}
}

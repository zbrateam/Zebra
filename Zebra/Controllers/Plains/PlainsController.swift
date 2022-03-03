//
//  PlainsController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import os.log

class PlainsController {

	static let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! / Bundle.main.bundleIdentifier!
	static let dataURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first! / Bundle.main.bundleIdentifier!

	class func setUp() throws {
		let config = PLConfig.shared

		// Create directories
		for path in ["logs", "archives", "archives/partial"] {
			try FileManager.default.createDirectory(at: cacheURL/path,
																							withIntermediateDirectories: true,
																							attributes: [:])
		}

		// Set directories
		let dpkgStateURL = URL(fileURLWithPath: Device.distroVarPrefix, isDirectory: true)/"var/lib/dpkg"
		let dpkgDataURL = URL(fileURLWithPath: Device.distroRootPrefix, isDirectory: true)/"share/dpkg"
		let etcPrefixURL = URL(fileURLWithPath: Device.distroEtcPrefix, isDirectory: true)

		config.set(string: (cacheURL/"logs").path, forKey: "Dir::Log")
		config.set(string: cacheURL.path, forKey: "Dir::Cache")
		config.set(string: dataURL.path, forKey: "Dir::State")
		config.set(string: (etcPrefixURL/"etc/apt"), forKey: "Dir::Etc")
		config.set(string: (dataURL/"zebra.sources").path, forKey: "Plains::SourcesList")
		config.set(string: (dpkgStateURL/"status").path, forKey: "Dir::State::status")
		config.set(string: (dpkgDataURL/"tupletable").path, forKey: "Dir::dpkg::tupletable")
		config.set(string: (dpkgDataURL/"triplettable").path, forKey: "Dir::dpkg::triplettable")
		config.set(string: (dpkgDataURL/"cputable").path, forKey: "Dir::dpkg::cputable")

		// Set slingshot path
		config.set(string: SlingshotController.superslingPath, forKey: "Plains::Slingshot")
		config.set(string: SlingshotController.superslingPath, forKey: "Dir::Bin::dpkg")

		// Set the primary architecture
		config.set(string: Device.primaryDebianArchitecture, forKey: "APT::Architecture")

		// Allow unsigned repos only on iOS
		#if !targetEnvironment(macCatalyst)
		config.set(boolean: true, forKey: "Acquire::AllowInsecureRepositories")
		#endif

		// Configure http method
		config.set(string: URLController.aptUserAgent, forKey: "Acquire::http::User-Agent")

		// Configure finish fd
		var finishFds: [Int32] = [0, 0]
		if pipe(&finishFds) == 0 {
			config.set(integer: finishFds[0], forKey: "Plains::FinishFD::")
			config.set(integer: finishFds[1], forKey: "Plains::FinishFD::")
		} else {
			os_log("[Zebra] Unable to create file descriptors.")
		}

		// Reset the default compression type ordering
		let compressors: [(ext: String, program: String)] = [
			("zst",  "zstd"),
			("xz",   "xz"),
			("lzma", "lzma"),
			("lz4",  "lz4"),
			("bz2",  "bzip2"),
			("gz",   "gzip")
		]
		for (ext, program) in compressors {
			config.set(string: program, forKey: "Acquire::CompressionTypes::\(ext)")
		}

		#if DEBUG
		let debugKeys = [
			"Debug::Acquire::cdrom",
			"Debug::Acquire::Ftp",
			"Debug::Acquire::gpgv",
			"Debug::Acquire::netrc",
			"Debug::Acquire::Progress",
			"Debug::Acquire::Retries",
			"Debug::Acquire::SrvRecs",
			"Debug::Acquire::Transaction",
			"Debug::APT::FTPArchive::Clean",
			"Debug::APT::Progress::PackageManagerFd",
			"Debug::aptcdrom",
			"Debug::AptMark::Minimize",
			"Debug::EDSP::WriteSolution",
			"Debug::GetListOfFilesInDir",
			"Debug::Hashes",
			"Debug::identcdrom",
			"Debug::InstallProgress::Fancy",
			"Debug::Locking",
			"Debug::NoDropPrivs",
			"Debug::NoLocking",
			"Debug::Phasing",
			"Debug::pkgAcqArchive::NoQueue",
			"Debug::pkgAcquire::Auth",
			"Debug::pkgAcquire::Diffs",
			"Debug::pkgAcquire::Worker",
			"Debug::pkgAcquire",
			"Debug::pkgAutoRemove",
			"Debug::pkgCacheGen",
			"Debug::pkgDepCache::AutoInstall",
			"Debug::pkgDepCache::Marker",
			"Debug::pkgDpkgPm",
			"Debug::pkgDPkgPM",
			"Debug::pkgDPkgProgressReporting",
			"Debug::pkgInitConfig",
			"Debug::pkgOrderList",
			"Debug::pkgPackageManager",
			"Debug::pkgPolicy",
			"Debug::pkgProblemResolver::ShowScores",
			"Debug::pkgProblemResolver",
			"Debug::RunScripts",
			"Debug::SetupAPTPartialDirectory::AssumeGood"
		]
		for key in debugKeys {
			config.set(boolean: true, forKey: key)
		}
		#endif

		// Go ahead and start doing APT stuff
		if !config.initializeAPT() {
			return
		}

		// Load the database
		PLPackageManager.shared.import()
	}

}

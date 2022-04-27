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

	class func setUp() throws {
		let config = PLConfig.shared
		let cacheURL = Device.cacheURL
		let dataURL = Device.dataURL
		let dpkgStateURL = URL(fileURLWithPath: Device.distroVarPrefix, isDirectory: true)/"var/lib/dpkg"
		let dpkgDataURL = URL(fileURLWithPath: Device.distroRootPrefix, isDirectory: true)/"share/dpkg"
		let binURL = URL(fileURLWithPath: Device.distroRootPrefix, isDirectory: true)/"bin"
		let libexecURL = URL(fileURLWithPath: Device.distroRootPrefix, isDirectory: true)/"libexec/apt"
		let etcPrefixURL = URL(fileURLWithPath: Device.distroEtcPrefix, isDirectory: true)

		// Create directories
		let dirsToCreate = [
			cacheURL/"logs",
			cacheURL/"archives",
			cacheURL/"archives/partial",
			dataURL/"lists"
		] + (Device.isDemo ? [
			dpkgStateURL,
			dpkgDataURL,
			binURL,
			libexecURL,
			etcPrefixURL/"etc/apt/apt.conf.d",
			etcPrefixURL/"etc/apt/preferences.d",
			etcPrefixURL/"etc/apt/sources.list.d"
		] : [])
		for url in dirsToCreate {
			try FileManager.default.createDirectory(at: url,
																							withIntermediateDirectories: true,
																							attributes: [:])
		}

		// Set up simulated environment if needed
		if Device.isDemo {
			let statusURL = dpkgStateURL/"status"
			if (try? statusURL.checkResourceIsReachable()) != true {
				try FileManager.default.copyItem(at: Bundle.main.url(forResource: "Installed", withExtension: "pack")!,
																				 to: statusURL)
			}
			for item in ["tupletable", "triplettable", "cputable"] {
				let url = dpkgDataURL/item
				if (try? url.checkResourceIsReachable()) != true {
					try Data().write(to: url)
				}
			}
		}

		// Set APT paths
		config.set(string: (cacheURL/"logs").path, forKey: "Dir::Log")
		config.set(string: cacheURL.path, forKey: "Dir::Cache")
		config.set(string: dataURL.path, forKey: "Dir::State")
		config.set(string: (etcPrefixURL/"etc/apt").path, forKey: "Dir::Etc")
		config.set(string: (dataURL/"zebra.sources").path, forKey: "Dir::Etc::sourcelist")
		config.set(string: (dataURL/"zebra.sources").path, forKey: "Plains::SourcesList")
		config.set(string: (dpkgStateURL/"status").path, forKey: "Dir::State::status")
		config.set(string: (dpkgDataURL/"tupletable").path, forKey: "Dir::dpkg::tupletable")
		config.set(string: (dpkgDataURL/"triplettable").path, forKey: "Dir::dpkg::triplettable")
		config.set(string: (dpkgDataURL/"cputable").path, forKey: "Dir::dpkg::cputable")
		config.set(string: (libexecURL/"methods").path, forKey: "Dir::Bin::Methods")
		config.set(string: (libexecURL/"solvers").path, forKey: "Dir::Bin::Solvers::")
		config.set(string: (libexecURL/"planners").path, forKey: "Dir::Bin::Planners::")
		config.set(string: (binURL/"apt-key").path, forKey: "Dir::Bin::apt-key")

		// Set slingshot path
		config.set(string: SlingshotController.superslingPath, forKey: "Plains::Slingshot")
		config.set(string: SlingshotController.superslingPath, forKey: "Dir::Bin::dpkg")

		// Set the primary architecture
		config.set(string: Device.primaryDebianArchitecture, forKey: "APT::Architecture")
		config.set(string: Device.primaryDebianArchitecture, forKey: "APT::Architectures::")

		// Set PATH that will be used when spawning dpkg
		config.set(string: Device.path, forKey: "DPkg::Path")

		// Allow unsigned repos only on iOS
		#if DEBUG || !targetEnvironment(macCatalyst)
		config.set(boolean: true, forKey: "Acquire::AllowInsecureRepositories")
		#endif

		// Configure http method
		config.set(string: URLController.httpUserAgent, forKey: "Acquire::http::User-Agent")

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
			"Debug::Acquire::gpgv",
			"Debug::Acquire::Progress",
			"Debug::Acquire::Retries",
			"Debug::Acquire::SrvRecs",
			"Debug::Acquire::Transaction",
			"Debug::APT::Progress::PackageManagerFd",
			"Debug::EDSP::WriteSolution",
			"Debug::GetListOfFilesInDir",
			"Debug::Hashes",
			"Debug::Locking",
			"Debug::Phasing",
			"Debug::pkgAcquire",
			"Debug::pkgAcquire::Auth",
			"Debug::pkgAcquire::Diffs",
			"Debug::pkgAcquire::Worker",
			"Debug::pkgAutoRemove",
			"Debug::pkgCacheGen",
			"Debug::pkgDepCache::AutoInstall",
			"Debug::pkgDepCache::Marker",
			"Debug::pkgDPkgProgressReporting",
			"Debug::pkgInitConfig",
			"Debug::pkgOrderList",
			"Debug::pkgPackageManager",
			"Debug::pkgPolicy",
			"Debug::pkgProblemResolver::ShowScores",
			"Debug::pkgProblemResolver",
			"Debug::RunScripts"
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

		// Kick off a refresh
		SourceRefreshController.shared.refresh(isUserRequested: false)
	}

}

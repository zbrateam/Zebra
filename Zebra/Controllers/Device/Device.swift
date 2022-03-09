//
//  Device.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

fileprivate let isSimulated = SlingshotController.isSimulated

@objc(ZBDevice)
class Device: NSObject {

	// MARK: - Environment

	static let distroRootPrefix: String = {
		#if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
		return "/opt/procursus"
		#else
		if #available(iOS 14.8, *),
			 FileManager.default.fileExists(atPath: "/private/preboot/procursus") {
			return "/private/preboot/procursus"
		} else {
			return "/usr"
		}
		#endif
	}()

	static let distroEtcPrefix = distroRootPrefix == "/usr" ? "/" : distroRootPrefix
	static let distroVarPrefix = distroRootPrefix == "/usr" ? "/" : distroRootPrefix

	static let cacheURL = FileManager.default.url(for: .cachesDirectory) / Bundle.main.bundleIdentifier!
	static let dataURL = FileManager.default.url(for: .applicationSupportDirectory) / Bundle.main.bundleIdentifier!

	@objc static let path: String = {
		// Construct a safe PATH that includes the distro prefix. This will be set app-wide.
		let prefix = URL(fileURLWithPath: distroRootPrefix, isDirectory: true)
		var path = ["/usr/sbin", "/usr/bin", "/sbin", "/bin"]
		if prefix.path != "/usr" && (try? prefix.checkResourceIsReachable()) == true {
			path.insert(contentsOf: [
				(prefix/"sbin").path,
				(prefix/"bin").path
			], at: 0)
		}
		return path.joined(separator: ":")
	}()

	@objc static let primaryDebianArchitecture: String = {
		// Cheat and say we’re on simulator.
		#if targetEnvironment(simulator)
		return "iphoneos-arm"
		#else
		// Ask dpkg what architecture we’re on. If this doesn’t work, either dpkg is broken, or we’re
		// sandboxed for some reason.
		let dpkgPath = (URL(fileURLWithPath: distroRootPrefix, isDirectory: true)/"bin/dpkg").path
		if let result = try? Command.executeSync(dpkgPath, arguments: ["--print-architecture"]),
			 !result.isEmpty {
			return String(result[..<(result.firstIndex(of: "\n") ?? result.endIndex)])
		}

		// Fall back to making our best guess.
		#if targetEnvironment(macCatalyst)
		#if arch(x86_64)
		return "darwin-amd64"
		#else
		return "darwin-arm64"
		#endif
		#else
		return "iphoneos-arm"
		#endif
		#endif
	}()

	// MARK: - Distro/Jailbreak

	private class func isRegularFile(path: String) -> Bool {
		var isDir: ObjCBool = false
		return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
	}

	private class func isRegularDirectory(path: String) -> Bool {
		var isDir: ObjCBool = false
		return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
	}

	@objc static let isCheckrain  = !isSimulated && isRegularFile(path: "/.bootstrapped")
	@objc static let isChimera    = !isSimulated && isRegularDirectory(path: "/chimera")
	@objc static let isElectra    = !isSimulated && isRegularDirectory(path: "/electra")
	@objc static let isUncover    = !isSimulated && isRegularFile(path: "/.installed_unc0ver")
	@objc static let isOdyssey    = !isSimulated && isRegularFile(path: "/.installed_odyssey")
	@objc static let isTaurine    = !isSimulated && isRegularFile(path: "/.installed_taurine")
	@objc static let hasProcursus = !isSimulated && isRegularFile(path: "/.procursus_strapped")

	@objc static let jailbreakType: String = {
		if isOdyssey {
			return "Odyssey"
		} else if isCheckrain {
			return "checkra1n"
		} else if isChimera {
			return "Chimera"
		} else if isElectra {
			return "Electra"
		} else if isUncover {
			return "unc0ver"
		}
		return "Unknown"
	}()

}

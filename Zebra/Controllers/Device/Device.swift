//
//  Device.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

fileprivate let isSimulated = SlingshotController.isSimulated

enum Jailbreak: Int {
	case demo = -1
	case unknown
	case palera1n
	case dopamine
}

enum Distribution: Int {
	case unknown
	case procursus
}

@objc(ZBDevice)
class Device: NSObject {

	// MARK: - Environment

	static let systemRootPrefix: URL = { URL(fileURLWithPath: isDemo ? (dataURL/"demo-sysroot").path : "/", isDirectory: true) }()

	static let distroRootPrefix: URL = {
		#if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
		URL(fileURLWithPath: "/opt/procursus", isDirectory: true)
		#else
		URL(fileURLWithPath: isDemo ? (dataURL/"demo-sysroot").path : "/var/jb", isDirectory: true)
		#endif
	}()

	static let cacheURL = FileManager.default.url(for: .cachesDirectory)/Bundle.main.bundleIdentifier!
	static let dataURL = FileManager.default.url(for: .applicationSupportDirectory)/Bundle.main.bundleIdentifier!

	static let isDemo: Bool = {
		#if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
		return false
		#else
		// TODO: Need to replace with sandbox_check(). Forking is broken on iOS 15+, has a perf penalty
		//       under Cheyote.
		switch forkplz() {
		case 0:
			// Forked process - just terminate the fork, we don’t need it to do anything else.
			exit(0)
		case -1:
			// Parent process - fork failed. EPERM would indicate being blocked by sandbox.
			return errno == EPERM
		default:
			// Parent process - fork succeeded.
			return false
		}
		#endif
	}()

	static let path: String = {
		// Construct a safe PATH that includes the distro prefix. This will be set app-wide.
		let path = ["/usr/sbin", "/usr/bin", "/sbin", "/bin"]
		return (path.map { (distroRootPrefix/$0).path } + path)
			.joined(separator: ":")
	}()

	static let architectures: [String] = {
		#if targetEnvironment(simulator)
		// Cheat and say we’re iphoneos-arm64 on simulator.
		return ["iphoneos-arm64"]
		#else
		// Ask dpkg what architecture we’re on. If this doesn’t work, either dpkg is broken, or we’re
		// sandboxed for some reason.
		if !isDemo {
			let dpkgPath = (distroRootPrefix/"bin/dpkg").path
			let primaryArch = (try? Command.executeSync(dpkgPath, arguments: ["--print-architecture"]))?
				.trimmingCharacters(in: .whitespacesAndNewlines)
			let foreignArchs = try? Command.executeSync(dpkgPath, arguments: ["--print-foreign-architectures"])?
				.trimmingCharacters(in: .whitespacesAndNewlines)
			return "\(primaryArch ?? "")\n\(foreignArchs ?? "")"
				.split(separator: "\n", omittingEmptySubsequences: true)
				.map(String.init(_:))
		}

		// Fall back to making our best guess.
		#if targetEnvironment(macCatalyst)
		#if arch(x86_64)
		return ["darwin-amd64"]
		#else
		return ["darwin-arm64"]
		#endif
		#else
		return ["iphoneos-arm64"]
		#endif
		#endif
	}()

	@objc static var primaryDebianArchitecture: String { architectures.first! }

	// MARK: - Distro/Jailbreak

	private class func isRegularFile(path: String) -> Bool {
		var isDir: ObjCBool = false
		return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
	}

	private class func isRegularDirectory(path: String) -> Bool {
		var isDir: ObjCBool = false
		return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
	}

	static let jailbreak: Jailbreak = {
		switch true {
		case isDemo: .demo
		case isRegularFile(path: "\(systemRootPrefix)/.installed_palera1n"):  .palera1n
		case isRegularFile(path: "\(systemRootPrefix)/.palecursus_strapped"): .palera1n
		case isRegularFile(path: "\(systemRootPrefix)/.installed_fugu15max"): .dopamine
		case isRegularFile(path: "\(systemRootPrefix)/.installed_dopamine"):  .dopamine
		default:     .unknown
		}
	}()

	static let jailbreakName: String = {
		switch jailbreak {
		case .demo:     .localize("Demo Mode")
		case .unknown:  .localize("Unknown Jailbreak")
		case .palera1n: "palera1n"
		case .dopamine: "Dopamine"
		}
	}()

	static let distro: Distribution = {
		switch true {
		case isDemo:    .procursus
		case isRegularFile(path: "\(systemRootPrefix)/.procursus_strapped"): .procursus
		default:        .unknown
		}
	}()

	static let distroName: String = {
		switch distro {
		case .unknown:   .localize("Unknown Distribution")
		case .procursus: "Procursus"
		}
	}()

}

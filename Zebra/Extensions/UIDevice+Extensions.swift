//
//  UIDevice+Additions.swift
//  NewTerm Common
//
//  Created by Adam Demasi on 25/9/21.
//

import UIKit
import Darwin
import UniformTypeIdentifiers

#if targetEnvironment(macCatalyst)
import IOKit
#endif

@available(iOS 14, *)
extension UTTagClass {
	static let deviceModelCode = UTTagClass(rawValue: "com.apple.device-model-code")
}

// Well-known fallback device identifiers. The UDID is the SHA1 of nothing.
fileprivate let udidFallback = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
fileprivate let machineFallback = "iPhone10,3"

enum Bitness: Int {
	case _64 = 64
}

enum Architecture: String {
	case x86_64 = "x86_64"
	case arm64 = "arm64"

	var clientHint: String {
		switch self {
		case .x86_64: return "x86"
		case .arm64:  return "arm"
		}
	}
}

@objc extension UIDevice {

	@objc(zbra_udid)
	var udid: String {
		#if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
		return udidFallback
		#else
		return MGCopyAnswer(kMGUniqueDeviceID)?.takeUnretainedValue() as? String ?? udidFallback
		#endif
	}

	@objc(zbra_machine)
	var machine: String {
		#if targetEnvironment(simulator)
		// Use a safe fallback. iPhone10,3 (iPhone X) is a well-known value seen with the well-known
		// UDID above.
		return machineFallback
		#else
		#if targetEnvironment(macCatalyst)
		let key = "hw.model"
		#else
		let key = "hw.machine"
		#endif
		if let value = sysctlValue(key: key) {
			return value
		}
		#if targetEnvironment(macCatalyst)
		return "Mac"
		#else
		return model
		#endif
		#endif
	}

	@objc(zbra_hardwareModel)
	var hardwareModel: String {
		#if targetEnvironment(macCatalyst)
		// localizedModel on macOS always returns “iPad” 🙁
		// Grab the device machine identifier directly, then find its name via CoreTypes.
		return UTType(tag: machine,
									tagClass: .deviceModelCode,
									conformingTo: nil)?.localizedDescription ?? "Mac"
		#else
		return localizedModel
		#endif
	}

	@objc(zbra_hardwarePlatform)
	var hardwarePlatform: String {
		#if targetEnvironment(macCatalyst)
		return "Mac"
		#else
		switch model {
		case "iPod touch": return "iPod"
		default:           return model
		}
		#endif
	}

	@objc(zbra_osName)
	var osName: String {
		#if targetEnvironment(macCatalyst)
		return "macOS"
		#else
		switch systemName {
		case "iPhone OS": return "iOS"
		case "Mac OS X":  return "macOS"
		default:          return systemName
		}
		#endif
	}

	@objc(zbra_osVersion)
	var osVersion: String {
		#if targetEnvironment(macCatalyst)
		if let value = sysctlValue(key: "kern.osproductversion") {
			return value
		}
		#endif
		return systemVersion
	}

	@nonobjc var bitness: Bitness {
		// Don’t add a catch-all #else here, this will ensure any future archs not accounted for will
		// throw a build error.
		#if arch(x86_64) || arch(arm64)
		._64
		#endif
	}

	@nonobjc var architecture: Architecture {
		// Don’t add a catch-all #else here, this will ensure any future archs not accounted for will
		// throw a build error.
		#if arch(x86_64)
		return .x86_64
		#elseif arch(arm64)
		return .arm64
		#endif
	}

	private func sysctlValue(key: String) -> String? {
		var size = size_t()
		sysctlbyname(key, nil, &size, nil, 0)
		let value = malloc(size)
		defer {
			value?.deallocate()
		}
		sysctlbyname(key, value, &size, nil, 0)
		if let cChar = value?.bindMemory(to: CChar.self, capacity: size) {
			return String(cString: cChar)
		}
		return nil
	}

}

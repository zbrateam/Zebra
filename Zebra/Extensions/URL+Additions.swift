//
//  URL+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 3/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

fileprivate let permittedInsecureDomains: [String] = {
	if let ats = Bundle.main.object(forInfoDictionaryKey: "NSAppTransportSecurity") as? [String: Any],
		 let exceptions = ats["NSExceptionDomains"] as? [String: [String: Any]] {
		return exceptions.compactMap { key, value in (value["NSExceptionAllowsInsecureHTTPLoads"] as? Bool) ?? false ? key : nil }
	}
	return []
}()

extension URL {

	struct XattrError: Error {
		let localizedDescription: String

		init(errno: errno_t) {
			localizedDescription = String(cString: strerror(errno))
		}
	}

	static let etagXattr = "com.getzbra.etag"

	static func / (lhs: URL, rhs: String) -> URL {
		rhs == ".." ? lhs.deletingLastPathComponent() : lhs.appendingPathComponent(rhs)
	}

	/// Return a URL that can be loaded, or at least attempted to be loaded, within App Transport
	/// Security restrictions.
	var secureURL: URL? {
		switch scheme {
		case "http":
			if let host = host,
				 permittedInsecureDomains.contains(host) {
				return self
			}

			guard var url = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
				return nil
			}
			url.scheme = "https"
			return url.url

		case "https", "file":
			return self

		default:
			return nil
		}
	}

	/// Return a cleaned URL for display.
	var displayString: String {
		absoluteString.replacingOccurrences(regex: "^https?://|/$", with: "")
	}

	func extendedAttributeData(forKey key: String) throws -> Data? {
		let count = getxattr(path, key, nil, 0, 0, 0)
		if count == -1 {
			if errno == ENOATTR {
				// Doesn’t exist
				return nil
			}
			throw XattrError(errno: errno)
		}

		var value = Data(count: count)
		let result = value.withUnsafeMutableBytes { getxattr(path, key, $0.baseAddress, count, 0, 0) }
		if result == -1 {
			throw XattrError(errno: errno)
		}
		return value
	}

	func extendedAttribute(forKey key: String) throws -> String? {
		if let data = try extendedAttributeData(forKey: key) {
			return String(data: data, encoding: .utf8)
		}
		return nil
	}

	func setExtendedAttribute(_ value: Data?, forKey key: String) throws {
		if var value = value {
			let result = value.withUnsafeMutableBytes {
				guard let address = $0.baseAddress else {
					return Int32(-1)
				}
				return setxattr(path, key, address, strlen(address), 0, 0)
			}
			if result == -1 {
				throw XattrError(errno: errno)
			}
		} else {
			if removexattr(path, key, 0) == -1 {
				throw XattrError(errno: errno)
			}
		}
	}

	func setExtendedAttribute(_ value: String?, forKey key: String) throws {
		try setExtendedAttribute(value?.data(using: .utf8), forKey: key)
	}
}

extension FileManager {
	func url(for searchPath: SearchPathDirectory, in domainMask: SearchPathDomainMask = .userDomainMask) -> URL {
		urls(for: searchPath, in: domainMask).first!
	}
}

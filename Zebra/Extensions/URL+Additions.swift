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
}

extension FileManager {
	func url(for searchPath: SearchPathDirectory, in domainMask: SearchPathDomainMask = .userDomainMask) -> URL {
		urls(for: searchPath, in: domainMask).first!
	}
}

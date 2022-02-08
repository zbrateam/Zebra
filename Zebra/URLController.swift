//
//  URLController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import SafariServices

@objc(ZBURLController)
class URLController: NSObject {

	// MARK: - Headers

	@objc static let webUserAgent: String = {
		let infoPlist = Bundle.main.infoDictionary!
		let device = UIDevice.current
		let userAgent = "Zebra/\(infoPlist["CFBundleShortVersionString"]!) (\(device.hardwarePlatform); \(device.osName) \(device.systemVersion)"
#if targetEnvironment(macCatalyst)
		return userAgent
#else
		return "Cydia/1.1.32 \(userAgent)"
#endif
	}()

	@objc static let aptUserAgent = "Telesphoreo (Zebra) APT-HTTP/1.0.592"

	@objc static var webHeaders: [String: String] {
		[
			"User-Agent": webUserAgent,
			"X-Firmware": UIDevice.current.systemVersion,
			"X-Machine": UIDevice.current.machine,
			"Payment-Provider": "API",
			"Tint-Color": (UIColor.accent ?? UIColor.link).hexString,
			"Accept-Language": Locale.preferredLanguages.first!
		]
	}

	@objc static let aptHeaders: [String: String] = [
		"User-Agent": webUserAgent,
		"X-Firmware": UIDevice.current.systemVersion,
		"X-Machine": UIDevice.current.machine
	]

	// MARK: - UI

	@objc(openURL:sender:)
	class func open(url: URL, sender: UIViewController) {
		guard url.scheme == "http" || url.scheme == "https" else {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			return
		}

		let viewController = SFSafariViewController(url: url)
		viewController.preferredControlTintColor = .accent
		sender.present(viewController, animated: true, completion: nil)
	}

}

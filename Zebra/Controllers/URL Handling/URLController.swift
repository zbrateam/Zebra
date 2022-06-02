//
//  URLController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import SafariServices

fileprivate protocol ClientHintValue {}
extension String: ClientHintValue {}
extension Int: ClientHintValue {}
extension CGFloat: ClientHintValue {}
extension Bool: ClientHintValue {}
extension Dictionary: ClientHintValue where Key == String, Value == String {}

@objc(ZBURLController)
class URLController: NSObject {

	// MARK: - Headers

	private static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

	static let baseUserAgent = "Zebra/\(appVersion)"

	// User agent used in web view requests.
	static let webUserAgent: String = {
		// Zebra/2.0
		#if targetEnvironment(macCatalyst)
		let compatToken = ""
		#else
		// Prepend Cydia token on iOS for compatibility.
		let compatToken = "Cydia/1.1.32 "
		#endif
		return "\(compatToken)\(baseUserAgent)"
	}()

	// User agent used in non-browser requests.
	static let httpUserAgent: String = {
		// Zebra/2.0 (iPhone; iOS 14.8.1)
		let device = UIDevice.current
		return "\(baseUserAgent) (\(device.hardwarePlatform); \(device.osName) \(device.osVersion))"
	}()

	private static func makeClientHintHeaders(_ clientHints: [String: ClientHintValue]) -> [String: String] {
		// https://www.rfc-editor.org/rfc/rfc8941
		var result = [String: String]()
		for (key, value) in clientHints {
			if let value = value as? [String: String] {
				result[key] = value
					.map { key, value in "\"\(key)\";v=\"\(value)\"" }
					.joined(separator: ", ")
			}
			if let value = value as? String {
				result[key] = "\"\(value)\""
			} else if let value = value as? Bool {
				result[key] = value ? "?1" : "?0"
			} else if let value = value as? NSNumber {
				let formatter = NumberFormatter()
				formatter.numberStyle = .decimal
				formatter.locale = Locale(identifier: "en_US_POSIX")
				result[key] = formatter.string(from: value)
			}
		}
		return result
	}

	// Client hints always sent.
	static let lowEntropyClientHints: [String: String] = {
		let device = UIDevice.current
		let screen = UIScreen.main
		#if targetEnvironment(macCatalyst)
		let isMobile = false
		#else
		let isMobile = screen.bounds.size.width < 500
		#endif
		return makeClientHintHeaders([
			"Sec-CH-UA": ["Zebra": appVersion],
			"Sec-CH-UA-Platform": device.osName,
			"Sec-CH-UA-Mobile": isMobile,
			// DPR is supposed to be high entropy, but I disagree that it reveals too much about the client…
			// Sec-CH-DPR is the new name for DPR
			"Sec-CH-DPR": screen.scale,
			"DPR": screen.scale
		])
	}()

	// More sensitive, fingerprintable, client hints only sent when requested.
	static let highEntropyClientHints: [String: String] = {
		let device = UIDevice.current
		let screen = UIScreen.main
		return makeClientHintHeaders([
			"Sec-CH-UA-Platform-Version": device.osVersion,
			"Sec-CH-UA-Full-Version": appVersion,
			"Sec-CH-UA-Full-Version-List": ["Zebra": appVersion],
			"Sec-CH-UA-Arch": device.architecture.clientHint,
			"Sec-CH-UA-Bitness": device.bitness.rawValue,
			"Sec-CH-UA-Model": device.machine
		])
	}()

	// Headers used by non-browser, non-APT requests.
	static var httpHeaders: [String: String] = {
		[
			"User-Agent": httpUserAgent
		] + lowEntropyClientHints
	}()

	// Headers used by web views.
	static var webHeaders: [String: String] {
		httpHeaders + [
			"Payment-Provider": "API",
			"Tint-Color": (UIColor.accent ?? UIColor.link).hexString
		]
	}

	// Headers used specifically by APT.
	@objc static let aptHeaders: [String: String] = {
#if targetEnvironment(macCatalyst)
		let headers = httpHeaders
#else
		// Legacy Cydia headers (iOS compatibility)
		let device = UIDevice.current
		let headers = httpHeaders + [
			"X-Firmware": device.osVersion,
			"X-Machine": device.machine
		]
#endif
		return headers + lowEntropyClientHints + highEntropyClientHints
	}()

	// Headers for repos that need legacy compatibility.
	static let legacyAPTHeaders: [String: String] = {
		let device = UIDevice.current
		return [
			"User-Agent": "Telesphoreo (Zebra) APT-HTTP/1.0.592",
			"X-Firmware": device.osVersion,
			"X-Machine": device.machine,
			"X-Unique-Id": device.udid,
			"X-Cydia-Id": device.udid
		]
	}()

	// MARK: - UI

	@discardableResult
	class func open(url: URL, sender: UIViewController? = nil, webSchemesOnly: Bool = false) -> Bool {
		if webSchemesOnly && url.scheme != "http" && url.scheme != "https" {
			return false
		}

		let actualSender: UIViewController
		if let sender = sender {
			actualSender = sender
		} else {
			if let sceneSession = UIApplication.shared.runningSceneSessions(withIdentifier: AppSceneDelegate.activityType).first,
				 let delegate = sceneSession.scene?.delegate as? AppSceneDelegate,
				 let rootViewController = delegate.window?.rootViewController {
				actualSender = rootViewController
			} else {
				// Can’t handle this, we don’t know where to present.
				return false
			}
		}

		switch url.scheme {
		case "zbra":
			// TODO
			break

		case "file":
			switch url.pathExtension {
			case "deb":
				let activity = NSUserActivity(activityType: PackageSceneDelegate.activityType)
				activity.userInfo = [UserActivityUserInfoKey.url: url.absoluteString]
				UIApplication.shared.activateScene(userActivity: activity,
																					 requestedBy: actualSender.view.window?.windowScene,
																					 asSingleton: false,
																					 withProminentPresentation: true)
				return true

			default: break
			}

		default:
			openExternal(url: url, sender: actualSender)
			return true
		}
		return false
	}

	@objc(openURL:sender:)
	@discardableResult
	class func __openURLObjC(url: URL, sender: UIViewController) -> Bool {
		open(url: url, sender: sender)
	}

	private class func openExternal(url: URL, sender: UIViewController) {
		#if targetEnvironment(macCatalyst)
		// Safari view controller just does this anyway on macOS.
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
		#else
		// Safari view controller can only open http/https urls.
		guard (url.scheme == "http" || url.scheme == "https") && Workspace.isSafariDefaultBrowser() else {
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			return
		}

		// Is there an app installed that opens this kind of link? If so, open with that. If not, open
		// inside Safari view controller.
		UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { success in
			if !success {
				let viewController = SFSafariViewController(url: url)
				viewController.preferredControlTintColor = .accent
				sender.present(viewController, animated: true, completion: nil)
			}
		}
		#endif
	}

}

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
		// Zebra/2.0 (iPhone; iOS 14.8.1)
		var userAgent = "Zebra/\(infoPlist["CFBundleShortVersionString"]!) (\(device.hardwarePlatform); \(device.osName) \(device.systemVersion))"
		#if !targetEnvironment(macCatalyst)
		// Prepend Cydia token on iOS for compatibility.
		userAgent = "Cydia/1.1.32 \(userAgent)"
		#endif
		return userAgent
	}()

	@objc static let aptUserAgent = "Telesphoreo (Zebra) APT-HTTP/1.0.592"

	@objc static var webHeaders: [String: String] {
		[
			"User-Agent": webUserAgent,
			"X-Firmware": UIDevice.current.osVersion,
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

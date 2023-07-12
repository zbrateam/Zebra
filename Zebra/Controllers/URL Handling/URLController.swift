//
//  URLController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import SafariServices
import HTTPTypes

fileprivate protocol ClientHintValue {}
extension String: ClientHintValue {}
extension Int: ClientHintValue {}
extension CGFloat: ClientHintValue {}
extension Bool: ClientHintValue {}

@objc(ZBURLController)
class URLController: NSObject {

	// MARK: - Headers

	private static let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

	static let baseUserAgent = "Zebra/\(appVersion)"

	// User agent used in web view requests.
	static let webUserAgent = baseUserAgent

	// User agent used in non-browser requests.
	static let httpUserAgent: String = {
		// Zebra/2.0 (iPhone; iOS 14.8.1)
		let device = UIDevice.current
		return "\(baseUserAgent) (\(device.hardwarePlatform); \(device.osName) \(device.osVersion))"
	}()

	private static func makeClientHintHeaders(_ clientHints: [HTTPField.Name: ClientHintValue]) -> HTTPFields {
		// https://www.rfc-editor.org/rfc/rfc8941
		var result = HTTPFields()
		for (key, value) in clientHints {
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
	static let lowEntropyClientHints: HTTPFields = {
		#if targetEnvironment(macCatalyst) || os(xrOS)
		let isMobile = false
		#else
		let isMobile = UIScreen.main.bounds.size.width < 500
		#endif
		let scale = UIScreen.largestScale ?? 2
		let jailbreak = Device.jailbreakName
			.lowercased()
			.replacingOccurrences(of: " ", with: "")
		let distro = Device.distroName
			.lowercased()
			.replacingOccurrences(of: " ", with: "")
		return makeClientHintHeaders([
			.chUserAgent: "Zebra;v=\(appVersion);t=client,\(jailbreak);t=jailbreak,\(distro);t=distribution",
			.chPlatform: UIDevice.current.osName,
			.chIsMobile: isMobile,
			// DPR is supposed to be high entropy, but I disagree that it reveals too much about the client…
			// Sec-CH-DPR is the new name for DPR
			.chDPR: scale,
			.dpr: scale
		])
	}()

	// More sensitive, fingerprintable, client hints only sent when requested.
	static let highEntropyClientHints: HTTPFields = {
		let device = UIDevice.current
		return makeClientHintHeaders([
			.chPlatformVersion: device.osVersion,
			.chFullVersion:     appVersion,
			.chFullVersionList: "Zebra;v=\(appVersion)",
			.chArch:            device.architecture.clientHint,
			.chBitness:         device.bitness.rawValue,
			.chModel:           device.machine
		])
	}()

	// Headers used by non-browser, non-APT requests.
	static var httpHeaders: HTTPFields = {
		[.userAgent: httpUserAgent] + lowEntropyClientHints
	}()

	// Headers used by web views.
	static var webHeaders: HTTPFields {
		httpHeaders + ([
			.paymentProvider: "API",
			.tintColor: (UIColor.accent ?? UIColor.link).hexString
		] as HTTPFields)
	}

	// Headers used specifically by APT.
	static let aptHeaders: HTTPFields = {
#if targetEnvironment(macCatalyst)
		let headers = httpHeaders
#else
		// Legacy Cydia headers (iOS compatibility)
		let device = UIDevice.current
		let headers = httpHeaders + [
			.xFirmware: device.osVersion,
			.xMachine:  device.machine
		]
#endif
		return headers + lowEntropyClientHints + highEntropyClientHints
	}()

	// Headers for repos that need legacy compatibility.
	static let legacyAPTHeaders: HTTPFields = {
		let device = UIDevice.current
		return [
			.userAgent: "Telesphoreo (Zebra) APT-HTTP/1.0.592",
			.xFirmware: device.osVersion,
			.xMachine:  device.machine,
			.xUniqueID: device.udid,
			.xCydiaID:  device.udid
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

//
//  Preferences.swift
//  Zebra
//
//  Created by Adam Demasi on 14/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

@objc(ZBInterfaceStyle)
enum InterfaceStyle: Int {
	case light, dark
}

extension UIUserInterfaceStyle {
	var zebraInterfaceStyle: InterfaceStyle {
		switch self {
		case .unspecified, .light: return .light
		case .dark:                return .dark
		@unknown default:          return .light
		}
	}
}

//@objc(ZBSettings)
//class Preferences: NSObject {
extension ZBSettings {

	private static let defaults = UserDefaults.standard

	@objc static func setUp() {
		defaults.register(defaults: [
			"AccentColor": AccentColor.cornflowerBlue.rawValue,
			"UsesSystemAccentColor": false,
			"InterfaceStyle": InterfaceStyle.light.rawValue,
			"UseSystemAppearance": true
		])
	}

	// MARK: - Theming

	@objc static var accentColor: AccentColor {
		get { AccentColor(rawValue: defaults.integer(forKey: "AccentColor")) ?? .cornflowerBlue }
		set { defaults.set(newValue, forKey: "AccentColor") }
	}

	@objc static var usesSystemAccentColor: Bool {
		get { defaults.bool(forKey: "UsesSystemAccentColor") }
		set { defaults.set(newValue, forKey: "UsesSystemAccentColor") }
	}

	@objc static var interfaceStyle: InterfaceStyle {
		get {
			if usesSystemAppearance {
				let traitCollection = UIScreen.main.traitCollection
				return traitCollection.userInterfaceStyle.zebraInterfaceStyle
			} else {
				return InterfaceStyle(rawValue: defaults.object(forKey: "InterfaceStyle") as? Int ?? -1) ?? .light
			}
		}
		set {
			// TODO
		}
	}

	@objc static var usesSystemAppearance: Bool {
		get { defaults.bool(forKey: "UseSystemAppearance") }
		set { defaults.set(newValue, forKey: "UseSystemAppearance") }
	}

	// MARK: - Language Settings

	@objc static var usesSystemLanguage: Bool {
		get { defaults.object(forKey: "UseSystemLanguage") as? Bool ?? false }
		set { defaults.set(newValue, forKey: "UseSystemLanguage") }
	}

	@objc static var selectedLanguage: String? {
		get { (defaults.object(forKey: "AppleLanguages") as? [String])?.first }
		set { defaults.set(newValue == nil ? nil : [newValue], forKey: "AppleLanguages") }
	}

	// MARK: - Filters

}

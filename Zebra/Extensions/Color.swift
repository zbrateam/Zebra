//
//  Color.swift
//  Zebra
//
//  Created by Adam Demasi on 14/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

@objc(ZBAccentColor)
enum AccentColor: Int, CaseIterable {
	case aquaVelvet
	case cornflowerBlue
	case emeraldCity
	case goldenTainoi
	case irisBlue
	case lotusPink
	case monochrome
	case mountainMeadow
	case pastelRed
	case purpleHeart
	case royalBlue
	case shark
	case storm

	var name: String {
		switch self {
		case .aquaVelvet:     return "Aqua Velvet"
		case .cornflowerBlue: return "Cornflower Blue"
		case .emeraldCity:    return "Emerald City"
		case .goldenTainoi:   return "Golden Tainoi"
		case .irisBlue:       return "Iris Blue"
		case .lotusPink:      return "Lotus Pink"
		case .monochrome:     return "Monochrome"
		case .mountainMeadow: return "Mountain Meadow"
		case .pastelRed:      return "Pastel Red"
		case .purpleHeart:    return "Purple Heart"
		case .royalBlue:      return "Royal Blue"
		case .shark:          return "Shark"
		case .storm:          return "Storm"
		}
	}

	var uiColor: UIColor { UIColor(named: name)! }
}

typealias ColorRGBAComponents = (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
typealias ColorHSBAComponents = (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)

extension UIColor {

	var rgbaComponents: ColorRGBAComponents {
		var bits: ColorRGBAComponents = (0, 0, 0, 0)
		getRed(&bits.r, green: &bits.g, blue: &bits.b, alpha: &bits.a)
		return bits
	}

	var hsbaComponents: ColorHSBAComponents {
		var bits: ColorHSBAComponents = (0, 0, 0, 0)
		getHue(&bits.h, saturation: &bits.s, brightness: &bits.b, alpha: &bits.a)
		return bits
	}

	var luminosity: CGFloat {
		// Based on https://github.com/mattjgalloway/MJGFoundation/blob/master/Source/Categories/UIColor/UIColor-MJGAdditions.m
		let bits = rgbaComponents
		return 0.2126 * pow(bits.r, 2.2) + 0.7152 * pow(bits.g, 2.2) + 0.0722 * pow(bits.b, 2.2)
	}

	@objc var hexString: String {
		let bits = rgbaComponents
		return String(format: "#%02lX%02lX%02lX%02lX",
									lroundf(Float(bits.r) * 255),
									lroundf(Float(bits.g) * 255),
									lroundf(Float(bits.b) * 255),
									lroundf(Float(bits.a) * 255))
	}

	@objc func legibleColor(_ color: UIColor) -> UIColor {
		let black = luminosityDifference(to: .black)
		let white = luminosityDifference(to: .white)
		return black > white ? .black : .white
	}

	@objc func luminosityDifference(to otherColor: UIColor) -> CGFloat {
		// Based on https://github.com/mattjgalloway/MJGFoundation/blob/master/Source/Categories/UIColor/UIColor-MJGAdditions.m
		let l1 = self.luminosity
		let l2 = otherColor.luminosity
		if l1 >= 0 && l2 >= 0 {
			if l1 > l2 {
				return (l1 + 0.05) / (l2 + 0.05)
			} else {
				return (l2 + 0.05) / (l1 + 0.05)
			}
		}
		return 0
	}

	@objc func blended(with otherColor: UIColor, amount: CGFloat) -> UIColor {
		// Partially from https://stackoverflow.com/a/34077839
		let progress = min(1, max(0, amount))
		let selfBits = self.rgbaComponents
		let otherBits = otherColor.rgbaComponents
		return UIColor(red: (1 - progress) * selfBits.r + progress * otherBits.r,
									 green: (1 - progress) * selfBits.g + progress * otherBits.g,
									 blue: (1 - progress) * selfBits.b + progress * otherBits.b,
									 alpha: selfBits.a)
	}

}

extension UIColor {

	@objc(accentColor)
	static var accent: UIColor? {
		ZBSettings.usesSystemAccentColor ? nil : ZBSettings.accentColor.uiColor
	}

	@objc func getAccentColor(_ accentColor: AccentColor, forInterfaceStyle userInterfaceStyle: UIUserInterfaceStyle) -> UIColor {
		let traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
		return accentColor.uiColor.resolvedColor(with: traitCollection)
	}

	@objc func localizedName(forAccentColor accentColor: AccentColor) -> String {
		if ZBSettings.usesSystemAccentColor {
			return NSLocalizedString("System", comment: "")
		}
		return NSLocalizedString(accentColor.name, comment: "")
	}

	@objc(badgeColor)
	static var badge: UIColor { UIColor(named: "Badge Color")! }

	@objc(imageBorderColor)
	static var imageBorder: UIColor { UIColor(named: "Image Border Color")! }

}

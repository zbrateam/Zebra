//
//  HelionTheme.swift
//  Zebra
//
//  Created by Amy While on 28/12/2021.
//  Copyright © 2021 Wilson Styres. All rights reserved.
//

import Foundation
import UIKit

public class HelionTheme {

	static var backgroundColour: UIColor {
		UIColor(dynamicProvider: { traitCollection in
			if traitCollection.userInterfaceStyle == .dark {
				return UIColor(red: 0.10, green: 0.10, blue: 0.10)
			} else {
				return .white
			}
		})
	}

	static var buttonBackground: UIColor {
		UIColor(dynamicProvider: { traitCollection in
			if traitCollection.userInterfaceStyle == .dark {
				return UIColor(red: 0.20, green: 0.20, blue: 0.20)
			} else {
				return UIColor(red: 0.93, green: 0.93, blue: 0.93)
			}
		})
	}

	static var buttonText: UIColor {
		UIColor(dynamicProvider: { traitCollection in
			if traitCollection.userInterfaceStyle == .dark {
				return UIColor(red: 0.89, green: 0.50, blue: 0.00)
			} else {
				return UIColor(red: 0.94, green: 0.51, blue: 0.20)
			}
		})
	}

	static var nativeDepictionTint = UIColor(red: 0.47, green: 0.53, blue: 0.97)

	static var secondaryNativeDepictionTint: UIColor = UIColor(red: 0.47, green: 0.53, blue: 0.97, alpha: 0.2)

	static var installConsoleBackground = UIColor(red: 0.20, green: 0.20, blue: 0.20)

}

@objc public extension UIColor {

	static var backgroundColor: UIColor {
		HelionTheme.backgroundColour
	}

	static var buttonBackground: UIColor {
		HelionTheme.buttonBackground
	}

	static var buttonText: UIColor {
		HelionTheme.buttonText
	}

	static var nativeDepictionTint: UIColor {
		HelionTheme.nativeDepictionTint
	}

	static var secondaryNativeDepictionTint: UIColor {
		HelionTheme.secondaryNativeDepictionTint
	}

	static var installConsoleBackground: UIColor {
		HelionTheme.installConsoleBackground
	}
}

fileprivate extension UIColor {

	convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
		self.init(red: red, green: green, blue: blue, alpha: 1)
	}

}

//
//  UIFont+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 14/1/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

extension UIFont {

	@objc static let monospace     = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
	@objc static let boldMonospace = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)

	class func preferredFont(forTextStyle style: TextStyle, weight: Weight) -> UIFont {
		let dynamicFont = preferredFont(forTextStyle: style)
		let font = systemFont(ofSize: dynamicFont.pointSize, weight: weight)
		return UIFontMetrics(forTextStyle: style)
			.scaledFont(for: font)
	}

}

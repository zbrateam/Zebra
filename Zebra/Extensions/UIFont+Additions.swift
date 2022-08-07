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

	class func preferredFont(forTextStyle style: TextStyle, scale: CGFloat = 1, minimumSize: CGFloat = 0, weight: Weight = .regular) -> UIFont {
		let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
		let font = systemFont(ofSize: max(descriptor.pointSize * scale, minimumSize), weight: weight)
		return UIFontMetrics(forTextStyle: style)
			.scaledFont(for: font)
	}

}

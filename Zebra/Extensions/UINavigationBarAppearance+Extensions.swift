//
//  UINavigationBarAppearance+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

extension UINavigationBarAppearance {

	static var `default`: Self {
		let appearance = Self()
		appearance.configureWithDefaultBackground()
		return appearance
	}

	static var transparent: Self {
		let appearance = Self()
		appearance.configureWithTransparentBackground()
		return appearance
	}

	static var withoutSeparator: Self {
		let appearance = self.default
		appearance.shadowColor = nil
		return appearance
	}

}

//
//  UIScreen+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 26/6/2023.
//  Copyright © 2023 Zebra Team. All rights reserved.
//

import UIKit

extension UIScreen {
	static var largestScale: CGFloat? {
		UIApplication.shared.openSessions
			.compactMap { ($0.scene as? UIWindowScene)?.screen.scale }
			.sorted()
			.last
	}
}

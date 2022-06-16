//
//  UIImage+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 16/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

extension UIImage.SymbolConfiguration {

	var multicolor: Self {
		if #available(iOS 15, *) {
			return Self.preferringMulticolor().applying(self)
		}
		return self
	}

	func withHierarchicalColor(_ hierarchicalColor: UIColor) -> Self {
		if #available(iOS 15, *) {
			return Self(hierarchicalColor: hierarchicalColor).applying(self)
		}
		return self
	}

}

//
//  UIListContentConfiguration+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 23/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

extension UIListContentConfiguration {

	static func zebraDefaultCell() -> UIListContentConfiguration {
		var config = UIListContentConfiguration.cell()
		config.textProperties.font = .preferredFont(forTextStyle: .headline)
		config.imageProperties.preferredSymbolConfiguration = .init(textStyle: .headline)
		config.imageToTextPadding = 10
		return config
	}

	static func zebraSubtitleCell() -> UIListContentConfiguration {
		var config = UIListContentConfiguration.subtitleCell()
		config.textProperties.font = .preferredFont(forTextStyle: .headline)
		config.textProperties.numberOfLines = 1
		config.secondaryTextProperties.font = .preferredFont(forTextStyle: .footnote)
		config.secondaryTextProperties.color = .secondaryLabel
		config.secondaryTextProperties.numberOfLines = 1
		config.textToSecondaryTextVerticalPadding = 2
		config.imageProperties.preferredSymbolConfiguration = .init(textStyle: .headline)
		config.imageToTextPadding = 10
		return config
	}

	static func zebraValueCell() -> UIListContentConfiguration {
		var config = self.zebraSubtitleCell()
		config.prefersSideBySideTextAndSecondaryText = true
		config.imageProperties.preferredSymbolConfiguration = .init(textStyle: .headline)
		return config
	}

}

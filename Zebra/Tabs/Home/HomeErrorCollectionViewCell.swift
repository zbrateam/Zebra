//
//  HomeErrorCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 10/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class HomeErrorCollectionViewCell: UICollectionViewListCell {

	var text: String? {
		didSet { setNeedsUpdateConfiguration() }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		accessories = [
			.disclosureIndicator(),
			.customView(configuration: .init(customView: UIView(),
																			 placement: .trailing(),
																			 isHidden: true,
																			 reservedLayoutWidth: .custom(30)))
		]
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)

		var configuration = UIListContentConfiguration.zebraDefaultCell()

		var margins = directionalLayoutMargins
		margins.leading += 15
		margins.trailing += 15
		configuration.directionalLayoutMargins = margins

		configuration.text = text
		configuration.image = UIImage(systemName: "exclamationmark.triangle.fill")
		self.contentConfiguration = configuration.updated(for: state)

		var backgroundConfiguration = UIBackgroundConfiguration.clear()
		backgroundConfiguration.backgroundColor = state.isHighlighted ? .systemGray4 : .systemGray6
		backgroundConfiguration.cornerRadius = 15
		backgroundConfiguration.edgesAddingLayoutMarginsToBackgroundInsets = [.leading, .trailing]
		self.backgroundConfiguration = backgroundConfiguration.updated(for: state)
	}

}

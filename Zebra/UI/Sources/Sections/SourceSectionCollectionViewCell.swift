//
//  SourceSectionCollectionViewCell.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SourceSectionCollectionViewCell: UICollectionViewListCell {

	var section: (name: String?, count: UInt, isSource: Bool)? {
		didSet { setNeedsUpdateConfiguration() }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		accessories = [.disclosureIndicator()]
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		section = nil
		super.prepareForReuse()
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		var config: UIListContentConfiguration
		var accessories: [UICellAccessory] = [.disclosureIndicator()]

		guard let (name, count, isSource) = section else {
			return
		}

		if let name = name {
			config = .zebraValueCell()
			config.text = .localize(name)
			config.secondaryText = NumberFormatter.count.string(for: count)
			config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
			accessories += [.iconImageView(url: nil,
																		 fallbackImage: SectionIcon.icon(for: name),
																		 width: 29)]
		} else {
			config = .zebraSubtitleCell()
			config.text = .localize("All Packages")
			config.secondaryText = isSource ? .localize("Browse packages from this source.") : .localize("Browse packages from all sources.")
			config.image = UIImage(named: "zebra.wrench")
			config.imageProperties.preferredSymbolConfiguration = .init(scale: .large)
			config.imageProperties.tintColor = .secondaryLabel
			config.imageProperties.reservedLayoutSize = CGSize(width: 29, height: 29)
		}

		self.accessories = accessories
		self.contentConfiguration = config.updated(for: state)
	}

}

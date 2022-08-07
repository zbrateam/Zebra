//
//  SourceCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class SourceCollectionViewCell: UICollectionViewListCell {

	var source: Source! {
		didSet { setNeedsUpdateConfiguration() }
	}

	var sourceState: SourceRefreshController.SourceState? {
		didSet { setNeedsUpdateConfiguration() }
	}

	private let progressView = ProgressDonut()
	private let iconImageView = IconImageView(size: 40)

	private var niceSourceURL: String?

	override func prepareForReuse() {
		source = nil
		super.prepareForReuse()
	}

	override func willMove(toSuperview newSuperview: UIView?) {
		super.willMove(toSuperview: newSuperview)

		if newSuperview == nil {
			NotificationCenter.default.removeObserver(self, name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		} else {
			NotificationCenter.default.addObserver(self, selector: #selector(self.progressDidChange), name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		}
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)

		var config = UIListContentConfiguration.zebraSubtitleCell()
		var accessories: [UICellAccessory] = [.disclosureIndicator()]

		if let source = source {
			config.text = source.origin
			config.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

			if let host = source.uri.host,
				 let image = UIImage(named: "Repo Icons/\(host)") {
				iconImageView.setImageURL(nil, fallbackImage: image)
			} else {
				iconImageView.setImageURL(source.iconURL)
			}
			accessories += [.customView(configuration: .init(customView: iconImageView,
																											 placement: .leading(),
																											 reservedLayoutWidth: .custom(iconImageView.size)))]

			if SourceRefreshController.shared.isRefreshing,
				 let progress = sourceState?.progress {
				accessories += [
					.customView(configuration: .init(customView: progressView,
																					 placement: .trailing(),
																					 reservedLayoutWidth: .actual,
																					 maintainsFixedSize: true))
				]
				progressView.progress = progress.fractionCompleted
			}

			if let errors = sourceState?.errors,
				 !errors.isEmpty {
				config.secondaryText = .localize("Failed to load")
				config.secondaryTextProperties.color = .systemRed
			} else {
				config.secondaryText = source.uri.displayString
				config.secondaryTextProperties.color = .secondaryLabel
			}
		} else {
			config.text = .localize("All Packages")
			config.secondaryText = .localize("Browse packages from all sources.")

			config.image = UIImage(named: "zebra.wrench")
			config.imageProperties.preferredSymbolConfiguration = .init(scale: .large)
			config.imageProperties.tintColor = .secondaryLabel
			config.imageProperties.reservedLayoutSize = CGSize(width: 40, height: 40)
		}

		self.accessories = accessories
		self.contentConfiguration = config
	}

	@objc private func progressDidChange() {
		guard let source = source else {
			return
		}

		let state = SourceRefreshController.shared.sourceStates[source.uuid]
		DispatchQueue.main.async {
			self.sourceState = state
		}
	}

}

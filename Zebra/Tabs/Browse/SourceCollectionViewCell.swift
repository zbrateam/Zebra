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
		didSet { updateSource() }
	}

	private let progressView = ProgressDonut()

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

	private func updateSource() {
		var config = UIListContentConfiguration.zebraSubtitleCell()
		var accessories: [UICellAccessory] = [.disclosureIndicator()]

		if let source = source {
			config.text = source.origin
			niceSourceURL = source.uri.displayString

			if let host = source.uri.host,
				 let image = UIImage(named: "Repo Icons/\(host)") {
				accessories += [.iconImageView(url: nil, fallbackImage: image, width: 40)]
			} else {
				accessories += [.iconImageView(url: source.iconURL, usingScale: true, width: 40)]
			}

			accessories += [
				.customView(configuration: .init(customView: progressView,
																				 placement: .trailing(),
																				 reservedLayoutWidth: .actual,
																				 maintainsFixedSize: true))
			]

			self.contentConfiguration = config
			let state = SourceRefreshController.shared.sourceStates[source.uuid]
			updateProgress(state: state)
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

	private func updateProgress(state: SourceRefreshController.SourceState?) {
		guard source != nil else {
			return
		}

		if SourceRefreshController.shared.isRefreshing,
			 let progress = state?.progress {
			progressView.isHidden = false
			progressView.progress = progress.fractionCompleted
		} else {
			progressView.isHidden = true
		}

		if var config = contentConfiguration as? UIListContentConfiguration {
			if let errors = state?.errors,
				 !errors.isEmpty {
				config.secondaryText = .localize("Failed to load")
				config.secondaryTextProperties.color = .systemRed
			} else {
				config.secondaryText = niceSourceURL
				config.secondaryTextProperties.color = .secondaryLabel
			}
			contentConfiguration = config
		}
	}

	@objc private func progressDidChange() {
		guard let source = source else {
			return
		}
		let state = SourceRefreshController.shared.sourceStates[source.uuid]
		DispatchQueue.main.async {
			self.updateProgress(state: state)
		}
	}

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}

}

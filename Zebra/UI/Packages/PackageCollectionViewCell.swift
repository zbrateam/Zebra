//
//  PackageCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 1/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Plains

class PackageCollectionViewCell: UICollectionViewListCell {

	enum SubtitleType {
		case description, source
	}

	var package: Package? {
		didSet { setNeedsUpdateConfiguration() }
	}
	var subtitleType: SubtitleType = .description {
		didSet { setNeedsUpdateConfiguration() }
	}

	private var imageView: IconImageView!
	private var symbolImageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var tertiaryLabel: UILabel!
	private var tertiary: UILabel!

	override init(frame: CGRect) {
		super.init(frame: frame)

		let imageContainer = UIView()
		imageContainer.translatesAutoresizingMaskIntoConstraints = false

		imageView = IconImageView()
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageContainer.addSubview(imageView)

		symbolImageView = UIImageView()
		symbolImageView.translatesAutoresizingMaskIntoConstraints = false
		symbolImageView.contentMode = .scaleAspectFit
		symbolImageView.tintColor = .secondaryLabel
		imageContainer.addSubview(symbolImageView)

		titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.textColor = .label

		detailLabel = UILabel()
		detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .medium)
		detailLabel.textColor = .secondaryLabel

		tertiaryLabel = UILabel()
		tertiaryLabel.font = UIFont.preferredFont(forTextStyle: .footnote, weight: .regular)
		tertiaryLabel.textColor = .secondaryLabel

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel, tertiaryLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		let mainStackView = UIStackView(arrangedSubviews: [imageContainer, labelStackView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 10
		contentView.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
			mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
			mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
			mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),

			imageView.widthAnchor.constraint(equalToConstant: 60),
			imageView.heightAnchor.constraint(equalToConstant: 60),

			symbolImageView.widthAnchor.constraint(equalToConstant: 30),
			symbolImageView.heightAnchor.constraint(equalToConstant: 30),
			symbolImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
			symbolImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		package = nil
		super.prepareForReuse()
	}

	override func updateConfiguration(using state: UICellConfigurationState) {
		super.updateConfiguration(using: state)
		
		guard let package = package else {
			return
		}

		imageView.setImageURL(package.iconURL,
													usingScale: false,
													fallbackImage: SectionIcon.icon(for: package.section))
		titleLabel.textColor = package.isCommercial ? tintColor : .label
		titleLabel.text = package.name
		detailLabel.text = package.author?.name ?? package.maintainer?.name ?? .localize("Unknown")

		switch subtitleType {
		case .description:
			tertiaryLabel.text = package.shortDescription ?? .localize("No Description")
			tertiaryLabel.textColor = .secondaryLabel

		case .source:
			tertiaryLabel.text = package.source?.origin ?? .localize("Locally Installed")
			tertiaryLabel.textColor = .tertiaryLabel
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()

		titleLabel.textColor = package?.isCommercial ?? false ? tintColor : .label
	}

}


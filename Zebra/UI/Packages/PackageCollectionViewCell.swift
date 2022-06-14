//
//  PackageCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 1/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Plains

class PackageCollectionViewCell: UICollectionViewCell {

	var package: Package! {
		didSet { updatePackage() }
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

		let footnoteFont = UIFont.preferredFont(forTextStyle: .footnote)

		detailLabel = UILabel()
		detailLabel.font = footnoteFont
		detailLabel.textColor = .secondaryLabel

		let tertiaryFontDescriptor = footnoteFont.fontDescriptor
			.addingAttributes([
				.traits: [
					.weight: UIFont.Weight.regular.rawValue
				] as [UIFontDescriptor.TraitKey: Any]
			])

		tertiaryLabel = UILabel()
		tertiaryLabel.font = UIFont(descriptor: tertiaryFontDescriptor, size: 0)
		tertiaryLabel.textColor = .tertiaryLabel

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel, tertiaryLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		let mainStackView = UIStackView(arrangedSubviews: [imageContainer, labelStackView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 12
		contentView.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
			mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

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

	private func updatePackage() {
		guard let package = package else {
			imageView.image = nil
			return
		}

		if let iconURL = package.iconURL,
			 ["http", "https", "file"].contains(iconURL.scheme) {
			imageView.setImageURL(iconURL, fallbackImage: SectionIcon.icon(for: package.section))
		} else {
			imageView.image = SectionIcon.icon(for: package.section)
		}

		titleLabel.textColor = package.isCommercial ? tintColor : .label
		titleLabel.text = package.name
		detailLabel.text = package.author?.name ?? package.maintainer?.name ?? .localize("Unknown")
		tertiaryLabel.text = package.source?.origin ?? .localize("Locally Installed")
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()

		titleLabel.textColor = package?.isCommercial ?? false ? tintColor : .label
	}

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}

}


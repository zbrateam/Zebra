//
//  SourceCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SourceCollectionViewCell: UICollectionViewCell {

	var source: PLSource! {
		didSet { updateSource() }
	}

	private var imageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false

		titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.textColor = .label

		detailLabel = UILabel()
		detailLabel.font = .preferredFont(forTextStyle: .footnote)
		detailLabel.textColor = .secondaryLabel

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
		chevronImageView.tintColor = .tertiaryLabel

		let mainStackView = UIStackView(arrangedSubviews: [imageView, labelStackView, chevronImageView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 12
		contentView.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
			mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

			imageView.widthAnchor.constraint(equalToConstant: 40),
			imageView.heightAnchor.constraint(equalToConstant: 40)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func updateSource() {
		titleLabel.text = [source?.origin, source?.uri.host, .localize("Untitled")]
			.first(where: { item in item?.isEmpty == false })!
		detailLabel.text = source?.uri.absoluteString
		imageView.sd_setImage(with: source?.iconURL)
	}

}

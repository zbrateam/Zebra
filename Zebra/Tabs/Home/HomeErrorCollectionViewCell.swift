//
//  HomeErrorCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 10/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class HomeErrorCollectionViewCell: UICollectionViewCell {

	private var titleLabel: UILabel!

	var text: String? {
		get { titleLabel.text }
		set { titleLabel.text = newValue }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		let effectView = UIToolbar()
		effectView.translatesAutoresizingMaskIntoConstraints = false
		effectView.setShadowImage(UIImage(), forToolbarPosition: .any)
		effectView.clipsToBounds = true
		effectView.layer.cornerRadius = 20
		effectView.layer.cornerCurve = .continuous
		contentView.addSubview(effectView)

		let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleAspectFit
		imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .headline)
		imageView.setContentHuggingPriority(.required, for: .horizontal)

		titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.font = .preferredFont(forTextStyle: .headline)
		titleLabel.numberOfLines = 0
		titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

		let bodyLabel = UILabel()
		bodyLabel.translatesAutoresizingMaskIntoConstraints = false
		bodyLabel.font = .preferredFont(forTextStyle: .footnote)
		bodyLabel.numberOfLines = 0
		bodyLabel.text = .localize("Tap for more information.")

		let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
		chevronImageView.tintColor = .tertiaryLabel
		let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
		chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium, scale: .small)

		let titleStackView = UIStackView(arrangedSubviews: [imageView, titleLabel])
		titleStackView.spacing = 4
		titleStackView.alignment = .firstBaseline

		let labelStackView = UIStackView(arrangedSubviews: [titleStackView, bodyLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		let mainStackView = UIStackView(arrangedSubviews: [labelStackView, chevronImageView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 12
		contentView.addSubview(mainStackView)

		NSLayoutConstraint.activate([
			effectView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15),
			effectView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15),
			effectView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
			effectView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),

			mainStackView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 15),
			mainStackView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -15),
			mainStackView.topAnchor.constraint(equalTo: effectView.topAnchor, constant: 10),
			mainStackView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor, constant: -10)
		])
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

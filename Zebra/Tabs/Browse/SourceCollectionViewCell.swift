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

	private var imageView: IconImageView!
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		imageView = IconImageView()
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
		if let url = source?.uri {
			var urlString = url.absoluteString
			if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
				urlString = urlString.replacingOccurrences(regex: "^https?://", with: "")
			}
			if urlString.last == "/" {
				urlString.removeLast()
			}
			detailLabel.text = urlString
		} else {
			detailLabel.text = nil
		}

		if let host = source?.uri.host,
			 let image = UIImage(named: "Repo Icons/\(host)") {
			imageView.imageURL = nil
			imageView.image = image
		} else {
			imageView.imageURL = source?.iconURL
		}

		let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
		let symbolConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium, scale: .small)
		if let messages = source?.messages,
			 !messages.isEmpty {
			titleLabel.text = .localize("Failed to load")
			titleLabel.textColor = .systemRed
			chevronImageView.image = UIImage(systemName: "exclamationmark.circle",
																			 withConfiguration: symbolConfig.configurationWithoutScale())
			chevronImageView.tintColor = .systemRed
		} else {
			titleLabel.text = source?.origin ?? .localize("Untitled")
			titleLabel.textColor = .label
			chevronImageView.image = UIImage(systemName: "chevron.right",
																			 withConfiguration: symbolConfig)
			chevronImageView.tintColor = .tertiaryLabel
		}
	}

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}

}

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
	private var symbolImageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailImageView: UIImageView!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!

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
		detailLabel.font = .preferredFont(forTextStyle: .footnote)
		detailLabel.textColor = .secondaryLabel

		detailImageView = UIImageView()
		detailImageView.translatesAutoresizingMaskIntoConstraints = false
		detailImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: detailLabel.font, scale: .small)
		detailImageView.tintColor = .secondaryLabel

		let detailStackView = UIStackView(arrangedSubviews: [detailImageView, detailLabel])
		detailStackView.spacing = 4
		detailStackView.alignment = .center

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailStackView])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.spacing = 3
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)

		chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
		chevronImageView.tintColor = .tertiaryLabel

		let pointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
		chevronImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium, scale: .small)

		let mainStackView = UIStackView(arrangedSubviews: [imageContainer, labelStackView, chevronImageView])
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
			imageView.heightAnchor.constraint(equalToConstant: 40),

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
		source = nil
		super.prepareForReuse()
	}

	private func updateSource() {
		if let source = source {
			let url = source.uri
			var urlString = url.absoluteString
			if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
				urlString = urlString.replacingOccurrences(regex: "^https?://", with: "")
			}
			if urlString.last == "/" {
				urlString.removeLast()
			}
			detailLabel.text = urlString

			if let host = source.uri.host,
				 let image = UIImage(named: "Repo Icons/\(host)") {
				imageView.imageURL = nil
				imageView.image = image
			} else {
				imageView.imageURL = source.iconURL
			}

			imageView.isHidden = false
			symbolImageView.isHidden = true

			if source.messages.isEmpty {
				titleLabel.text = source.origin
				titleLabel.textColor = .label
				detailImageView.image = UIImage(systemName: "lock.slash.fill")
				detailImageView.isHidden = url.scheme == "https"
			} else {
				titleLabel.text = .localize("Failed to load")
				titleLabel.textColor = .systemRed
				detailImageView.image = UIImage(systemName: "exclamationmark.circle")
				detailImageView.isHidden = false
			}
		} else {
			titleLabel.text = .localize("All Packages")
			detailLabel.text = .localize("Browse packages from all installed sources.")
			imageView.imageURL = nil
			imageView.isHidden = true
			symbolImageView.image = UIImage(named: "zebra.wrench")
			symbolImageView.isHidden = false
			detailImageView.isHidden = true
		}
	}

	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}

}

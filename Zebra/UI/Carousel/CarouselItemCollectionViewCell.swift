//
//  CarouselItemCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class CarouselItemCollectionViewCell: UICollectionViewCell {

	static let size = CGSize(width: 314, height: 175)

	var item: CarouselItem! {
		didSet { updateItem() }
	}

	private var imageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		imageView = UIImageView(frame: bounds)
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageView.backgroundColor = .tertiarySystemBackground
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 20
		imageView.layer.cornerCurve = .continuous
		imageView.layer.minificationFilter = .trilinear
		imageView.layer.magnificationFilter = .trilinear
		contentView.addSubview(imageView)

		let overlayView = UIView(frame: bounds)
		overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		overlayView.backgroundColor = .black.withAlphaComponent(0.1)
		overlayView.clipsToBounds = true
		overlayView.layer.cornerRadius = 20
		overlayView.layer.cornerCurve = .continuous
		contentView.addSubview(overlayView)

		titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .title2, weight: .bold)
		titleLabel.textColor = .white
		titleLabel.numberOfLines = 2

		detailLabel = UILabel()
		detailLabel.font = .preferredFont(forTextStyle: .subheadline, weight: .bold)
		detailLabel.textColor = UIColor(white: 163 / 255, alpha: 0.8)

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
		contentView.addSubview(labelStackView)

		NSLayoutConstraint.activate([
			labelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			labelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			labelStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

			imageView.widthAnchor.constraint(equalToConstant: 40),
			imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func updateItem() {
		titleLabel.text = item.title
		detailLabel.text = item.subtitle
		imageView.sd_setImage(with: item.imageURL)
	}

}

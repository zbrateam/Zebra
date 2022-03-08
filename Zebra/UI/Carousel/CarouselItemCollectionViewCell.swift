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

	var item: CarouselItem? {
		didSet { updateItem() }
	}

	private var imageView: UIImageView!
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!
	private var highlightView: UIView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		imageView = UIImageView(frame: bounds)
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageView.backgroundColor = .systemBackground
		imageView.contentMode = .scaleAspectFill
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = 20
		imageView.layer.cornerCurve = .continuous
		imageView.layer.minificationFilter = .trilinear
		imageView.layer.magnificationFilter = .trilinear
		imageView.sd_imageTransition = .fade(duration: 0.2)
		contentView.addSubview(imageView)

		let overlayView = GradientView(frame: bounds)
		overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		overlayView.colors = [
			.black.withAlphaComponent(0.15),
			.black.withAlphaComponent(0.25),
			.black.withAlphaComponent(0.45)
		]
		overlayView.clipsToBounds = true
		overlayView.layer.cornerRadius = 20
		overlayView.layer.cornerCurve = .continuous
		contentView.addSubview(overlayView)

		highlightView = UIView(frame: bounds)
		highlightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		highlightView.backgroundColor = .black.withAlphaComponent(0.4)
		highlightView.alpha = 0
		highlightView.clipsToBounds = true
		highlightView.layer.cornerRadius = 20
		highlightView.layer.cornerCurve = .continuous
		contentView.addSubview(highlightView)

		titleLabel = UILabel()
		titleLabel.font = .preferredFont(forTextStyle: .title2, weight: .bold)
		titleLabel.textColor = .white
		titleLabel.numberOfLines = 2
		titleLabel.layer.shadowColor = UIColor.black.cgColor
		titleLabel.layer.shadowOffset = .zero
		titleLabel.layer.shadowRadius = 3
		titleLabel.layer.shadowOpacity = 0.5

		detailLabel = UILabel()
		detailLabel.font = .preferredFont(forTextStyle: .subheadline, weight: .bold)
		detailLabel.textColor = UIColor(white: 0.9, alpha: 0.9)
		detailLabel.layer.shadowColor = UIColor.black.cgColor
		detailLabel.layer.shadowOffset = .zero
		detailLabel.layer.shadowRadius = 3
		detailLabel.layer.shadowOpacity = 0.5

		let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
		labelStackView.translatesAutoresizingMaskIntoConstraints = false
		labelStackView.axis = .vertical
		labelStackView.alignment = .leading
		labelStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
		contentView.addSubview(labelStackView)

		NSLayoutConstraint.activate([
			labelStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			labelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			labelStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		item = nil
		imageView.sd_cancelCurrentImageLoad()
		super.prepareForReuse()
	}

	private func updateItem() {
		titleLabel.text = item?.title
		detailLabel.text = item?.subtitle
		imageView.sd_setImage(with: item?.imageURL,
													placeholderImage: UIImage(named: "banner-fallback"),
													options: .delayPlaceholder,
													context: nil)
	}

	override var isHighlighted: Bool {
		didSet {
			if isHighlighted {
				highlightView.alpha = 1
			} else {
				UIView.animate(withDuration: 0.3) {
					self.highlightView.alpha = 0
				}
			}
		}
	}

}

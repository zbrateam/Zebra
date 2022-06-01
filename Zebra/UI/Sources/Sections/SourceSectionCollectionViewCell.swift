//
//  SourceSectionCollectionViewCell.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SourceSectionCollectionViewCell: UICollectionViewCell {
	var section: (name: String, count: Int)! {
        didSet { updateSection() }
    }
	var isSource = false

	private var imageView: IconImageView!
	private var symbolImageView: UIImageView!
    private var titleLabel: UILabel!
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

        let labelStackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
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
					imageView.widthAnchor.constraint(equalToConstant: 38),
					imageView.heightAnchor.constraint(equalToConstant: 38),

					symbolImageView.widthAnchor.constraint(equalToConstant: 28),
					symbolImageView.heightAnchor.constraint(equalToConstant: 28),
					symbolImageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
					symbolImageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        section = nil
        super.prepareForReuse()
    }

    private func updateSection() {
        if let (name, count) = section {
					titleLabel.text = .localize(name)
					detailLabel.text = NumberFormatter.localizedString(from: count as NSNumber, number: .none)
					imageView.image = SectionIcon.icon(for: name)
					imageView.isHidden = false
					symbolImageView.isHidden = true
        } else {
            titleLabel.text = .localize("All Packages")
					detailLabel.text = isSource ? .localize("Browse packages from this source.") : .localize("Browse packages from all installed sources.")
					imageView.isHidden = true
					symbolImageView.image = UIImage(named: "zebra.wrench")
					symbolImageView.isHidden = false
        }
        // TODO: Add "All Packages"
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemGray4 : nil
        }
    }
}

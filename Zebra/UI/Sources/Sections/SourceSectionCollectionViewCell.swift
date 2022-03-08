//
//  SourceSectionCollectionViewCell.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SourceSectionCollectionViewCell: UICollectionViewCell {
	var section: (String, NSNumber)! {
		didSet { updateSection() }
	}
	
	private var titleLabel: UILabel!
	private var detailLabel: UILabel!
	private var chevronImageView: UIImageView!
	
	override init(frame: CGRect) {
		super.init(frame: frame)

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
		
		let mainStackView = UIStackView(arrangedSubviews: [labelStackView, chevronImageView])
		mainStackView.translatesAutoresizingMaskIntoConstraints = false
		mainStackView.alignment = .center
		mainStackView.spacing = 12
		contentView.addSubview(mainStackView)
		
		NSLayoutConstraint.activate([
			mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
			mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
			mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
			mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
		])
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		section = nil
		super.prepareForReuse()
	}
	
	private func updateSection() {
		if let section = section {
			titleLabel.text = section.0
			detailLabel.text = section.1.stringValue
		} else {
			titleLabel.text = .localize("All Packages")
			detailLabel.text = .localize("Browse packages from this source.")
		}
		// TODO: Add "All Packages"
	}
	
	override var isHighlighted: Bool {
		didSet {
			backgroundColor = isHighlighted ? .systemGray4 : nil
		}
	}
}

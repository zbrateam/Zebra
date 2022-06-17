//
//  ErrorCollectionViewCell.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class ErrorCollectionViewCell: UICollectionViewCell {

	var error: PlainsError? {
		didSet { updateError() }
	}

	private var imageView: UIImageView!
	private var detailLabel: UITextView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		let font = UIFont.preferredFont(forTextStyle: .body)

		imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.contentMode = .scaleAspectFit
		imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: font, scale: .medium).multicolor
		imageView.setContentHuggingPriority(.required, for: .horizontal)
		imageView.setContentCompressionResistancePriority(.required, for: .horizontal)

		detailLabel = UITextView()
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.isScrollEnabled = false
		detailLabel.isEditable = false
		detailLabel.backgroundColor = .systemBackground
		detailLabel.font = font
		detailLabel.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
		detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

		let stackView = UIStackView(arrangedSubviews: [imageView, detailLabel])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.spacing = 2
		stackView.alignment = .firstBaseline
		contentView.addSubview(stackView)

		NSLayoutConstraint.activate([
			stackView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor, constant: 21),
			stackView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor, constant: -17),
			stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
			stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func prepareForReuse() {
		error = nil
		super.prepareForReuse()
	}

	private func updateError() {
		guard let error = error else {
			return
		}

		switch error.level {
		case .warning:
			imageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
			imageView.tintColor = .systemYellow

		case .error:
			imageView.image = UIImage(systemName: "xmark.octagon.fill")
			imageView.tintColor = .systemRed

		@unknown default:
			fatalError()
		}

		detailLabel.text = error.text
	}
}

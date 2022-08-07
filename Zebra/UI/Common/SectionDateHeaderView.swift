//
//  SectionDateHeaderView.swift
//  Zebra
//
//  Created by Adam Demasi on 6/7/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class SectionDateHeaderView: UICollectionReusableView, PinnableHeader {

	var title: String? {
		get { label.text }
		set { label.text = newValue }
	}

	var dateTitle: String? {
		get { dateLabel.text }
		set { dateLabel.text = newValue }
	}

	var isFirstItem = false {
		didSet { updateToolbar() }
	}

	var isPinned = false {
		didSet { updateToolbar() }
	}

	private var label: UILabel!
	private var toolbar: UIToolbar!
	private var dateLabel: UILabel!
	private var dateToolbar: UIToolbar!

	override init(frame: CGRect) {
		super.init(frame: frame)

		preservesSuperviewLayoutMargins = true

		toolbar = UIToolbar(frame: bounds)
		toolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		toolbar.delegate = self
		addSubview(toolbar)

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = UIFont.preferredFont(forTextStyle: .headline, scale: 1.1, minimumSize: 18, weight: .semibold)
		label.adjustsFontForContentSizeCategory = true
		label.textColor = .label

		let dateView = UIView()
		dateView.translatesAutoresizingMaskIntoConstraints = false
		dateView.clipsToBounds = true
		dateView.layer.cornerRadius = 5
		dateView.layer.cornerCurve = .continuous

		dateLabel = UILabel()
		dateLabel.translatesAutoresizingMaskIntoConstraints = false
		dateLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
		dateLabel.adjustsFontForContentSizeCategory = true
		dateLabel.textColor = .secondaryLabel
		dateView.addSubview(dateLabel)

		dateToolbar = UIToolbar(frame: bounds)
		dateToolbar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		dateView.addSubview(dateToolbar)

		let stackView = UIStackView(arrangedSubviews: [label, UIView(), dateView])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.spacing = 15
		stackView.alignment = .firstBaseline
		addSubview(stackView)

		NSLayoutConstraint.activate([
			self.heightAnchor.constraint(equalToConstant: 44),

			stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
			stackView.topAnchor.constraint(equalTo: self.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

			dateLabel.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: 8),
			dateLabel.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -8),
			dateLabel.topAnchor.constraint(equalTo: dateView.topAnchor, constant: 4),
			dateLabel.bottomAnchor.constraint(equalTo: dateView.bottomAnchor, constant: -4)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func updateToolbar() {
		toolbar.alpha = isPinned ? 1 : 0
		dateToolbar.alpha = isPinned ? 0 : 1
	}

}

extension SectionDateHeaderView: UIToolbarDelegate {
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		.top
	}
}

extension NSCollectionLayoutBoundarySupplementaryItem {
	static var dateHeader: NSCollectionLayoutBoundarySupplementaryItem {
		let item = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																															heightDimension: .estimated(52)),
																													 elementKind: "DateHeader",
																													 alignment: .top)
		item.pinToVisibleBounds = true
		item.zIndex = .max
		return item
	}
}

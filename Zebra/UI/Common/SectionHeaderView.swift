//
//  SectionHeaderView.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

protocol PinnableHeader {
	var isPinned: Bool { get set }
}

class SectionHeaderView: UICollectionReusableView, PinnableHeader {

	var title: String? {
		get { label.text }
		set { label.text = newValue }
	}

	var buttons: [SectionHeaderButton] = [] {
		didSet { updateButtons() }
	}

	var isPinned = false {
		didSet { updateToolbar() }
	}

	private var label: UILabel!
	private var buttonsStackView: UIStackView!
	private var toolbar: UIToolbar!

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

		buttonsStackView = UIStackView()
		buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
		buttonsStackView.spacing = 4

		let stackView = UIStackView(arrangedSubviews: [label, UIView(), buttonsStackView])
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.spacing = 15
		stackView.alignment = .center
		addSubview(stackView)

		NSLayoutConstraint.activate([
			self.heightAnchor.constraint(equalToConstant: 44),

			stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			stackView.topAnchor.constraint(equalTo: self.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func updateButtons() {
		for item in buttonsStackView.arrangedSubviews {
			item.removeFromSuperview()
			buttonsStackView.removeArrangedSubview(item)
		}
		for item in buttons {
			buttonsStackView.addSubview(item)
			buttonsStackView.addArrangedSubview(item)
		}
	}

	private func updateToolbar() {
		toolbar.alpha = isPinned ? 1 : 0
	}

}

extension SectionHeaderView: UIToolbarDelegate {
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		.top
	}
}

extension NSCollectionLayoutBoundarySupplementaryItem {
	static var header: NSCollectionLayoutBoundarySupplementaryItem {
		let item = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																															heightDimension: .estimated(44)),
																													 elementKind: "Header",
																													 alignment: .top)
		item.pinToVisibleBounds = true
		item.zIndex = .max
		return item
	}
}

//
//  SectionHeaderView.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SectionHeaderView: UICollectionReusableView {

	var title: String? {
		get { label.text }
		set { label.text = newValue }
	}

	var buttons: [SectionHeaderButton] = [] {
		didSet { updateButtons() }
	}

	private var label: UILabel!
	private var buttonsStackView: UIStackView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .preferredFont(forTextStyle: .headline)
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
			stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
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

}

extension NSCollectionLayoutBoundarySupplementaryItem {
	static var header: NSCollectionLayoutBoundarySupplementaryItem {
		let item = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																															heightDimension: .absolute(52)),
																													 elementKind: "Header",
																													 alignment: .top)
		item.pinToVisibleBounds = true
		item.zIndex = .max
		return item
	}
}

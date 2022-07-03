//
//  InfoFooterView.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class InfoFooterView: UICollectionReusableView {

	var text: String? {
		get { label.text }
		set { label.text = newValue }
	}

	private var label: UILabel!

	override init(frame: CGRect) {
		super.init(frame: frame)

		let textStyle: UIFont.TextStyle
		switch UIDevice.current.userInterfaceIdiom {
		case .mac: textStyle = .body
		default:   textStyle = .footnote
		}

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .preferredFont(forTextStyle: textStyle)
		label.textAlignment = .center
		label.textColor = .secondaryLabel
		addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
			label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
			label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor, constant: 10),
			label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor, constant: -14),
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

extension NSCollectionLayoutBoundarySupplementaryItem {
	static var infoFooter: NSCollectionLayoutBoundarySupplementaryItem {
		NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																									 heightDimension: .estimated(52)),
																								elementKind: "InfoFooter",
																								alignment: .bottom)
	}
}

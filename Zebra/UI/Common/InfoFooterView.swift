//
//  InfoFooterView.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class InfoFooterView: UICollectionReusableView {

	var title: String? {
		get { label.text }
		set { label.text = newValue }
	}

	private var label: UILabel!

	override init(frame: CGRect) {
		super.init(frame: frame)

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .preferredFont(forTextStyle: .title2, weight: .bold)
		label.textColor = .label

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
			label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
			label.topAnchor.constraint(equalTo: self.topAnchor, constant: 6),
			label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6),
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

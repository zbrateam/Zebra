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

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .preferredFont(forTextStyle: .footnote)
		label.textAlignment = .center
		label.textColor = .secondaryLabel
		addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
			label.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
			label.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
			label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -6),
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

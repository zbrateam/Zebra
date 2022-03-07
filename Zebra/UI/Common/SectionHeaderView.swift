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

		let effectView = UIToolbar()
		effectView.frame = bounds
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		addSubview(effectView)

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .preferredFont(forTextStyle: .title2, weight: .bold)
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
			stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 21),
			stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -21),
			stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 6),
			stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -6),
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

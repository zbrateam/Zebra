//
//  BadgeView.swift
//  Zebra
//
//  Created by Adam Demasi on 23/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class BadgeView: UIView {

	private var count = 0 {
		didSet { updateCount() }
	}

	private var circleView: UIView!
	private var label: UILabel!

	init(count: Int) {
		super.init(frame: .zero)

		circleView = UIView()
		circleView.translatesAutoresizingMaskIntoConstraints = false
		circleView.clipsToBounds = true
		addSubview(circleView)

		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
		label.textAlignment = .center
		label.textColor = .white
		addSubview(label)

		NSLayoutConstraint.activate([
			circleView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			circleView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			circleView.topAnchor.constraint(equalTo: self.topAnchor),
			circleView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
			circleView.widthAnchor.constraint(greaterThanOrEqualTo: circleView.heightAnchor),
			circleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),

			label.leadingAnchor.constraint(equalTo: circleView.leadingAnchor, constant: 2),
			label.trailingAnchor.constraint(equalTo: circleView.trailingAnchor, constant: -2),
			label.topAnchor.constraint(equalTo: circleView.topAnchor, constant: 4),
			label.bottomAnchor.constraint(equalTo: circleView.bottomAnchor, constant: -4)
		])

		self.count = count
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func updateCount() {
		isHidden = count == 0
		label.text = count > 99 ? "☃" : NumberFormatter.count.string(for: count)
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		circleView.layer.cornerRadius = circleView.frame.size.height / 2
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()

		circleView.backgroundColor = tintColor
	}

}

extension UICellAccessory {

	static func badge(count: Int) -> UICellAccessory {
		.customView(configuration: CustomViewConfiguration(customView: BadgeView(count: count),
																											 placement: .trailing(displayed: .always),
																											 isHidden: count == 0,
																											 tintColor: .badge))
	}

}

//
//  ProgressDonut.swift
//  Zebra
//
//  Created by Adam Demasi on 5/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class ProgressDonut: UIView {

	static let size = CGSize(width: 16, height: 16)
	static let lineWidth: CGFloat = 2

	var progress: Double = 0 {
		didSet { updateProgress() }
	}

	private var baseCircle: CAShapeLayer!
	private var progressCircle: CAShapeLayer!

	init() {
		super.init(frame: CGRect(origin: .zero, size: Self.size))

		let path = UIBezierPath(arcCenter: CGPoint(x: frame.size.width / 2,
																							 y: frame.size.height / 2),
														radius: (frame.size.width - Self.lineWidth) / 2,
														startAngle: .pi / -2,
														endAngle: 3 * .pi / 2,
														clockwise: true)

		baseCircle = CAShapeLayer()
		baseCircle.path = path.cgPath
		baseCircle.fillColor = UIColor.clear.cgColor
		baseCircle.lineWidth = Self.lineWidth
		layer.addSublayer(baseCircle)

		progressCircle = CAShapeLayer()
		progressCircle.path = path.cgPath
		progressCircle.fillColor = UIColor.clear.cgColor
		progressCircle.lineCap = .round
		progressCircle.lineWidth = Self.lineWidth
		progressCircle.strokeEnd = 0
		layer.addSublayer(progressCircle)

		updateColors()

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: frame.size.width),
			heightAnchor.constraint(equalToConstant: frame.size.height)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		baseCircle.frame = bounds
		progressCircle.frame = bounds
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		updateColors()
	}

	private func updateColors() {
		baseCircle.strokeColor = UIColor.tertiaryLabel.cgColor
		progressCircle.strokeColor = tintColor.cgColor
	}

	private func updateProgress() {
		progressCircle.strokeEnd = progress
	}

}

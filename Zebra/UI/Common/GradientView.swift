//
//  GradientView.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class GradientView: UIView {

	override class var layerClass: AnyClass { CAGradientLayer.self }

	var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

	var type: CAGradientLayerType {
		get { gradientLayer.type }
		set { gradientLayer.type = newValue }
	}

	var colors = [UIColor]() {
		didSet { updateColors() }
	}

	var locations: [CGFloat]? {
		get { gradientLayer.locations as? [CGFloat] }
		set { gradientLayer.locations = newValue as [NSNumber]? }
	}

	var startPoint: CGPoint {
		get { gradientLayer.startPoint }
		set { gradientLayer.startPoint = newValue }
	}

	var endPoint: CGPoint {
		get { gradientLayer.endPoint }
		set { gradientLayer.endPoint = newValue }
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		updateColors()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		updateColors()
	}

	private func updateColors() {
		gradientLayer.colors = colors.map { item in item.cgColor }
	}

}

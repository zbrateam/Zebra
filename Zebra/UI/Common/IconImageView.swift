//
//  IconImageView.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class IconImageView: UIView {

	var image: UIImage? {
		get { imageView.image }
		set {
			imageView.load(url: nil)
			imageView.image = newValue
		}
	}

	private var backgroundView: UIView!
	private var imageView: UIImageView!
	private var borderView: UIView!

	override init(frame: CGRect) {
		super.init(frame: frame)

		backgroundView = UIView(frame: bounds)
		backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		backgroundView.clipsToBounds = true
		backgroundView.backgroundColor = .secondarySystemBackground
		backgroundView.layer.cornerCurve = .continuous
		addSubview(backgroundView)

		imageView = UIImageView(frame: bounds)
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		imageView.layer.cornerCurve = .continuous
		imageView.layer.minificationFilter = .trilinear
		imageView.layer.magnificationFilter = .trilinear
		addSubview(imageView)

		borderView = UIView(frame: bounds)
		borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		borderView.clipsToBounds = true
		borderView.layer.borderColor = UIColor.separator.cgColor
		borderView.layer.cornerCurve = .continuous
		addSubview(borderView)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()

		let cornerRadius = (13 / 60) * frame.size.width
		backgroundView.layer.cornerRadius = cornerRadius
		imageView.layer.cornerRadius = cornerRadius
		borderView.layer.cornerRadius = cornerRadius
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		borderView.layer.borderWidth = 1 / (window?.screen.scale ?? 1)
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		borderView.layer.borderColor = UIColor.separator.cgColor
	}

	func setImageURL(_ url: URL?, usingScale: Bool = true, fallbackImage: UIImage? = nil) {
		imageView.load(url: url, usingScale: usingScale, fallbackImage: fallbackImage)
	}

}

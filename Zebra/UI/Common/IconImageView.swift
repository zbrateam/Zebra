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
		set { setImageURL(nil, usingScale: false, fallbackImage: newValue) }
	}

	private var currentImage: (url: URL?, usingScale: Bool, fallbackImage: UIImage?)?

	private var backgroundView: UIView!
	private var imageView: UIImageView!
	private var borderView: UIView!

	init() {
		super.init(frame: .zero)

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
		addSubview(imageView)

		borderView = UIView(frame: bounds)
		borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		borderView.clipsToBounds = true
		borderView.layer.borderColor = UIColor.separator.cgColor
		borderView.layer.cornerCurve = .continuous
		addSubview(borderView)

		NSLayoutConstraint.activate([
			self.widthAnchor.constraint(equalTo: self.heightAnchor)
		])
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

		if let (url, usingScale, fallbackImage) = currentImage {
			setImageURL(url, usingScale: usingScale, fallbackImage: fallbackImage)
		}
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
		currentImage = (url, usingScale, fallbackImage)
		imageView.load(url: url, usingScale: usingScale, fallbackImage: fallbackImage)
	}

}

extension UICellAccessory {

	static func iconImageView(url: URL?, usingScale: Bool = true, fallbackImage: UIImage? = nil, width: CGFloat = 29) -> UICellAccessory {
		let view = IconImageView()
		view.setImageURL(url, usingScale: usingScale, fallbackImage: fallbackImage)

		NSLayoutConstraint.activate([
			view.widthAnchor.constraint(equalToConstant: width),
			view.heightAnchor.constraint(equalToConstant: width)
		])

		return .customView(configuration: .init(customView: view,
																						placement: .leading(displayed: .always),
																						reservedLayoutWidth: .custom(width),
																						maintainsFixedSize: true))
	}

}


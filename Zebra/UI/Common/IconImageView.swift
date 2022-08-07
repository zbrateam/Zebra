//
//  IconImageView.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class IconImageView: UIView {

	var size: CGFloat = 29 {
		didSet { invalidateIntrinsicContentSize() }
	}

	private var backgroundView: UIView!
	private var imageView: WebImageView!
	private var borderView: UIView!

	init(size: CGFloat = 29) {
		super.init(frame: .zero)

		self.size = size

		backgroundView = UIView(frame: bounds)
		backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		backgroundView.clipsToBounds = true
		backgroundView.backgroundColor = .secondarySystemBackground
		backgroundView.layer.cornerCurve = .continuous
		addSubview(backgroundView)

		imageView = WebImageView(frame: bounds)
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

	override var intrinsicContentSize: CGSize {
		CGSize(width: size, height: size)
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

extension UICellAccessory {
	static func iconImageView(url: URL?,
														usingScale: Bool = true,
														fallbackImage: UIImage? = nil,
														width: CGFloat = 29,
														reservedLayoutWidth: LayoutDimension = .actual) -> UICellAccessory {
		let view = IconImageView(size: width)
		view.setImageURL(url, usingScale: usingScale, fallbackImage: fallbackImage)
		return .customView(configuration: .init(customView: view,
																						placement: .leading(),
																						reservedLayoutWidth: reservedLayoutWidth))
	}
}


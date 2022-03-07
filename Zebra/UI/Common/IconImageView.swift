//
//  IconImageView.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import SDWebImage

class IconImageView: UIView {

	var image: UIImage? {
		get { imageView.image }
		set { imageView.image = newValue }
	}
	var imageURL: URL? {
		didSet { updateImageURL() }
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
		imageView.sd_imageTransition = .fade(duration: 0.2)
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

		let cornerRadius = 0.2237 * frame.size.width
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

	private func updateImageURL() {
		guard let imageURL = imageURL,
					var url = URLComponents(url: imageURL, resolvingAgainstBaseURL: true) else {
			imageView.sd_setImage(with: nil)
			return
		}

		let scale = window?.screen.scale ?? UIScreen.main.scale
		if scale == 1 {
			imageView.sd_setImage(with: imageURL)
		} else {
			// Try native scale first, falling back to original url.
			var fileBaseName = (imageURL.lastPathComponent as NSString).deletingPathExtension
			fileBaseName = fileBaseName.replacingOccurrences(regex: "@\\d+x$", with: "")

			let numberFormatter = NumberFormatter()
			numberFormatter.maximumFractionDigits = 1

			var pathComponents = imageURL.pathComponents
			pathComponents.removeLast()
			pathComponents.append("\(fileBaseName)@\(numberFormatter.string(for: scale)!)x.\(imageURL.pathExtension)")
			url.path = pathComponents.joined(separator: "/")
			imageView.sd_setImage(with: url.url!) { image, _, _, _ in
				if image == nil {

					self.imageView.sd_setImage(with: imageURL)
				}
			}
		}
	}

}

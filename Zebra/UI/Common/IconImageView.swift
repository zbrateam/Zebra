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
		set {
			imageView.sd_cancelCurrentImageLoad()
			imageView.image = newValue
		}
	}
	var imageURL: URL? {
		didSet { updateImageURL() }
	}
	var fallbackImage: UIImage?

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

	func setImageURL(_ imageURL: URL, fallbackImage: UIImage? = nil) {
		self.fallbackImage = fallbackImage
		self.imageURL = imageURL
	}

	private func loadImage(url: URL, completion: SDExternalCompletionBlock? = nil) {
		imageView.sd_imageTransition = .fade(duration: 100)
		imageView.sd_setImage(with: url,
													placeholderImage: fallbackImage,
													options: [.delayPlaceholder, .decodeFirstFrameOnly, .scaleDownLargeImages],
													completed: completion)
	}

	private func updateImageURL() {
		imageView.sd_cancelCurrentImageLoad()

		guard let imageURL = imageURL,
					var url = URLComponents(url: imageURL, resolvingAgainstBaseURL: true) else {
			imageView.image = fallbackImage
			return
		}

		imageView.image = nil

		let scale = window?.screen.scale ?? UIScreen.main.scale
		if scale == 1 {
			loadImage(url: imageURL)
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
			loadImage(url: url.url!) { image, _, _, _ in
				if image == nil {
					// Fall back to original url.
					self.imageView.sd_setImage(with: imageURL)
				}
			}
		}
	}

}

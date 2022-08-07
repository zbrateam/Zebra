//
//  WebImageView.swift
//  Zebra
//
//  Created by Adam Demasi on 6/7/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class WebImageView: UIImageView {

	private var currentImage: (url: URL?, usingScale: Bool, fallbackImage: UIImage?)?

	private var frameObserver: NSKeyValueObservation!

	override init(frame: CGRect) {
		super.init(frame: frame)

		frameObserver = observe(\.frame, options: [.new, .old]) { _, change in
			if change.oldValue?.size != change.newValue?.size {
				self.reloadImage()
			}
		}
	}

	convenience init() {
		self.init(frame: .zero)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		reloadImage()
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		reloadImage()
	}

	override func load(url: URL?, usingScale: Bool = true, fallbackImage: UIImage? = nil) {
		if let currentImage = currentImage,
			 currentImage == (url, usingScale, fallbackImage) {
			return
		}
		currentImage = (url, usingScale, fallbackImage)
		reloadImage()
	}

	private func reloadImage() {
		if let (url, usingScale, fallbackImage) = currentImage {
			super.load(url: url, usingScale: usingScale, fallbackImage: fallbackImage)
		}
	}

}

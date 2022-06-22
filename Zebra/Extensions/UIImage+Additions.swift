//
//  UIImage+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 16/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {

	/// > Note: Wait till the image view has been laid out before calling this. If `frame.size == .zero`,
	/// > the image load will be skipped. Call this from `layoutSubviews` to ensure relayout as needed.
	func load(url: URL?, usingScale: Bool = false, fallbackImage: UIImage? = nil) {
		let scale = window?.screen.scale ?? UIScreen.main.scale
		var sources = [Kingfisher.Source]()

		if let url = url?.secureURL {
			// Scaled image
			if usingScale && scale != 1 {
				let fileBaseName = url
					.deletingPathExtension()
					.lastPathComponent
					.replacingOccurrences(regex: "@\\d+x$", with: "")

				let numberFormatter = NumberFormatter()
				numberFormatter.maximumFractionDigits = 1

				let scaledURL = url/".."/"\(fileBaseName)@\(numberFormatter.string(for: scale)!)x.\(url.pathExtension)"
				if scaledURL != url {
					sources += [.network(scaledURL)]
				}
			}

			// Originally supplied url
			sources += [.network(url)]
		}

		if sources.isEmpty || frame.size == .zero {
			kf.cancelDownloadTask()
			image = fallbackImage
			return
		}

		image = nil
		let primarySource = sources.removeFirst()
		kf.setImage(with: primarySource,
								placeholder: fallbackImage,
								options: [
									.keepCurrentImageWhileLoading,
									.processor(DownsamplingImageProcessor(size: frame.size)),
									.scaleFactor(scale),
									.alternativeSources(sources)
								])
	}

}

extension UIImage.SymbolConfiguration {

	var multicolor: Self {
		if #available(iOS 15, *) {
			return Self.preferringMulticolor().applying(self)
		}
		return self
	}

	func withHierarchicalColor(_ hierarchicalColor: UIColor) -> Self {
		if #available(iOS 15, *) {
			return Self(hierarchicalColor: hierarchicalColor).applying(self)
		}
		return self
	}

}

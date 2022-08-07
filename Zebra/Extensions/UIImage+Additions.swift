//
//  UIImage+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 16/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Kingfisher

typealias KingfisherTask = DownloadTask

extension UIImageView {

	fileprivate typealias Source = Kingfisher.Source

	private static func sources(url: URL?, scale: CGFloat) -> [Source] {
		var sources = [Source]()
		if let url = url?.secureURL {
			// Scaled image
			if scale != 1 {
				let fileBaseName = url
					.deletingPathExtension()
					.lastPathComponent
					.replacingOccurrences(regex: "@\\d+x$", with: "")

				let numberFormatter = NumberFormatter()
				numberFormatter.locale = Locale(identifier: "en_US_POSIX")
				numberFormatter.maximumFractionDigits = 1

				let scaledURL = url/".."/"\(fileBaseName)@\(numberFormatter.string(for: scale)!)x.\(url.pathExtension)"
				if scaledURL != url {
					sources += [.network(scaledURL)]
				}
			}

			// Originally supplied url
			sources += [.network(url)]
		}
		return sources
	}

	static func preload(url: URL?, usingScale: Bool = false, screen: UIScreen? = nil) -> DownloadTask? {
		var sources = Self.sources(url: url,
															 scale: usingScale ? screen?.scale ?? 1 : 1)
		if sources.isEmpty {
			return nil
		}

		let primarySource = sources.removeFirst()
		return KingfisherManager.shared.retrieveImage(with: primarySource,
																									options: [.alternativeSources(sources)],
																									completionHandler: nil)
	}

	/// > Note: Wait till the image view has been laid out before calling this. If `frame.size == .zero`,
	/// > the image load will be skipped. Call this from `layoutSubviews` to ensure relayout as needed.
	@objc func load(url: URL?, usingScale: Bool = false, fallbackImage: UIImage? = nil) {
		let scale = (window?.screen ?? .main).scale
		var sources = Self.sources(url: url, scale: usingScale ? scale : 1)
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

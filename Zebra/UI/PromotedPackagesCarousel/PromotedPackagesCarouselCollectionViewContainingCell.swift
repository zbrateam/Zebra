//
//  PromotedPackagesCarouselCollectionViewContainingCell.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class PromotedPackagesCarouselCollectionViewContainingCell: CarouselCollectionViewContainingCell {
	var bannerItems: [PromotedPackageBanner] {
		get { promotedViewController.bannerItems }
		set { promotedViewController.bannerItems = newValue }
	}

	var promotedViewController: PromotedPackagesCarouselViewController! {
		viewController as! PromotedPackagesCarouselViewController?
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		let effectView = UIToolbar()
		effectView.frame = bounds
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.setShadowImage(UIImage(), forToolbarPosition: .any)
		contentView.addSubview(effectView)

		viewController = PromotedPackagesCarouselViewController()
		promotedViewController.view.frame = bounds
		promotedViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentView.addSubview(promotedViewController.view)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

//
//  PromotedPackagesCarouselCollectionViewContainingCell.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class PromotedPackagesCarouselCollectionViewContainingCell: UICollectionViewCell {
	weak var parentViewController: UIViewController? {
		didSet {
			if let parentViewController = parentViewController {
				viewController.willMove(toParent: parentViewController)
				parentViewController.addChild(viewController)
			} else {
				viewController.didMove(toParent: nil)
			}
		}
	}
	
	var items: [PromotedPackageBanner] {
		get { viewController.items }
		set { viewController.items = newValue }
	}
	
	private(set) var viewController: PromotedPackagesCarouselViewController!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		let effectView = UIToolbar()
		effectView.frame = bounds
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.setShadowImage(UIImage(), forToolbarPosition: .any)
		contentView.addSubview(effectView)
		
		viewController = PromotedPackagesCarouselViewController()
		viewController.view.frame = bounds
		viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentView.addSubview(viewController.view)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

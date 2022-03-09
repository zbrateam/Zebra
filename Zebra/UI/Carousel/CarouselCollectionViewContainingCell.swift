//
//  CarouselCollectionViewContainingCell.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class CarouselCollectionViewContainingCell: UICollectionViewCell {

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

	var items: [CarouselItem] {
		get { viewController.items }
		set { viewController.items = newValue }
	}

	internal var viewController: CarouselViewController!

	override init(frame: CGRect) {
		super.init(frame: frame)

		let effectView = UIToolbar()
		effectView.frame = bounds
		effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		effectView.setShadowImage(UIImage(), forToolbarPosition: .any)
		contentView.addSubview(effectView)

		viewController = CarouselViewController()
		viewController.view.frame = bounds
		viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentView.addSubview(viewController.view)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}

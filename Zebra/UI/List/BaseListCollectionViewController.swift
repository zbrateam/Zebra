//
//  BaseListCollectionViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log
import UIKit

class BaseListCollectionViewController<Layout: UICollectionViewLayout>: UICollectionViewController {

	class func createLayout() -> Layout {
		fatalError("createLayout() not implemented")
	}

	var layout: Layout { collectionViewLayout as! Layout }

	internal init() {
		super.init(collectionViewLayout: Self.createLayout())
	}

	@available(*, unavailable)
	internal required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.standardAppearance = .withoutSeparator

		collectionView.backgroundColor = .systemBackground
		collectionView.alwaysBounceVertical = true
	}

}

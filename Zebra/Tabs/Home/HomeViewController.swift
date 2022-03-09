//
//  HomeViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class HomeViewController: ListCollectionViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Home")

#if !targetEnvironment(macCatalyst)
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(nil, action: #selector(RootViewController.refreshSources), for: .valueChanged)
		collectionView.refreshControl = refreshControl
#endif
	}

}

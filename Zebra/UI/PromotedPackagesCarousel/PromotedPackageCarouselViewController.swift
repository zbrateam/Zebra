//
//  PromotedPackageCarouselViewController.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class PromotedPackagesCarouselViewController: CarouselViewController {
	var bannerItems = [PromotedPackageBanner]() {
		didSet { updateState() }
	}

	override init() {
		super.init()
		errorText = .localize("Featured Unavailable")
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.register(PromotedPackageCarouselItemCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
	}

	override func updateState() {
		super.updateState()
		if !bannerItems.isEmpty {
			if isLoading {
				isLoading = false
			}
			if isError {
				isError = false
			}
			collectionView.reloadData()
		}
	}
}

extension PromotedPackagesCarouselViewController {
	override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
		return bannerItems.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PromotedPackageCarouselItemCollectionViewCell
		cell.bannerItem = bannerItems[indexPath.item]
		return cell
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = bannerItems[indexPath.item]
		if let foundPackage = PLPackageManager.shared.packages.first(where: { package in package.identifier == item.package }) {
			let controller = ZBPackageViewController(package: foundPackage)
			parent?.navigationController?.pushViewController(controller, animated: true)
		} else {
			// TODO: Put this somewhere more global
			let alertController = UIAlertController(title: .localize("Couldn’t open package because it wasn’t found in your installed sources."),
																							message: .localize("You may need to refresh sources to see this package."),
																							preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: .ok, style: .cancel, handler: nil))
			present(alertController, animated: true)
		}
	}
}

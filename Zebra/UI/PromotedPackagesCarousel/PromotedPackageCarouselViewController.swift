//
//  PromotedPackageCarouselViewController.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class PromotedPackagesCarouselViewController: CarouselViewController {

	var bannerItems = [PromotedPackageBanner]() {
		didSet { updateBannerItems() }
	}

	private var packages = [Package]()

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

	private func updateBannerItems() {
		let bannerItems = self.bannerItems

		Task.detached {
			let packages = bannerItems.map { PackageManager.shared.package(withIdentifier: $0.package) }
			let items = zip(bannerItems, packages).compactMap { item, package -> CarouselItem? in
				guard let package = package else {
					return nil
				}

				return CarouselItem(title: (item.displayText ?? true) ? item.title : "",
														subtitle: nil,
														url: package.depictionURL ?? package.homepageURL,
														imageURL: item.url)
			}

			await MainActor.run {
				if items.isEmpty && !self.isLoading {
					self.errorText = .localize("No Featured Packages")
					self.isError = true
				}
				self.packages = packages.compact()
				self.items = items
			}
		}
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

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = bannerItems[indexPath.item]
		Task.detached {
			if let viewController = await PackageMenuCommands.packageViewController(identifier: item.package, sender: self) {
				await self.parent?.navigationController?.pushViewController(viewController, animated: true)
			}
		}
	}

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		let package = packages[indexPath.item]
		let cell = collectionView.cellForItem(at: indexPath)!
		return PackageMenuCommands.contextMenuConfiguration(for: package,
																								 identifier: indexPath as NSCopying,
																								 viewController: self,
																								 sourceView: cell)
	}

}

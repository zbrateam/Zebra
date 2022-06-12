//
//  PackageListViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

enum PackageListSwipeActionStyle: Int {
	case text, icon
}

enum PackageListSort: Int {
	case alpha, date, installedSize
}

class PackageListViewController: ListCollectionViewController {

	enum Filter {
		case fixed(packages: [Package])
		case installed
		case section(source: Source?, section: String?)
		case search(query: String)
		case favorites
	}

	var filter: Filter = .fixed(packages: []) {
		didSet {
			if isVisible {
				updateFilter()
			}
		}
	}

	private let collation = UILocalizedIndexedCollation.current()

	private var packages = [Package]() {
		didSet { updatePackages() }
	}
	private var sectionIndexes = [Int]()

	private var isVisible = false

	convenience init(filter: Filter) {
		self.init()
		self.filter = filter
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize.height = 92

		collectionView.register(PackageCollectionViewCell.self, forCellWithReuseIdentifier: "PackageCell")

		let searchController = UISearchController()
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.searchBar.placeholder = .localize("Search")
		navigationItem.searchController = searchController
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		isVisible = true
		updateFilter()

		NotificationCenter.default.addObserver(self, selector: #selector(updateFilter), name: PackageManager.databaseDidRefreshNotification, object: nil)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		isVisible = false

		NotificationCenter.default.removeObserver(self, name: PackageManager.databaseDidRefreshNotification, object: nil)
	}

	@objc private func updateFilter() {
		Task {
			let title: String
			let packages: [Package]

			let maxRole = Preferences.roleFilter
			let roleFilter: (Package) -> Bool = { $0.role.rawValue <= maxRole.rawValue }

			switch filter {
			case .fixed(let fixedPackages):
				title = .localize("Packages")
				packages = fixedPackages

			case .installed:
				title = .localize("Installed")
				packages = await PackageManager.shared
					.fetchPackages {
						$0.isInstalled && $0.role.rawValue < PackageRole.cydia.rawValue
					}

			case .section(let source, let section):
				let filter: ((Package) -> Bool)?
				if let section = section {
					title = .localize(section)
					if let source = source {
						filter = { roleFilter($0) && $0.source == source && $0.section == section }
					} else {
						filter = { roleFilter($0) && $0.section == section }
					}
				} else if let source = source {
					title = source.origin
					filter = { roleFilter($0) && $0.source == source }
				} else {
					title = .localize("All Packages")
					filter = roleFilter
				}

				if let filter = filter {
					packages = await PackageManager.shared
						.fetchPackages(matchingFilter: filter)
				} else {
					packages = PackageManager.shared.packages
				}

			case .search(let query):
				title = .localize("Search")
				packages = await PackageManager.shared
					.fetchPackages {
						roleFilter($0) &&
						($0.identifier.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) ||
						$0.shortDescription.localizedCaseInsensitiveContains(query) ||
						($0.author?.name.localizedCaseInsensitiveContains(query) ?? false) ||
						($0.maintainer?.name.localizedCaseInsensitiveContains(query) ?? false))
					}

			case .favorites:
				title = .localize("Favorites")
				let favoritePackageIDs = Preferences.favoritePackages
				packages = await PackageManager.shared
					.fetchPackages(matchingFilter: { favoritePackageIDs.contains($0.identifier) })
			}

			let sortedPackages = collation.sortedArray(from: packages, collationStringSelector: #selector(getter: Package.name)) as! [Package]
			await MainActor.run {
				self.title = title
				navigationItem.searchController!.title = title
				self.packages = sortedPackages

				switch filter {
				case .search(_):
					navigationItem.hidesSearchBarWhenScrolling = false

				default:
					navigationItem.hidesSearchBarWhenScrolling = true
				}
			}
		}
	}

	private func updatePackages() {
		collectionView.performBatchUpdates {
			var sectionIndexes = Array(repeating: 0, count: collation.sectionTitles.count)
			for package in packages {
				let section = collation.section(for: package, collationStringSelector: #selector(getter: Package.name))
				sectionIndexes[section] += 1
			}
			var tally = 0
			for i in 0..<sectionIndexes.count {
				let count = sectionIndexes[i]
				sectionIndexes[i] = min(tally, packages.count - 1)
				tally += count
			}
			self.sectionIndexes = sectionIndexes
			collectionView.reloadData()
		}
	}

	// MARK: - Actions

	@objc private func openInSafari(_ sender: UICommand) {
		guard let index = sender.propertyList as? Int else {
			return
		}
		let package = packages[index]
		if let url = package.depictionURL ?? package.homepageURL {
			URLController.open(url: url, sender: self, webSchemesOnly: true)
		}
	}

	@objc private func sharePackage(_ sender: UICommand) {
		guard let index = sender.propertyList as? Int else {
			return
		}
		let package = packages[index]
		guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else {
			return
		}

		let text = String(format: .localize("%@ by %@"),
											package.name,
											package.author?.name ?? package.maintainer?.name ?? .localize("Unknown"))
		let url = package.depictionURL ?? package.homepageURL

		let viewController = UIActivityViewController(activityItems: [text, url as Any].compactMap { $0 },
																									applicationActivities: nil)
		viewController.popoverPresentationController?.sourceView = cell
		viewController.popoverPresentationController?.sourceRect = cell.bounds
		present(viewController, animated: true, completion: nil)
	}

}

extension PackageListViewController { // UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
	override func numberOfSections(in _: UICollectionView) -> Int {
		1
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		packages.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let package = packages[indexPath.item]
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PackageCell", for: indexPath) as! PackageCollectionViewCell
		cell.package = package
		return cell
	}

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		let package = packages[indexPath.item]
		return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
			PackageViewController(package: package)
		}, actionProvider: { _ in
			var items = [UIMenuElement]()
			if (package.depictionURL ?? package.homepageURL) != nil {
				items += [
					UICommand(title: .openInBrowser,
										image: UIImage(systemName: "safari"),
										action: #selector(self.openInSafari),
										propertyList: indexPath.item)
				]
			}
			items += [
				UICommand(title: .share,
									image: UIImage(systemName: "square.and.arrow.up"),
									action: #selector(self.sharePackage),
									propertyList: indexPath.item)
			]
			return UIMenu(children: items)
		})
	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
//			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
//			view.title = indexOrder[indexPath.section]
//			view.buttons = []
//			return view
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Empty", for: indexPath)

		case UICollectionView.elementKindSectionFooter:
//			if indexPath.section != packagesByIndex.count - 1 {
//				return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Empty", for: indexPath)
//			}

			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! InfoFooterView
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .decimal
			let packageCount = packages.count
			view.text = String.localizedStringWithFormat(.localize("%@ Packages"),
																									 packageCount,
																									 numberFormatter.string(for: packageCount) ?? "0")
			return view

		default: fatalError()
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return .zero // CGSize(width: collectionView.frame.size.width, height: 52)
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
//		if section != packagesByIndex.count - 1 {
//			return .zero
//		}
		return CGSize(width: collectionView.frame.size.width, height: 52)
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let package = packages[indexPath.item]
		let viewController = PackageViewController(package: package)
		navigationController?.pushViewController(viewController, animated: true)
	}

	override func indexTitles(for _: UICollectionView) -> [String]? {
		return packages.isEmpty || sectionIndexes.isEmpty ? nil : collation.sectionIndexTitles
	}

	override func collectionView(_: UICollectionView, indexPathForIndexTitle _: String, at index: Int) -> IndexPath {
		if packages.isEmpty || sectionIndexes.isEmpty {
			return IndexPath(item: 0, section: 0)
		}
		let section = collation.section(forSectionIndexTitle: index)
		if section >= sectionIndexes.count {
			return IndexPath(item: 0, section: 0)
		}
		return IndexPath(item: sectionIndexes[section], section: 0)
	}

}

extension PackageListViewController: UISearchControllerDelegate, UISearchResultsUpdating {

	func willPresentSearchController(_ searchController: UISearchController) {
		collectionView.indexDisplayMode = .alwaysHidden
	}

	func willDismissSearchController(_ searchController: UISearchController) {
		collectionView.indexDisplayMode = .automatic
	}

	func updateSearchResults(for searchController: UISearchController) {

	}

}

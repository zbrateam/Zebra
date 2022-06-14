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

enum PackageListSort: Int, CaseIterable {
	case alpha, date, installedSize

	var title: String {
		switch self {
		case .alpha:         return .localize("Name")
		case .date:          return .localize("Recent")
		case .installedSize: return .localize("Size")
		}
	}
}

enum PackageListSortOrder {
	case ascending, descending

	var icon: UIImage? {
		switch self {
		case .ascending:  return UIImage(systemName: "chevron.up")
		case .descending: return UIImage(systemName: "chevron.down")
		}
	}

	mutating func toggle() {
		self = self == .ascending ? .descending : .ascending
	}
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
	private var filteredCount = 0

	private var isVisible = false

	private var sortButton: SectionHeaderButton!
	private var sortOrder = PackageListSortOrder.ascending

	convenience init(filter: Filter) {
		self.init()
		self.filter = filter
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize.height = 80

		collectionView.register(PackageCollectionViewCell.self, forCellWithReuseIdentifier: "PackageCell")

		let searchController = UISearchController()
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.searchBar.placeholder = .localize("Search")
		navigationItem.searchController = searchController

		sortButton = SectionHeaderButton(title: .localize("Sort"), image: UIImage(systemName: "line.3.horizontal.decrease"))
		sortButton.showsMenuAsPrimaryAction = true
		if #available(iOS 15, *) {
			sortButton.menu = UIMenu(options: .singleSelection, children: [])
		} else {
			sortButton.menu = UIMenu(children: [])
		}
		updateSortMenu()
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
			var filteredCount = 0
			let roleFilter: (Package) -> Bool = {
				if $0.role.rawValue <= maxRole.rawValue {
					return true
				}
				if $0.role != .cydia {
					filteredCount += 1
				}
				return false
			}

			switch filter {
			case .fixed(let fixedPackages):
				title = .localize("Packages")
				packages = fixedPackages

			case .installed:
				title = .localize("Installed")
				packages = await PackageManager.shared
					.fetchPackages { $0.isInstalled && $0.role.rawValue < PackageRole.cydia.rawValue }

			case .section(let source, let section):
				let filter: ((Package) -> Bool)?
				if let section = section {
					title = .localize(section)
					if let source = source {
						filter = { $0.source == source && $0.section == section && roleFilter($0) }
					} else {
						filter = { $0.section == section && roleFilter($0) }
					}
				} else if let source = source {
					title = source.origin
					filter = { $0.source == source && roleFilter($0) }
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
						($0.identifier.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) ||
						$0.shortDescription.localizedCaseInsensitiveContains(query) ||
						($0.author?.name.localizedCaseInsensitiveContains(query) ?? false) ||
						($0.maintainer?.name.localizedCaseInsensitiveContains(query) ?? false)) &&
						roleFilter($0)
					}

			case .favorites:
				title = .localize("Favorites")
				let favoritePackageIDs = Preferences.favoritePackages
				packages = await PackageManager.shared
					.fetchPackages(matchingFilter: { favoritePackageIDs.contains($0.identifier) })
			}

			// Yeah I couldn’t get something cleaner to work with KeyPath without Swift arguing with me
			let sort = Preferences.packageListSort
			let ascending = sortOrder == .ascending
			let sortedPackages = packages.sorted {
				switch sort {
				case .alpha:
					let order = $0.name.localizedStandardCompare($1.name)
					return order == (ascending ? .orderedAscending : .orderedDescending)

				case .date:
					return ascending
						? $0.installedDate ?? .distantPast < $1.installedDate ?? .distantPast
						: $0.installedDate ?? .distantPast > $1.installedDate ?? .distantPast

				case .installedSize:
					return ascending
						? $0.installedSize < $1.installedSize
						: $0.installedSize > $1.installedSize
				}
			}

			await MainActor.run {
				self.title = title
				navigationItem.searchController!.title = title
				self.filteredCount = filteredCount
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
		UIView.performWithoutAnimation {
			collectionView.performBatchUpdates {
				switch Preferences.packageListSort {
				case .alpha:
					var sectionIndexes = Array(repeating: 0, count: self.collation.sectionTitles.count)
					for package in self.packages {
						let section = self.collation.section(for: package, collationStringSelector: #selector(getter: Package.name))
						sectionIndexes[section] += 1
					}
					var tally = 0
					for i in 0..<sectionIndexes.count {
						let count = sectionIndexes[i]
						sectionIndexes[i] = min(tally, self.packages.count - 1)
						tally += count
					}
					self.sectionIndexes = sectionIndexes

				case .installedSize, .date:
					self.sectionIndexes = []
				}

				collectionView.reloadSections([0])
				collectionView.indexDisplayMode = sectionIndexes.isEmpty ? .alwaysHidden : .automatic
			}
		}
	}

	private func updateSortMenu() {
		let currentSort = Preferences.packageListSort

		var items = [UIMenuElement]()
		for item in PackageListSort.allCases {
			let icon = currentSort == item ? sortOrder.icon : nil
			items.append(UICommand(title: item.title,
														 image: icon,
														 action: #selector(self.changeSortOrder),
														 propertyList: item.rawValue,
														 attributes: [],
														 state: currentSort == item ? .on : .off)
			)
		}
		sortButton.menu = sortButton.menu!.replacingChildren(items)
	}

	// MARK: - Actions

	@objc private func changeSortOrder(_ sender: UICommand) {
		let currentSort = Preferences.packageListSort
		let newSort = PackageListSort(rawValue: sender.propertyList as! Int)!
		if currentSort == newSort {
			sortOrder.toggle()
		} else {
			Preferences.packageListSort = newSort
			sortOrder = .ascending
		}
		updateSortMenu()
		updateFilter()
	}

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
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
			view.title = .localize("Packages")
			view.buttons = [sortButton]
			return view

		case UICollectionView.elementKindSectionFooter:
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! InfoFooterView
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .decimal
			let packageText = String.localizedStringWithFormat(.localize("%@ Packages"),
																												 packages.count,
																												 numberFormatter.string(for: packages.count) ?? "0")
			let filteredText = filteredCount == 0 ? "" : " (\(String(format: .localize("%@ hidden"), numberFormatter.string(for: filteredCount) ?? "0")))"
			view.text = packageText + filteredText
			return view

		default: fatalError()
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		return CGSize(width: collectionView.frame.size.width, height: 52)
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
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
		collectionView.indexDisplayMode = sectionIndexes.isEmpty ? .alwaysHidden : .automatic
	}

	func updateSearchResults(for searchController: UISearchController) {

	}

}

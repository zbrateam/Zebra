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

fileprivate class PackageListDataSource: UICollectionViewDiffableDataSource<Int, Package> {

	var collation: UILocalizedIndexedCollation!
	var sectionIndexes = [Int]()

	override func indexTitles(for _: UICollectionView) -> [String]? {
		return sectionIndexes.isEmpty ? nil : collation.sectionIndexTitles
	}

	override func collectionView(_: UICollectionView, indexPathForIndexTitle _: String, at index: Int) -> IndexPath {
		if sectionIndexes.isEmpty {
			return IndexPath(item: 0, section: 0)
		}
		let section = collation.section(forSectionIndexTitle: index)
		if section >= sectionIndexes.count {
			return IndexPath(item: 0, section: 0)
		}
		return IndexPath(item: sectionIndexes[section], section: 0)
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

	private static let superHiddenPackages = ["base", "essential"]

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
	private var filteredCount = 0

	private var isVisible = false

	private var sortButton: SectionHeaderButton!
	private var sortOrder = PackageListSortOrder.ascending

	private var dataSource: PackageListDataSource!

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { _, environment in
			let section = NSCollectionLayoutSection(group: .listGrid(environment: environment,
																															 heightDimension: .estimated(80)))
			section.boundarySupplementaryItems = [.header, .infoFooter]
			return section
		}
	}

	convenience init(filter: Filter) {
		self.init()
		self.filter = filter
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.register(PackageCollectionViewCell.self, forCellWithReuseIdentifier: "PackageCell")

		let searchController = UISearchController()
		searchController.delegate = self
		searchController.searchResultsUpdater = self
		searchController.searchBar.placeholder = .localize("Search")
		navigationItem.searchController = searchController

		sortButton = SectionHeaderButton(title: .localize("Sort"), image: UIImage(systemName: "line.3.horizontal.decrease"))
		sortButton.showsMenuAsPrimaryAction = true
		sortButton.menu = UIMenu(children: [])
		updateSortMenu()

		dataSource = PackageListDataSource(collectionView: collectionView) { collectionView, indexPath, package in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PackageCell", for: indexPath) as! PackageCollectionViewCell
			cell.package = package
			return cell
		}
		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case "Header":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				view.title = .localize("Packages")
				view.buttons = [self.sortButton]
				return view

			case "InfoFooter":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "InfoFooter", for: indexPath) as! InfoFooterView
				let numberFormatter = NumberFormatter()
				numberFormatter.numberStyle = .decimal
				let packageText = String.localizedStringWithFormat(.localize("%@ Packages"),
																													 self.packages.count,
																													 numberFormatter.string(for: self.packages.count) ?? "0")
				let filteredText = self.filteredCount == 0 ? "" : " (\(String(format: .localize("%@ hidden"), numberFormatter.string(for: self.filteredCount) ?? "0")))"
				view.text = packageText + filteredText
				return view

			default: fatalError()
			}
		}
		dataSource.collation = collation
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
		let filter = self.filter
		let sortOrder = self.sortOrder

		Task.detached(priority: .userInitiated) {
			let title: String
			let packages: [Package]

			let maxRole = Preferences.roleFilter
			var filteredCount = 0
			let roleFilter: (Package) -> Bool = { package in
				if Self.superHiddenPackages.contains(package.identifier) {
					return false
				}
				if package.role.rawValue <= maxRole.rawValue {
					return true
				}
				if package.role != .cydia {
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

			let finalFilteredCount = filteredCount
			await MainActor.run {
				self.title = title
				self.navigationItem.searchController!.title = title
				self.filteredCount = finalFilteredCount
				self.packages = sortedPackages

				switch filter {
				case .search(_):
					self.navigationItem.hidesSearchBarWhenScrolling = false

				default:
					self.navigationItem.hidesSearchBarWhenScrolling = true
				}
			}
		}
	}

	private func updatePackages() {
		let packages = self.packages

		Task.detached(priority: .userInitiated) {
			var sectionIndexes = [Int]()

			switch await self.traitCollection.horizontalSizeClass {
			case .compact:
				switch Preferences.packageListSort {
				case .alpha:
					sectionIndexes = await Array(repeating: 0, count: self.collation.sectionTitles.count)
					for package in packages {
						let section = await self.collation.section(for: package, collationStringSelector: #selector(getter: Package.name))
						sectionIndexes[section] += 1
					}
					var tally = 0
					for i in 0..<sectionIndexes.count {
						let count = sectionIndexes[i]
						sectionIndexes[i] = min(tally, packages.count - 1)
						tally += count
					}

				case .installedSize, .date:
					break
				}

			case .regular, .unspecified:
				break

			@unknown default:
				break
			}

			var snapshot = NSDiffableDataSourceSnapshot<Int, Package>()
			snapshot.appendSections([0])
			snapshot.appendItems(packages)

			let finalSectionIndexes = sectionIndexes
			await MainActor.run {
				self.dataSource.sectionIndexes = packages.isEmpty ? [] : finalSectionIndexes
				self.collectionView.indexDisplayMode = finalSectionIndexes.isEmpty ? .alwaysHidden : .automatic
			}
			await self.dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
		}
	}

	private func updateSortMenu() {
		let currentSort = Preferences.packageListSort

		var singleSelection = UIMenu.Options()
		if #available(iOS 15, *) {
			singleSelection = .singleSelection
		}

		let sortMenu = UIMenu(title: .localize("Sort"),
													options: singleSelection.union(.displayInline),
													children: PackageListSort.allCases.map { item in
			let icon = currentSort == item ? sortOrder.icon : nil
			return UIAction(title: item.title,
											image: icon,
											state: currentSort == item ? .on : .off) { _ in
				self.changeSortOrder(item)
			}
		})
		sortButton.menu = sortButton.menu!.replacingChildren([sortMenu])
	}

	// MARK: - Actions

	private func changeSortOrder(_ newSort: PackageListSort) {
		let currentSort = Preferences.packageListSort
		if currentSort == newSort {
			sortOrder.toggle()
		} else {
			Preferences.packageListSort = newSort
			sortOrder = .ascending
		}
		updateSortMenu()
		updateFilter()
	}

}

extension PackageListViewController { // UICollectionViewDelegate

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		let package = packages[indexPath.item]
		let cell = collectionView.cellForItem(at: indexPath)!
		return PackageMenuCommands.contextMenuConfiguration(for: package,
																												identifier: indexPath as NSCopying,
																												viewController: self,
																												sourceView: cell)
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let package = packages[indexPath.item]
		let viewController = PackageViewController(package: package)
		navigationController?.pushViewController(viewController, animated: true)
	}

}

extension PackageListViewController: UISearchControllerDelegate, UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		// TODO: Search!
	}

}

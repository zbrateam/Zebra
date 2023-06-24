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

	private var isLoading = false {
		didSet { updateLoading() }
	}

	private var isVisible = false

	private var loadingView: LoadingView!

	private var sortButton: SectionHeaderButton!
	private var sortOrder = PackageListSortOrder.ascending

	private var dataSource: PackageListDataSource!
	private var preloadTasks = [IndexPath: KingfisherTask]()

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { _, environment in
			let section = NSCollectionLayoutSection(group: .listGrid(environment: environment,
																															 heightDimension: .estimated(80)))
			section.contentInsetsReference = .none
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

		collectionView.prefetchDataSource = self
		collectionView.register(PackageCollectionViewCell.self, forCellWithReuseIdentifier: "PackageCell")

		loadingView = LoadingView()
		loadingView.translatesAutoresizingMaskIntoConstraints = false
		loadingView.isHidden = true
		view.addSubview(loadingView)

		NSLayoutConstraint.activate([
			loadingView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			loadingView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			loadingView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
			loadingView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
		])

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

			switch self.filter {
			case .installed:
				cell.subtitleType = .source

			default:
				cell.subtitleType = .description
			}

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
				let packageText = String.localizedStringWithFormat(.localize("%@ Packages"),
																													 self.packages.count,
																													 NumberFormatter.count.string(for: self.packages.count) ?? "0")
				let filteredText = self.filteredCount == 0 ? nil : String(format: .localize("(%@ hidden)"), NumberFormatter.count.string(for: self.filteredCount) ?? "0")
				view.text = [packageText, filteredText]
					.compact()
					.joined(separator: " ")
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

		let title: String

		switch filter {
		case .fixed(_):
			title = .localize("Packages")

		case .installed:
			title = .localize("Installed")

		case .section(let source, let section):
			if let section = section {
				title = .localize(section)
			} else if let source = source {
				title = source.origin
			} else {
				title = .localize("All Packages")
			}

		case .search(_):
			title = .localize("Search")

		case .favorites:
			title = .localize("Favorites")
		}

		self.title = title
		navigationItem.searchController!.title = title

		switch filter {
		case .search(_):
			navigationItem.hidesSearchBarWhenScrolling = false

		default:
			navigationItem.hidesSearchBarWhenScrolling = true
		}

		isLoading = true

		Task.detached(priority: .userInitiated) {
			let packages: [Package]

			let maxRole = Preferences.roleFilter
			var filteredCount = 0
			let alwaysFilter: (Package) -> Bool = { package in
				package.role.rawValue < PackageRole.cydia.rawValue &&
					!Self.superHiddenPackages.contains(package.identifier)
			}
			let roleFilter: (Package) -> Bool = { package in
				if !alwaysFilter(package) {
					return false
				}
				if package.role.rawValue > maxRole.rawValue {
					filteredCount += 1
					return false
				}
				return true
			}

			switch filter {
			case .fixed(let fixedPackages):
				packages = fixedPackages

			case .installed:
				packages = await PackageManager.shared
					.fetchPackages { $0.isInstalled && alwaysFilter($0) }

			case .section(let source, let section):
				let filter: ((Package) -> Bool)
				if let section = section {
					filter = { $0.section == section && roleFilter($0) }
				} else {
					filter = roleFilter
				}

				packages = await PackageManager.shared
					.fetchPackages(in: source, matchingFilter: filter)

			case .search(let query):
				packages = await PackageManager.shared
					.fetchPackages {
						($0.identifier.localizedCaseInsensitiveContains(query) || $0.name.localizedCaseInsensitiveContains(query) ||
						($0.shortDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
						($0.author?.name.localizedCaseInsensitiveContains(query) ?? false) ||
						($0.maintainer?.name.localizedCaseInsensitiveContains(query) ?? false)) &&
						roleFilter($0)
					}

			case .favorites:
				let favoritePackageIDs = Preferences.favoritePackages
				packages = await PackageManager.shared
					.fetchPackages { favoritePackageIDs.contains($0.identifier) && !alwaysFilter($0) }
			}

			let sortedPackages: [Package]
			switch Preferences.packageListSort {
			case .alpha:
				// TODO: I don’t see any reason this API needs to run on the main actor, file a radar?
				sortedPackages = await self.collation.sortedArray(from: packages, collationStringSelector: #selector(getter: Package.name)) as! [Package]

			case .date:
				sortedPackages = packages.sorted { $0.installedDate ?? .distantPast < $1.installedDate ?? .distantPast }

			case .installedSize:
				sortedPackages = packages.sorted { $0.installedSize < $1.installedSize }
			}

			await MainActor.run { [filteredCount] in
				self.filteredCount = filteredCount
				switch sortOrder {
				case .ascending:  self.packages = sortedPackages
				case .descending: self.packages = sortedPackages.reversed()
				}
				self.isLoading = false
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

			await MainActor.run { [sectionIndexes] in
				self.dataSource.sectionIndexes = packages.isEmpty ? [] : sectionIndexes
				self.collectionView.indexDisplayMode = sectionIndexes.isEmpty ? .alwaysHidden : .automatic
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

	private func updateLoading() {
		let isLoading = self.isLoading && packages.isEmpty
		loadingView.isHidden = !isLoading
		view.isUserInteractionEnabled = !isLoading
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

extension PackageListViewController: UICollectionViewDataSourcePrefetching { // UICollectionViewDelegate

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

	func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
			let item = packages[indexPath.item]
			preloadTasks[indexPath] = UIImageView.preload(url: item.iconURL,
																										screen: view.window?.screen ?? .main)
		}
	}

	func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		for indexPath in indexPaths {
			preloadTasks[indexPath]?.cancel()
			preloadTasks[indexPath] = nil
		}
	}

}

extension PackageListViewController: UISearchControllerDelegate, UISearchResultsUpdating {

	func updateSearchResults(for searchController: UISearchController) {
		// TODO: Search!
	}

}

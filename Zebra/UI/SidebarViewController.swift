//
//  MacSidebarViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class SidebarViewController: ListCollectionViewController {

	private typealias AppTab = RootViewController.AppTab

	private var dataSource: UICollectionViewDiffableDataSource<Int, AppTab>!
	private var cellRegistration: UICollectionViewDiffableDataSource<Int, AppTab>!

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { index, layoutEnvironment in
			#if targetEnvironment(macCatalyst)
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																												heightDimension: .estimated(36)),
																										 subitems: [NSCollectionLayoutItem(layoutSize: .full)])

			let section = NSCollectionLayoutSection(group: group)
			section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
			return section
			#else
			let configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
			let section = NSCollectionLayoutSection.list(using: configuration,
																									 layoutEnvironment: layoutEnvironment)
			return section
			#endif
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		#if targetEnvironment(macCatalyst)
		collectionView.backgroundColor = nil
		#else
		collectionView.backgroundColor = .secondarySystemBackground
		#endif

		clearsSelectionOnViewWillAppear = false

		let registration = UICollectionView.CellRegistration<UICollectionViewListCell, AppTab> { cell, indexPath, item in
			var config = UIListContentConfiguration.sidebarCell()
			config.text = item.name
			config.image = item.icon
			cell.contentConfiguration = config

			if let rootViewController = self.splitViewController as? RootViewController {
				cell.isSelected = rootViewController.currentTab == item
			}
		}

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
			collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
		})

		var snapshot = NSDiffableDataSourceSnapshot<Int, AppTab>()
		snapshot.appendSections([0])
		snapshot.appendItems(AppTab.allCases)
		dataSource.apply(snapshot)

		updateTabs()
	}

	private func updateTabs() {
		var snapshot = dataSource.snapshot()
		if #available(iOS 15, *) {
			snapshot.reconfigureItems(AppTab.allCases)
		} else {
			snapshot.reloadItems(AppTab.allCases)
		}
		dataSource.apply(snapshot, animatingDifferences: false)
	}

}

extension SidebarViewController { // UICollectionViewDelegate

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let rootViewController = splitViewController as! RootViewController
		rootViewController.selectTab(AppTab(rawValue: indexPath.row)!)
	}

}

extension SidebarViewController: RootViewControllerDelegate {

	func selectTab(_ tab: RootViewController.AppTab) {
		updateTabs()
	}

}

//
//  HomeViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class HomeViewController: ListCollectionViewController {

	private enum Section: Hashable {
		case featured
		case notice
		case packages(date: Date)
	}

	private enum Value: Hashable {
		case featured
		case notice(reason: NoticeReason)
		case package(package: Package)
	}

	private enum NoticeReason: Hashable {
		case sandboxed
		case refreshErrors(count: UInt)
	}

	private var errorCount: UInt = 0
	private var promotedPackages: [PromotedPackageBanner]?

	private var dataSource: UICollectionViewDiffableDataSource<Section, Value>!

	private var isVisible = false

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { index, environment in
			switch index {
			case 0:
				let section = NSCollectionLayoutSection(group: .oneAcross(heightDimension: .absolute(CarouselViewController.height)))
				section.contentInsetsReference = .none
				return section

			case 1:
				let section = NSCollectionLayoutSection(group: .oneAcross(heightDimension: .estimated(52)))
				section.interGroupSpacing = 15
				section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 0, bottom: 15, trailing: 0)
				section.contentInsetsReference = .none
				return section

			default:
				let section = NSCollectionLayoutSection(group: .listGrid(environment: environment,
																																 heightDimension: .estimated(80)))
				section.contentInsetsReference = .none
//				section.boundarySupplementaryItems = [.header]
				return section
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Home")

		collectionView.register(PromotedPackagesCarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")
		collectionView.register(HomeErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")

		#if !targetEnvironment(macCatalyst)
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshSources), for: .valueChanged)
		collectionView.refreshControl = refreshControl
		#endif

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, value in
			switch value {
			case .featured:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! PromotedPackagesCarouselCollectionViewContainingCell
				cell.parentViewController = self
				cell.bannerItems = self.promotedPackages ?? []
				return cell

			case .notice(let reason):
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! HomeErrorCollectionViewCell
				switch reason {
				case .sandboxed:
					cell.text = .localize("You’re using a sandboxed demo of Zebra.")

				case .refreshErrors(let count):
					cell.text = String.localizedStringWithFormat(.localize("Zebra encountered %@ errors."),
																											 count,
																											 NumberFormatter.count.string(for: count) ?? "0")
				}
				return cell

			case .package(let package):
				fatalError()
			}
		})

		NotificationCenter.default.addObserver(self, selector: #selector(refreshDidFinish), name: SourceRefreshController.refreshDidFinishNotification, object: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(refreshProgressDidChange), name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		update()
		refreshProgressDidChange()
		updatePromotedPackages()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
	}

	@objc private func refreshProgressDidChange() {
		// Filter to only errors. Warnings are mostly annoying and not particularly useful.
		errorCount = UInt(SourceRefreshController.shared.refreshErrors.count) + ErrorManager.shared.errorCount(at: .error)
		let percent = SourceRefreshController.shared.progress.fractionCompleted

		DispatchQueue.main.async {
			self.updateProgress(percent: percent)
		}
	}

	@objc private func refreshDidFinish() {
		promotedPackages = nil
		if isVisible {
			updatePromotedPackages()
		}
	}

	@objc private func refreshSources() {
		#if !targetEnvironment(macCatalyst)
		collectionView.refreshControl!.endRefreshing()
		#endif

		SourceRefreshController.shared.refresh()
	}

	private func update() {
		let showFeaturedCarousel = Preferences.showFeaturedCarousels
		navigationItem.scrollEdgeAppearance = showFeaturedCarousel ? .withoutSeparator : .transparent

		var snapshot = NSDiffableDataSourceSnapshot<Section, Value>()
		if showFeaturedCarousel {
			snapshot.appendSections([.featured])
			snapshot.appendItems([.featured])
		}
		snapshot.appendSections([.notice])
		dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
	}

	private func updateProgress(percent: Double) {
		navigationProgressBar?.setProgress(Float(percent), animated: true)

		var snapshot = dataSource.snapshot()
		snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .notice))
		if Device.isDemo {
			snapshot.appendItems([.notice(reason: .sandboxed)])
		}
		if errorCount > 0 {
			snapshot.appendItems([.notice(reason: .refreshErrors(count: errorCount))])
		}
		dataSource.apply(snapshot, animatingDifferences: false)
	}

	private func updatePromotedPackages() {
		if promotedPackages != nil {
			return
		}

		Task.detached {
			let promotedPackages = await PromotedPackagesFetcher.getHomeCarouselItems()

			await MainActor.run {
				self.promotedPackages = promotedPackages

				var snapshot = self.dataSource.snapshot()
				if #available(iOS 15, *) {
					snapshot.reconfigureItems([.featured])
				} else {
					snapshot.reloadItems([.featured])
				}
				self.dataSource.apply(snapshot, animatingDifferences: true)
			}
		}
	}

}

extension HomeViewController {

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let item = dataSource.itemIdentifier(for: indexPath) else {
			return
		}

		switch item {
		case .notice(let reason):
			switch reason {
			case .sandboxed:
				// TODO: Display sandboxed.json
				break

			case .refreshErrors(_):
				let viewController = ErrorsViewController()
				navigationController?.pushViewController(viewController, animated: true)
			}

		case .featured:
			break

		case .package(let package):
			break
		}
	}

}

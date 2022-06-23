//
//  BrowseViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log
import UIKit
import Plains

class BrowseViewController: ListCollectionViewController {

	private enum Section {
		case news, sources
	}

	private enum Value: Hashable {
		case news
		case source(source: Source?)

		func hash(into hasher: inout Hasher) {
			switch self {
			case .news:
				break
			case .source(let source):
				hasher.combine(source)
			}
		}
	}

	private var sources = [Source]()
	private var newsItems: [CarouselItem]? {
		didSet { carouselViewController?.items = newsItems ?? [] }
	}

	private var dataSource: UICollectionViewDiffableDataSource<Section, Value>!

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { index, environment in
			switch index {
			case 0:
				return NSCollectionLayoutSection(group: .oneAcross(heightDimension: .absolute(CarouselViewController.height)))

			case 1:
				let section = NSCollectionLayoutSection(group: .listGrid(environment: environment,
																																 heightDimension: .estimated(57)))
				section.boundarySupplementaryItems = [.header, .infoFooter]
				return section

			default: fatalError()
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Browse")

		collectionView.register(SourceCollectionViewCell.self, forCellWithReuseIdentifier: "SourceCell")
		collectionView.register(CarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")

		#if !targetEnvironment(macCatalyst)
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshSources), for: .valueChanged)
		collectionView.refreshControl = refreshControl
		#endif

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, value in
			switch value {
			case .news:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! CarouselCollectionViewContainingCell
				cell.parentViewController = self
				cell.items = self.newsItems ?? []
				return cell

			case .source(let source):
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SourceCell", for: indexPath) as! SourceCollectionViewCell
				cell.source = source
				return cell
			}
		}
		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case "Header":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				view.title = .localize("Sources")
				view.buttons = [
					SectionHeaderButton(title: .localize("Export"),
															target: nil,
															action: #selector(RootViewController.exportSources)),
					SectionHeaderButton(title: .add,
															image: UIImage(systemName: "plus"),
															target: self,
															action: #selector(self.addSource)),
				]
				return view

			case "InfoFooter":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "InfoFooter", for: indexPath) as! InfoFooterView
				let numberFormatter = NumberFormatter()
				numberFormatter.numberStyle = .decimal
				let sourcesCount = self.sources.count
				let packageCount = PackageManager.shared.packages.count
				view.text = String(format: "%@ • %@",
													 String.localizedStringWithFormat(.localize("%@ Sources"),
																														sourcesCount,
																														numberFormatter.string(for: sourcesCount) ?? "0"),
													 String.localizedStringWithFormat(.localize("%@ Packages"),
																														packageCount,
																														numberFormatter.string(for: packageCount) ?? "0"))
				return view

			default: fatalError()
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		sourcesDidUpdate()

		NotificationCenter.default.addObserver(self, selector: #selector(sourcesDidUpdate), name: SourceManager.sourceListDidUpdateNotification, object: nil)

		if newsItems == nil {
			fetchNews()
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: SourceManager.sourceListDidUpdateNotification, object: nil)
	}

	// MARK: - Sources

	private func updateSources() {
		sources = SourceManager.shared.sources
			.sorted(by: { a, b in a.origin.localizedStandardCompare(b.origin) == .orderedAscending })

		var snapshot = NSDiffableDataSourceSnapshot<Section, Value>()
		if Preferences.showFeaturedCarousels {
			snapshot.appendSections([.news])
			snapshot.appendItems([.news], toSection: .news)
		}
		snapshot.appendSections([.sources])
		snapshot.appendItems([.source(source: nil)] + sources.map { .source(source: $0) }, toSection: .sources)
		dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
	}

	@objc private func sourcesDidUpdate() {
		DispatchQueue.main.async {
			self.updateSources()
		}
	}

	@objc private func refreshSources() {
		#if !targetEnvironment(macCatalyst)
		collectionView.refreshControl!.endRefreshing()
		#endif

		SourceRefreshController.shared.refresh()
	}

	@objc private func addSource(_: UIButton) {
		let viewController = NavigationController(rootViewController: ZBSourceAddViewController())
		present(viewController, animated: true)
	}

	@objc private func copySource(_ sender: UICommand) {
		let item = sources[sender.propertyList as! Int]
		UIPasteboard.general.string = item.uri.absoluteString
	}

	@objc private func shareSource(_ sender: UICommand) {
		let index = sender.propertyList as! Int
		guard let cell = collectionView.cellForItem(at: IndexPath(item: index + 1, section: 1)) else {
			return
		}
		let item = sources[index]
		let viewController = UIActivityViewController(activityItems: [item.uri], applicationActivities: nil)
		viewController.popoverPresentationController?.sourceView = cell
		viewController.popoverPresentationController?.sourceRect = cell.bounds
		present(viewController, animated: true, completion: nil)
	}

	@objc private func openSourceInSafari(_ sender: UICommand) {
		let item = sources[sender.propertyList as! Int]
		var url = URLComponents(url: item.uri, resolvingAgainstBaseURL: true)!
		url.path = "/"
		URLController.open(url: url.url!, sender: self, webSchemesOnly: true)
	}

	@objc private func removeSource(_ sender: UICommand) {
		let index = sender.propertyList as! Int
		remove(source: sources[index])
	}

	private func remove(source: Source) {
		let index = sources.firstIndex(of: source)
		SourceManager.shared.removeSource(source)
		if let index = index {
			collectionView.deleteItems(at: [IndexPath(item: index, section: 1)])
		} else {
			collectionView.reloadData()
		}
	}

	// MARK: - News

	private var carouselViewController: CarouselViewController? {
		if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? CarouselCollectionViewContainingCell {
			return cell.viewController
		}
		return nil
	}

	private func fetchNews() {
		Task.detached(priority: .medium) {
			do {
				if let cachedNews = RedditNewsFetcher.getCached() {
					await MainActor.run {
						self.newsItems = cachedNews
					}
				}

				let newsItems = try await RedditNewsFetcher.fetch()
				await MainActor.run {
					self.newsItems = newsItems
				}
			} catch {
				Logger().warning("Loading news failed: \(String(describing: error))")
				await MainActor.run {
					self.carouselViewController?.isError = true
				}
			}
		}
	}
}

extension BrowseViewController { // UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		switch indexPath.section {
		case 0:
			return nil

		case 1:
			if indexPath.item == 0 {
				return nil
			}
			let item = sources[indexPath.item - 1]
			return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil, actionProvider: { _ in
				UIMenu(children: [
					UICommand(title: .openInBrowser,
										image: UIImage(systemName: "safari"),
										action: #selector(self.openSourceInSafari),
										propertyList: indexPath.item - 1),
					UICommand(title: .copy,
										image: UIImage(systemName: "doc.on.doc"),
										action: #selector(self.copySource),
										propertyList: indexPath.item - 1),
					UICommand(title: .share,
										image: UIImage(systemName: "square.and.arrow.up"),
										action: #selector(self.shareSource),
										propertyList: indexPath.item - 1),
				] + (item.canRemove ? [
					UICommand(title: .delete,
										image: UIImage(systemName: "trash"),
										action: #selector(self.removeSource),
										propertyList: indexPath.item - 1,
										attributes: .destructive)
				] : []))
			})

		default:
			return nil
		}
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch indexPath.section {
		case 0: return

		case 1:
			let controller = SourceSectionsViewController(source: indexPath.item == 0 ? nil : sources[indexPath.item - 1])
			navigationController?.pushViewController(controller, animated: true)

		default: break
		}
	}

}

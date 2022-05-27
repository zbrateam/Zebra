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
	private var sources = [Source]()

	private var newsItems: [CarouselItem]?

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Browse")

		collectionView.register(SourceCollectionViewCell.self, forCellWithReuseIdentifier: "SourceCell")
		collectionView.register(CarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")

		#if !targetEnvironment(macCatalyst)
			let refreshControl = UIRefreshControl()
			refreshControl.addTarget(nil, action: #selector(RootViewController.refreshSources), for: .valueChanged)
			collectionView.refreshControl = refreshControl
		#endif
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

	@objc private func sourcesDidUpdate() {
		DispatchQueue.main.async {
			self.sources = SourceManager.shared.sources
				.sorted(by: { a, b in a.origin.localizedStandardCompare(b.origin) == .orderedAscending })
			self.collectionView.reloadData()

			#if !targetEnvironment(macCatalyst)
				self.collectionView.refreshControl?.endRefreshing()
			#endif
		}
	}

	@objc private func addSource(_: UIButton) {
		let viewController = UINavigationController(rootViewController: ZBSourceAddViewController())
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
		Task(priority: .medium) {
			do {
				if let cachedNews = RedditNewsFetcher.getCached() {
					newsItems = cachedNews
					await MainActor.run {
						self.carouselViewController?.items = cachedNews
					}
				}

				newsItems = try await RedditNewsFetcher.fetch()
				await MainActor.run {
					self.carouselViewController?.items = newsItems!
				}
			} catch {
				os_log("Loading news failed: %@", String(describing: error))
				await MainActor.run {
					self.carouselViewController?.isError = true
				}
			}
		}
	}
}

extension BrowseViewController { // UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
	private enum Section: Int, CaseIterable {
		case news, sources
	}

	override func numberOfSections(in _: UICollectionView) -> Int {
		Section.allCases.count
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch Section(rawValue: section)! {
		case .news: return ZBSettings.wantsCommunityNews() ? 1 : 0
		case .sources: return sources.count + 1
		}
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! CarouselCollectionViewContainingCell
			cell.parentViewController = self
			cell.items = newsItems ?? []
			return cell

		case .sources:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SourceCell", for: indexPath) as! SourceCollectionViewCell
			cell.source = indexPath.item == 0 ? nil : sources[indexPath.item - 1]
			return cell
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return CGSize(width: collectionView.frame.size.width, height: CarouselViewController.height)

		case .sources:
			return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		switch Section(rawValue: section)! {
		case .news:
			return .zero

		case .sources:
			return super.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
		}
	}

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return nil

		case .sources:
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
		}
	}

	override func collectionView(_: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return false

		case .sources:
			if indexPath.item == 0 {
				return false
			}
			let item = sources[indexPath.item - 1]
			return item.canRemove
		}
	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Empty", for: indexPath)

		case .sources:
			switch kind {
			case UICollectionView.elementKindSectionHeader:
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				view.title = .localize("Sources")
				view.buttons = [
					SectionHeaderButton(title: .localize("Export"),
										target: nil,
										action: #selector(RootViewController.exportSources)),
					SectionHeaderButton(title: .add,
										image: UIImage(systemName: "plus"),
										target: self,
										action: #selector(addSource)),
				]
				return view

			case UICollectionView.elementKindSectionFooter:
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath) as! InfoFooterView
				let numberFormatter = NumberFormatter()
				numberFormatter.numberStyle = .decimal
				let packageCount = PackageManager.shared.packages.count
				view.text = String(format: "%@ • %@",
													 String.localizedStringWithFormat(.localize("%@ Sources"),
																														NSDecimalNumber(value: sources.count),
																														numberFormatter.string(for: sources.count) ?? "0"),
													 String.localizedStringWithFormat(.localize("%@ Packages"),
																														NSDecimalNumber(value: packageCount),
																														numberFormatter.string(for: packageCount) ?? "0"))
				return view

			default: fatalError()
			}
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .news:
			return .zero

		case .sources:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .news:
			return .zero

		case .sources:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch Section(rawValue: indexPath.section) {
		case .news:
			return
		case .sources:
			if indexPath.item == 0 {
				let controller = ZBPackageListViewController(packages: PackageManager.shared.packages)
				controller.title = .localize("All Packages")
				navigationController?.pushViewController(controller, animated: true)
			} else {
				let controller = SourceSectionViewController(source: sources[indexPath.item - 1])
				navigationController?.pushViewController(controller, animated: true)
			}
			return
		case .none:
			fatalError("Something was selected that wasn't supposed to be")
		}
	}
}

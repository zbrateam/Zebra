//
//  BrowseViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import os.log

class BrowseViewController: ListCollectionViewController {

	private var sources = [PLSource]()

	private var newsItems: [CarouselItem]?

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Browse")

		collectionView.register(SourceCollectionViewCell.self, forCellWithReuseIdentifier: "SourceCell")
		collectionView.register(CarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		sourcesDidUpdate()

		NotificationCenter.default.addObserver(self, selector: #selector(sourcesDidUpdate), name: PLSourceManager.sourceListDidUpdateNotification, object: nil)

		if newsItems == nil {
			fetchNews()
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: PLSourceManager.sourceListDidUpdateNotification, object: nil)
	}

	// MARK: - Sources

	@objc private func sourcesDidUpdate() {
		sources = PLSourceManager.shared.sources
			.sorted(by: { a, b in a.label < b.label })
		collectionView.reloadData()
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
				let news = try await RedditNewsFetcher.fetch()
				newsItems = news.map { item in
					var cleanedTitle = item.title
					if item.title.starts(with: "["),
						 let bracketIndex = item.title.range(of: "] ") {
						cleanedTitle = String(item.title.suffix(from: bracketIndex.upperBound))
					}
					return CarouselItem(title: cleanedTitle,
															subtitle: item.tag,
															url: item.url,
															imageURL: item.thumbnail)
				}
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

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		Section.allCases.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch Section(rawValue: section)! {
		case .news:    return 1
		case .sources: return sources.count
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
			cell.source = sources[indexPath.item]
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

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmptyHeader", for: indexPath)

		case .sources:
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
			view.title = .localize("Sources")
			return view
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .news:
			return .zero

		case .sources:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

}

//
//  BrowseViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import os.log

class BrowseViewController: UICollectionViewController {

	private var sources = [PLSource]()

	private var newsItems: [CarouselItem]?

	init() {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSize(width: 320, height: 57)
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionHeadersPinToVisibleBounds = true
		super.init(collectionViewLayout: layout)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Browse")
		navigationItem.standardAppearance = .withoutSeparator

		collectionView.backgroundColor = .systemBackground
		collectionView.alwaysBounceVertical = true
		collectionView.register(SourceCollectionViewCell.self, forCellWithReuseIdentifier: "SourceCell")
		collectionView.register(CarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")
		collectionView.register(UICollectionReusableView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
														withReuseIdentifier: "EmptyHeader")
		collectionView.register(SectionHeaderView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
														withReuseIdentifier: "Header")
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

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		collectionViewLayout.invalidateLayout()
	}

	// MARK: - Sources

	@objc private func sourcesDidUpdate() {
		sources = PLSourceManager.shared.sources
			.sorted(by: { a, b in a.label < b.label })
		collectionView.reloadData()
	}

	// MARK: - News

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
					self.collectionView.reloadItems(at: [
						IndexPath(item: 0, section: 0)
					])
				}
			} catch {
				os_log("Loading news failed: %@", String(describing: error))
			}
		}
	}

}

extension BrowseViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDataSource, UICollectionViewDelegate

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

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch Section(rawValue: indexPath.section)! {
		case .news:
			return CGSize(width: collectionView.frame.size.width, height: CarouselViewController.height)

		case .sources:
			let layout = collectionViewLayout as! UICollectionViewFlowLayout
			var size = layout.itemSize
			size.width = collectionView.frame.size.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right
			return size
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

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .news:
			return .zero

		case .sources:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

}

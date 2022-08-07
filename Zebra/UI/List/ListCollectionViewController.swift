//
//  ListCollectionViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class ListCollectionViewController: BaseListCollectionViewController<UICollectionViewCompositionalLayout> {

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.preservesSuperviewLayoutMargins = true

		collectionView.register(SectionHeaderView.self,
														forSupplementaryViewOfKind: "Header",
														withReuseIdentifier: "Header")
		collectionView.register(InfoFooterView.self,
														forSupplementaryViewOfKind: "InfoFooter",
														withReuseIdentifier: "InfoFooter")
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		updateHeaders()
	}

	private func updateHeaders() {
		UIView.animate(withDuration: 0.1) {
			guard let collectionView = self.collectionView,
						let layout = self.layout else {
				return
			}

			let isScrollEdge = floor(collectionView.contentOffset.y + collectionView.adjustedContentInset.top) <= 0

			for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: "Header") {
				guard let view = collectionView.supplementaryView(forElementKind: "Header", at: indexPath) as? SectionHeaderView,
							let attributes = layout.layoutAttributesForSupplementaryView(ofKind: "Header", at: indexPath) else {
					continue
				}

				view.isPinned = !isScrollEdge && attributes.zIndex == .max && floor(attributes.frame.origin.y) <= floor(collectionView.contentOffset.y + collectionView.adjustedContentInset.top)
			}
		}
	}

}

extension NSCollectionLayoutGroup {
	static func oneAcross(heightDimension: NSCollectionLayoutDimension) -> NSCollectionLayoutGroup {
		NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
																												 heightDimension: heightDimension),
																			 subitems: [NSCollectionLayoutItem(layoutSize: .full)])
	}

	static func listGrid(environment: NSCollectionLayoutEnvironment, heightDimension: NSCollectionLayoutDimension) -> NSCollectionLayoutGroup {
		let width = environment.container.effectiveContentSize.width
		let itemWidth = width / (width < 480 ? 1 : round(width / 295))
		let fraction = itemWidth / width
		return NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
																																heightDimension: heightDimension),
																							subitems: Array(repeating: NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(fraction),
																																																									heightDimension: .fractionalHeight(1))),
																															count: Int(1 / fraction)))
	}
}

extension NSCollectionLayoutSize {
	static var full: NSCollectionLayoutSize {
		.init(widthDimension: .fractionalWidth(1),
					heightDimension: .fractionalHeight(1))
	}
}

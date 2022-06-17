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

		collectionView.register(SectionHeaderView.self,
														forSupplementaryViewOfKind: "Header",
														withReuseIdentifier: "Header")
		collectionView.register(InfoFooterView.self,
														forSupplementaryViewOfKind: "InfoFooter",
														withReuseIdentifier: "InfoFooter")
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
		let itemWidth = width < 480 ? width : (width / round(width / 320))
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

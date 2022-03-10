//
//  ListCollectionViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log
import UIKit

class ListCollectionViewController: UICollectionViewController {
	init() {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSize(width: 320, height: 57)
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionHeadersPinToVisibleBounds = true
		super.init(collectionViewLayout: layout)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.standardAppearance = .withoutSeparator

		collectionView.backgroundColor = .systemBackground
		collectionView.alwaysBounceVertical = true
		collectionView.register(UICollectionReusableView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
														withReuseIdentifier: "Empty")
		collectionView.register(UICollectionReusableView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
														withReuseIdentifier: "EmptyFooter")
		collectionView.register(SectionHeaderView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
														withReuseIdentifier: "Header")
		collectionView.register(InfoFooterView.self,
														forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
														withReuseIdentifier: "Footer")
	}

	override func viewWillTransition(to _: CGSize, with _: UIViewControllerTransitionCoordinator) {
		collectionViewLayout.invalidateLayout()
	}
}

extension ListCollectionViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDataSource, UICollectionViewDelegate
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		var size = layout.itemSize
		size.width = collectionView.frame.size.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right
		if size.width > 1024 {
			size.width /= 5
		} else if size.width > 1000 {
			size.width /= 4
		} else if size.width > 480 {
			size.width /= 3
		}
		return size
	}

	func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
		UIEdgeInsets(top: 0,
								 left: collectionView.safeAreaInsets.left,
								 bottom: 0,
								 right: collectionView.safeAreaInsets.right)
	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Empty", for: indexPath)

		case UICollectionView.elementKindSectionFooter:
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmptyFooter", for: indexPath)

		default: fatalError()
		}
	}

	func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
		.zero
	}

	func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection _: Int) -> CGSize {
		.zero
	}
}

//
//  FlowListCollectionViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log
import UIKit

class FlowListCollectionViewController: BaseListCollectionViewController<UICollectionViewFlowLayout> {

	internal var useCellsAcross = true

	override class func createLayout() -> UICollectionViewFlowLayout {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CGSize(width: 320, height: 57)
		layout.minimumInteritemSpacing = 0
		layout.minimumLineSpacing = 0
		layout.sectionHeadersPinToVisibleBounds = true
		return layout
	}

	override func viewDidLoad() {
		super.viewDidLoad()

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

	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)
		collectionViewLayout.invalidateLayout()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		var width = collectionView.frame.size.width - collectionView.safeAreaInsets.left - collectionView.safeAreaInsets.right
		if useCellsAcross && width > 480 {
			width /= round(width / 320)
		}

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		if layout.itemSize.width != width {
			layout.itemSize.width = width
			layout.invalidateLayout()
		}
	}

}

extension FlowListCollectionViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDataSource, UICollectionViewDelegate

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		return layout.itemSize
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

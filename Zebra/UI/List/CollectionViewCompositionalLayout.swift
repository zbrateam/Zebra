//
//  CollectionViewCompositionalLayout.swift
//  Zebra
//
//  Created by Adam Demasi on 26/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class CollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {

	private var effectViews = [IndexPath: UIToolbar]()

	override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		guard let layout = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) else {
			return nil
		}
		guard let collectionView = collectionView else {
			return layout
		}

		let isPinned = layout.zIndex == .max && layout.frame.origin.y == collectionView.contentOffset.y + collectionView.adjustedContentInset.top
		if isPinned {
			if effectViews[indexPath] == nil,
				 let supplementaryView = collectionView.supplementaryView(forElementKind: elementKind, at: indexPath) {
				let effectView = UIToolbar()
				effectView.delegate = self
				collectionView.insertSubview(effectView, belowSubview: supplementaryView)
				effectViews[indexPath] = effectView
			}
			effectViews[indexPath]?.frame = layout.frame
		} else if let effectView = effectViews[indexPath] {
			effectView.removeFromSuperview()
			effectViews[indexPath] = nil
		}

		return layout
	}

}

extension CollectionViewCompositionalLayout: UIToolbarDelegate {
	func position(for bar: UIBarPositioning) -> UIBarPosition {
		.top
	}
}

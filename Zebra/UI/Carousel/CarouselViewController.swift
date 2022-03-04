//
//  CarouselViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class CarouselViewController: UICollectionViewController {

	static let height: CGFloat = CarouselItemCollectionViewCell.size.height + (15 * 2)

	var items = [CarouselItem]() {
		didSet { collectionView.reloadData() }
	}

	init() {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CarouselItemCollectionViewCell.size
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 20
		layout.sectionInset = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
		super.init(collectionViewLayout: layout)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.alwaysBounceHorizontal = true
		collectionView.isPagingEnabled = true
		collectionView.decelerationRate = .fast
		collectionView.backgroundColor = nil
		collectionView.register(CarouselItemCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
	}

	@objc private func copyItem(_ sender: UICommand) {
		guard let urlString = sender.propertyList as? String,
					let url = URL(string: urlString) else {
			return
		}
		UIPasteboard.general.url = url
	}

}

extension CarouselViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDataSource, UICollectionViewDelegate

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		1
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		items.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CarouselItemCollectionViewCell
		cell.item = items[indexPath.item]
		return cell
	}

	override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
		let item = items[indexPath.item]
		return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
			// TODO
			return nil
		}, actionProvider: { menu in
			UIMenu(children: [
				UICommand(title: .copy,
									image: UIImage(systemName: "doc.on.doc"),
									action: #selector(self.copyItem),
									propertyList: item.url.absoluteString)
			])
		})
	}

}


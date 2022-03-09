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
		didSet { updateState() }
	}

	var isLoading = true {
		didSet { updateState() }
	}

	var isError = false {
		didSet { updateState() }
	}

	var errorText = String.localize("News Unavailable") {
		didSet { errorLabel?.text = errorText }
	}

	internal var activityIndicator: UIActivityIndicatorView!
	internal var errorLabel: UILabel!

	init() {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = CarouselItemCollectionViewCell.size
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 20
		layout.sectionInset = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
		super.init(collectionViewLayout: layout)
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		// TODO: Scroll snap/pagination centering on each item
		collectionView.showsVerticalScrollIndicator = false
		collectionView.showsHorizontalScrollIndicator = false
		collectionView.alwaysBounceHorizontal = true
		collectionView.decelerationRate = .fast
		collectionView.backgroundColor = nil
		collectionView.register(CarouselItemCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

		activityIndicator = UIActivityIndicatorView(style: .medium)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.hidesWhenStopped = true
		activityIndicator.startAnimating()
		view.addSubview(activityIndicator)

		errorLabel = UILabel()
		errorLabel.translatesAutoresizingMaskIntoConstraints = false
		errorLabel.font = .preferredFont(forTextStyle: .subheadline, weight: .semibold)
		errorLabel.textColor = .tertiaryLabel
		errorLabel.text = errorText
		view.addSubview(errorLabel)

		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

			errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			errorLabel.widthAnchor.constraint(equalToConstant: 200),
		])
	}

	func updateState() {
		if !items.isEmpty {
			if isLoading {
				isLoading = false
			}
			if isError {
				isError = false
			}
			collectionView.reloadData()
		}

		collectionView.isUserInteractionEnabled = !isLoading && !isError
		errorLabel.isHidden = !isError

		if isLoading {
			activityIndicator.startAnimating()
		} else {
			activityIndicator.stopAnimating()
		}

		if isError {
			isLoading = false
		}
	}

	@objc private func copyItem(_ sender: UICommand) {
		let index = sender.propertyList as! Int
		let item = items[index]
		UIPasteboard.general.string = item.url.absoluteString
	}

	@objc private func shareItem(_ sender: UICommand) {
		let index = sender.propertyList as! Int
		guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) else {
			return
		}
		let item = items[index]
		let viewController = UIActivityViewController(activityItems: [item.url], applicationActivities: nil)
		viewController.popoverPresentationController?.sourceView = cell
		viewController.popoverPresentationController?.sourceRect = cell.bounds
		present(viewController, animated: true, completion: nil)
	}
}

extension CarouselViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDataSource, UICollectionViewDelegate
	override func numberOfSections(in _: UICollectionView) -> Int {
		1
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
		items.count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CarouselItemCollectionViewCell
		cell.item = items[indexPath.item]
		return cell
	}

	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
			// TODO:
			nil
		}, actionProvider: { _ in
			UIMenu(children: [
				UICommand(title: .copy,
									image: UIImage(systemName: "doc.on.doc"),
									action: #selector(self.copyItem),
									propertyList: indexPath.item),
				UICommand(title: .share,
									image: UIImage(systemName: "square.and.arrow.up"),
									action: #selector(self.shareItem),
									propertyList: indexPath.item),
			])
		})
	}

	override func collectionView(_: UICollectionView, shouldHighlightItemAt _: IndexPath) -> Bool {
		true
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = items[indexPath.item]
		URLController.open(url: item.url, sender: self, webSchemesOnly: true)
	}

	override func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		guard let cell = collectionView.cellForItem(at: configuration.identifier as! IndexPath) else {
			return nil
		}
		let parameters = UIPreviewParameters()
		parameters.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 20)
		return UITargetedPreview(view: cell, parameters: parameters)
	}

	override func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
		return self.collectionView(collectionView, previewForHighlightingContextMenuWithConfiguration: configuration)
	}
}

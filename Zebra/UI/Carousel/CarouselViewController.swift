//
//  CarouselViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class CarouselViewController: ListCollectionViewController {
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

	private var dataSource: UICollectionViewDiffableDataSource<Int, CarouselItem>!

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		let size = CarouselItemCollectionViewCell.size
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(size.width),
																																											heightDimension: .absolute(size.height)),
																									 subitems: [NSCollectionLayoutItem(layoutSize: .full)])
		let section = NSCollectionLayoutSection(group: group)
		section.interGroupSpacing = 20
		section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20)
		section.orthogonalScrollingBehavior = .groupPaging
		return UICollectionViewCompositionalLayout(section: section)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.backgroundColor = nil
		collectionView.register(CarouselItemCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CarouselItemCollectionViewCell
			cell.item = item
			return cell
		}

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

			var snapshot = NSDiffableDataSourceSnapshot<Int, CarouselItem>()
			snapshot.appendSections([0])
			snapshot.appendItems(items)
			dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
		}

		collectionView.isUserInteractionEnabled = !isLoading && !isError
		errorLabel.isHidden = !isError

		if isLoading {
			activityIndicator.startAnimating()
		} else {
			activityIndicator.stopAnimating()
		}

		if isError && isLoading {
			isLoading = false
		}
	}
}

extension CarouselViewController: UICollectionViewDelegateFlowLayout { // UICollectionViewDelegate
	override func collectionView(_: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point _: CGPoint) -> UIContextMenuConfiguration? {
		let item = items[indexPath.item]
		let cell = collectionView.cellForItem(at: indexPath)!
		return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
			// TODO: Preview safari vc?
			nil
		}, actionProvider: { _ in
			UIMenu(children: [
				.openInBrowser(url: item.url, sender: self),
				.copy(text: item.url?.absoluteString),
				.share(text: item.title, url: item.url, sender: self, sourceView: cell)
			].compact())
		})
	}

	override func collectionView(_: UICollectionView, shouldHighlightItemAt _: IndexPath) -> Bool {
		true
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = items[indexPath.item]
		if let url = item.url {
			URLController.open(url: url, sender: self, webSchemesOnly: true)
		}
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

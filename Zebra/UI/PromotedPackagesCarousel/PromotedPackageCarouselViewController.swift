//
//  PromotedPackageCarouselViewController.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class PromotedPackagesCarouselViewController: UICollectionViewController {
	static let height: CGFloat = CarouselItemCollectionViewCell.size.height + (15 * 2)
	
	var items = [PromotedPackageBanner]() {
		didSet { updateState() }
	}

	var isLoading = true {
		didSet { updateState() }
	}

	var isError = false {
		didSet { updateState() }
	}

	var errorText = String.localize("Package Unavailable") {
		didSet { errorLabel?.text = errorText }
	}
	
	private var activityIndicator: UIActivityIndicatorView!
	private var errorLabel: UILabel!
	
	init() {
		let layout = UICollectionViewFlowLayout()
		layout.itemSize = PromotedPackageCarouselItemCollectionViewCell.size
		layout.scrollDirection = .horizontal
		layout.minimumInteritemSpacing = 20
		layout.sectionInset = UIEdgeInsets(top: 15, left: 20, bottom: 15, right: 20)
		super.init(collectionViewLayout: layout)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
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
		collectionView.register(PromotedPackageCarouselItemCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
		
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
			errorLabel.widthAnchor.constraint(equalToConstant: 200)
		])
	}
	
	private func updateState() {
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
}

extension PromotedPackagesCarouselViewController: UICollectionViewDelegateFlowLayout {
	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		1
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		items.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PromotedPackageCarouselItemCollectionViewCell
		cell.item = items[indexPath.item]
		return cell
	}
	
	override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
		true
	}
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let item = items[indexPath.item]
		let foundPackages: [PLPackage?] = PLPackageManager.shared.packages.filter {
			$0.identifier == item.package
		}
		if foundPackages.isEmpty { return }
		
		let controller = ZBPackageViewController(package: foundPackages[0]!)
		parent?.navigationController?.pushViewController(controller, animated: true)
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

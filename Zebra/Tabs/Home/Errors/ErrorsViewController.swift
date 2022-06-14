//
//  ErrorsViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class ErrorsViewController: ListCollectionViewController {

	private var sources = [String]()
	private var errors = [[PlainsError]]()

	override func viewDidLoad() {
		super.viewDidLoad()

		useCellsAcross = false

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

		collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		NotificationCenter.default.addObserver(self, selector: #selector(refreshProgressDidChange), name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
		refreshProgressDidChange()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)

		NotificationCenter.default.removeObserver(self, name: SourceRefreshController.refreshProgressDidChangeNotification, object: nil)
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		if layout.itemSize.width != layout.estimatedItemSize.width {
			layout.estimatedItemSize.width = layout.itemSize.width
			layout.invalidateLayout()
		}
	}

	@objc private func refreshProgressDidChange() {
		DispatchQueue.main.async {
			let globalErrors = ErrorManager.shared.errorMessages
			let items = SourceRefreshController.shared.sourceStates
				.compactMap { (key, value) -> (key: String, errors: [PlainsError])? in
					if value.errors.isEmpty {
						return nil
					}
					return (key, value.errors.map { PlainsError(level: .error, text: $0.localizedDescription) })
				}
				.sorted(by: { a, b in
					let sourceA = SourceManager.shared.source(forUUID: a.key)
					let sourceB = SourceManager.shared.source(forUUID: b.key)
					return sourceA?.origin.localizedStandardCompare(sourceB?.origin ?? "") == .orderedAscending
				})
			self.sources = items.map(\.key)
			self.errors = (globalErrors.isEmpty ? [] : [globalErrors]) + items.map(\.errors)

			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .decimal
			let count = self.totalErrorCount
			self.title = String.localizedStringWithFormat(.localize("%@ Errors"),
																										count,
																										numberFormatter.string(for: count) ?? "0")

			self.collectionView.reloadData()
		}
	}

	private var globalErrorCount: Int { ErrorManager.shared.errorMessages.count }
	private var totalErrorCount: Int { globalErrorCount + SourceRefreshController.shared.refreshErrors.count }

}

extension ErrorsViewController {

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		errors.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		errors[section].count
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! ErrorCollectionViewCell
		cell.error = errors[indexPath.section][indexPath.item]
		return cell
	}

//	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
//		CGSize(width: collectionView.frame.size.width,
//					 height: UIView.layoutFittingCompressedSize.height)
//	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
			if indexPath.section == 0 && globalErrorCount > 0 {
				view.title = .localize("Package Manager")
			} else {
				let uuid = sources[indexPath.section - (globalErrorCount > 0 ? 1 : 0)]
				let source = SourceManager.shared.source(forUUID: uuid)
				view.title = source?.origin
			}
			return view

		case UICollectionView.elementKindSectionFooter:
			return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Empty", for: indexPath)

		default: fatalError()
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		CGSize(width: collectionView.frame.size.width, height: 52)
	}

}

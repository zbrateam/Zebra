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

	private enum Section: Hashable {
		case packageManager
		case source(label: String)
	}

	private var dataSource: UICollectionViewDiffableDataSource<Section, PlainsError>!

	override class func createLayout() -> CollectionViewCompositionalLayout {
		CollectionViewCompositionalLayout { index, layoutEnvironment in
			var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
			configuration.showsSeparators = false

			let section = NSCollectionLayoutSection.list(using: configuration,
																									 layoutEnvironment: layoutEnvironment)
			section.contentInsetsReference = .none
			section.boundarySupplementaryItems = [.header]
			return section
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, error in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! ErrorCollectionViewCell
			cell.error = error
			return cell
		})
		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case "Header":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				switch self.dataSource.snapshot().sectionIdentifiers[indexPath.section] {
				case .packageManager:
					view.title = .localize("Package Manager")

				case .source(let label):
					view.title = label
				}
				return view

			default: fatalError()
			}
		}
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

	@objc private func refreshProgressDidChange() {
		let count = totalErrorCount

		let sourceErrors = SourceRefreshController.shared.sourceStates
			.compactMap { (key, value) -> (key: Section, value: [PlainsError])? in
				if value.errors.isEmpty {
					return nil
				}
				let source = SourceManager.shared.source(forUUID: key)
				return (.source(label: source?.origin ?? key),
								value.errors.map { PlainsError(level: .error, text: $0.localizedDescription) })
			}
			.sorted(by: { a, b in
				guard case .source(let labelA) = a.key,
							case .source(let labelB) = b.key else {
					return false
				}
				return labelA.localizedStandardCompare(labelB) == .orderedAscending
			})
		let globalErrors = ErrorManager.shared.errorMessages
		let errors = (globalErrors.isEmpty ? [] : [(Section.packageManager, globalErrors)]) + sourceErrors

		var snapshot = NSDiffableDataSourceSnapshot<Section, PlainsError>()
		for section in errors {
			snapshot.appendSections([section.key])
			snapshot.appendItems(section.value, toSection: section.key)
		}

		DispatchQueue.main.async {
			self.title = String.localizedStringWithFormat(.localize("%@ Errors"),
																										count,
																										NumberFormatter.count.string(for: count) ?? "0")
			self.dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
		}
	}

	private var globalErrorCount: Int { ErrorManager.shared.errorMessages.count }
	private var totalErrorCount: Int { globalErrorCount + SourceRefreshController.shared.refreshErrors.count }

}


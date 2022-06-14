//
//  ErrorsViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class ErrorsViewController: UICollectionViewController {

	private enum ErrorSection: Equatable, Hashable {
		case packageManager
		case source(label: String)

		func hash(into hasher: inout Hasher) {
			switch self {
			case .packageManager:
				break
			case .source(label: let label):
				hasher.combine(label)
			}
		}
	}

	private var dataSource: UICollectionViewDiffableDataSource<ErrorSection, PlainsError>!

	init() {
		let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																											heightDimension: .estimated(52)),
																								 subitems: [
																									NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																																						heightDimension: .estimated(52)))
																								 ])
		let section = NSCollectionLayoutSection(group: group)
		section.boundarySupplementaryItems = [
			NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
																																										 heightDimension: .absolute(52)),
																									elementKind: "Header",
																									alignment: .top)
		]
		let layout = UICollectionViewCompositionalLayout(section: section)
		super.init(collectionViewLayout: layout)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		collectionView.register(ErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")
		collectionView.register(SectionHeaderView.self,
														forSupplementaryViewOfKind: "Header",
														withReuseIdentifier: "Header")

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, error in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! ErrorCollectionViewCell
			cell.error = error
			return cell
		})
		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case "Header":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				// TODO: What am I supposed to do on iOS 14? How did they forget this for a full year??
				if #available(iOS 15, *) {
					switch self.dataSource.sectionIdentifier(for: indexPath.section) {
					case .packageManager:
						view.title = .localize("Package Manager")

					case .source(label: let label):
						view.title = label

					case .none:
						break
					}
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

		let globalErrors = ErrorManager.shared.errorMessages
		let sourceErrors = SourceRefreshController.shared.sourceStates
			.compactMap { (key, value) -> (key: ErrorSection, value: [PlainsError])? in
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
		let coreErrors = globalErrors.isEmpty ? [] : [(key: ErrorSection.packageManager,
																									 value: globalErrors)]
		let errors = coreErrors + sourceErrors

		var snapshot = NSDiffableDataSourceSnapshot<ErrorSection, PlainsError>()
		for section in errors {
			snapshot.appendSections([section.key])
			snapshot.appendItems(section.value, toSection: section.key)
		}

		DispatchQueue.main.async {
			let numberFormatter = NumberFormatter()
			numberFormatter.numberStyle = .decimal
			self.title = String.localizedStringWithFormat(.localize("%@ Errors"),
																										count,
																										numberFormatter.string(for: count) ?? "0")
			self.dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
		}
	}

	private var globalErrorCount: Int { ErrorManager.shared.errorMessages.count }
	private var totalErrorCount: Int { globalErrorCount + SourceRefreshController.shared.refreshErrors.count }

}


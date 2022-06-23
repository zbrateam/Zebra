//
//  SourceSectionsViewController.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import os.log
import UIKit
import Plains

fileprivate protocol SectionCountProviding {
	var sections: [String: NSNumber] { get }
	var count: UInt { get }
}

extension PackageManager: SectionCountProviding {}
extension Source: SectionCountProviding {}

class SourceSectionsViewController: ListCollectionViewController {

	private enum Section: Int {
		case featured, sections
	}

	private enum Value: Hashable {
		case featured
		case section(section: String?, count: UInt)

		func hash(into hasher: inout Hasher) {
			switch self {
			case .featured:
				break
			case .section(let section, let count):
				hasher.combine(section)
				hasher.combine(count)
			}
		}
	}

	private let source: Source?

	private var promotedPackages: [PromotedPackageBanner]?
	private var sections = [Value]()
	private var dataSource: UICollectionViewDiffableDataSource<Section, Value>!

	override class func createLayout() -> UICollectionViewCompositionalLayout {
		UICollectionViewCompositionalLayout { index, environment in
			switch index {
			case 0:
				let section = NSCollectionLayoutSection(group: .oneAcross(heightDimension: .absolute(CarouselViewController.height)))
				section.contentInsetsReference = .none
				return section

			case 1:
				let section = NSCollectionLayoutSection(group: .listGrid(environment: environment,
																																 heightDimension: .estimated(52)))
				section.contentInsetsReference = .none
				section.boundarySupplementaryItems = [.header]
				return section

			default: fatalError()
			}
		}
	}

	init(source: Source?) {
		self.source = source
		super.init()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = source?.origin ?? .localize("All Packages")

		collectionView.register(SourceSectionCollectionViewCell.self, forCellWithReuseIdentifier: "SourceSectionCell")
		collectionView.register(PromotedPackagesCarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")

		dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, value in
			switch value {
			case .featured:
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! PromotedPackagesCarouselCollectionViewContainingCell
				cell.parentViewController = self
				cell.bannerItems = self.promotedPackages ?? []
				return cell

			case .section(let section, let count):
				let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SourceSectionCell", for: indexPath) as! SourceSectionCollectionViewCell
				cell.isSource = self.source != nil
				cell.section = (section, count)
				return cell
			}
		}
		dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
			switch kind {
			case "Header":
				let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
				view.title = .localize("Sections")
				return view

			default: fatalError()
			}
		}

		updateDataSource()
		setupSections()
		fetchPromotedPackages()
	}

	private func setupSections() {
		Task.detached {
			let source: SectionCountProviding = self.source ?? PackageManager.shared
			let sections = (source.sections as! [String: UInt])
				.map { key, value in Value.section(section: key, count: value) }
				.sorted(by: { a, b in
					guard case .section(let labelA, _) = a,
								case .section(let labelB, _) = b else {
						return false
					}
					return labelA!.localizedStandardCompare(labelB!) == .orderedAscending
				})
			let finalSections = [.section(section: nil, count: source.count)] + sections

			await MainActor.run {
				self.sections = finalSections
				self.updateDataSource()
			}
		}
	}

	private func updateDataSource() {
		var snapshot = NSDiffableDataSourceSnapshot<Section, Value>()
		if Preferences.showFeaturedCarousels {
			snapshot.appendSections([.featured])
			snapshot.appendItems([.featured], toSection: .featured)
		}
		snapshot.appendSections([.sections])
		snapshot.appendItems(sections, toSection: .sections)
		self.dataSource.apply(snapshot, animatingDifferences: true, completion: nil)
	}

	// MARK: - Sileo Compatibility Layer

	private var carouselViewController: PromotedPackagesCarouselViewController? {
		if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? PromotedPackagesCarouselCollectionViewContainingCell {
			return cell.promotedViewController
		}
		return nil
	}

	private func fetchPromotedPackages() {
		Task.detached {
			guard let source = self.source else {
				return
			}

			do {
				if let packages = PromotedPackagesFetcher.getCached(repo: source.uri) {
					await MainActor.run {
						self.promotedPackages = packages
						self.carouselViewController?.bannerItems = packages
					}
				}

				let promotedPackages = try await PromotedPackagesFetcher.fetch(repo: source.uri)
				await MainActor.run {
					self.promotedPackages = promotedPackages
					self.carouselViewController?.bannerItems = promotedPackages
				}
			} catch {
				Logger().warning("Loading Promoted packages failed: \(String(describing: error))")
				await MainActor.run {
					self.carouselViewController?.isError = true
				}
			}
		}
	}

}

extension SourceSectionsViewController {

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch Section(rawValue: indexPath.section) {
		case .featured:
			return

		case .sections:
			guard case .section(let section, _) = sections[indexPath.item] else {
				return
			}

			let viewController = PackageListViewController(filter: .section(source: source, section: section))
			// Avoid doubling the name on the back button by changing the back button label to a generic
			// “Back” for the all sections item.
			navigationItem.backButtonTitle = section == nil ? .back : nil
			navigationController?.pushViewController(viewController, animated: true)
			return

		case .none:
			return
		}
	}

}

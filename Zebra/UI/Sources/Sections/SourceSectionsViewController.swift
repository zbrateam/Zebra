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

class SourceSectionViewController: ListCollectionViewController {
	private let source: Source?
	private var totalCount: UInt = 0
	private var countsBySection = [String: UInt]()
	private var sections = [String]()

	private var promotedPackages: [PromotedPackageBanner]?

	init(source: Source?) {
		self.source = source
		super.init()
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = source?.origin ?? .localize("All Packages")

		let layout = collectionViewLayout as! UICollectionViewFlowLayout
		layout.itemSize.height = 52

		collectionView.register(SourceSectionCollectionViewCell.self, forCellWithReuseIdentifier: "SourceSectionCell")
		collectionView.register(PromotedPackagesCarouselCollectionViewContainingCell.self, forCellWithReuseIdentifier: "CarouselCell")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if sections.isEmpty {
			setupSections()
		}
		if promotedPackages == nil {
			fetchPromotedPackages()
		}
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}

	private func setupSections() {
		Task {
			var countsBySection = [String: UInt]()
			var totalCount: UInt = 0
			if let source = source {
				countsBySection = source.sections as! [String: UInt]
				totalCount = source.count
			} else {
				let packageManager = PackageManager.shared
				countsBySection = packageManager.sections as! [String: UInt]
				totalCount = packageManager.count
			}

			let sections = Array(countsBySection.keys)
				.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending })
			await MainActor.run {
				collectionView.performBatchUpdates({
					self.sections = sections
					self.countsBySection = countsBySection
					self.totalCount = totalCount

					collectionView.reloadData()
				})
			}
		}
	}

	// MARK: - Sileo Compatibility Layer

	private var carouselViewController: PromotedPackagesCarouselViewController? {
		if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? PromotedPackagesCarouselCollectionViewContainingCell {
			return cell.promotedViewController
		}
		return nil
	}

	private func fetchPromotedPackages() {
		Task(priority: .medium) {
			guard let source = source else {
				return
			}

			do {
				if let packages = PromotedPackagesFetcher.getCached(repo: source.uri) {
					promotedPackages = packages
					await MainActor.run {
						self.carouselViewController?.bannerItems = packages
					}
				}

				promotedPackages = try await PromotedPackagesFetcher.fetch(repo: source.uri)
				await MainActor.run {
					self.carouselViewController?.bannerItems = promotedPackages!
				}
			} catch {
				os_log("Loading Promoted packages failed: %@", String(describing: error))
				await MainActor.run {
					self.carouselViewController?.isError = true
				}
			}
		}
	}
}

extension SourceSectionViewController {
	private enum Section: Int, CaseIterable {
		case featuredBanner, sections
	}

	override func numberOfSections(in _: UICollectionView) -> Int {
		Section.allCases.count
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch Section(rawValue: section)! {
				case .featuredBanner: return source != nil && Preferences.showFeaturedCarousels ? 1 : 0
		case .sections:       return sections.count + 1
		}
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch Section(rawValue: indexPath.section)! {
		case .featuredBanner:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarouselCell", for: indexPath) as! PromotedPackagesCarouselCollectionViewContainingCell
			cell.parentViewController = self
			cell.bannerItems = promotedPackages ?? []
			return cell

		case .sections:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SourceSectionCell", for: indexPath) as! SourceSectionCollectionViewCell
					cell.isSource = indexPath.item != 0
			cell.section = indexPath.item == 0
						? (nil, totalCount)
						: (sections[indexPath.item - 1], countsBySection[sections[indexPath.item - 1]] ?? 0)
			return cell
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch Section(rawValue: indexPath.section)! {
		case .featuredBanner:
			return CGSize(width: collectionView.frame.size.width, height: CarouselViewController.height)

		case .sections:
			return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		switch Section(rawValue: section)! {
		case .featuredBanner:
			return .zero

		case .sections:
			return super.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		switch kind {
		case UICollectionView.elementKindSectionHeader:
			let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! SectionHeaderView
			view.title = .localize("Sections")
			return view

		default:
			return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .featuredBanner:
			return .zero

		case .sections:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		switch Section(rawValue: section)! {
		case .featuredBanner:
			return .zero

		case .sections:
			return CGSize(width: collectionView.frame.size.width, height: 52)
		}
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch Section(rawValue: indexPath.section) {
		case .featuredBanner:
			return

		case .sections:
			let viewController = PackageListViewController(filter: .section(source: source, section: indexPath.item == 0 ? nil : sections[indexPath.item - 1]))
			// Avoid doubling the name on the back button by changing the back button label to a generic
			// “Back” for the all sections item.
			navigationItem.backButtonTitle = indexPath.item == 0 ? .back : nil
			navigationController?.pushViewController(viewController, animated: true)
			return

		case .none:
			return
		}
	}
}

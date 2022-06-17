//
//  HomeViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class HomeViewController: FlowListCollectionViewController {

	private var errorCount: UInt = 0

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Home")
		collectionView.register(HomeErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")

		#if !targetEnvironment(macCatalyst)
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refreshSources), for: .valueChanged)
		collectionView.refreshControl = refreshControl
		#endif
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
		// Filter to only errors. Warnings are mostly annoying and not particularly useful.
		errorCount = UInt(SourceRefreshController.shared.refreshErrors.count) + ErrorManager.shared.errorCount(at: .error)

		DispatchQueue.main.async {
			self.collectionView.reloadData()

			let progress = SourceRefreshController.shared.progress
			let percent = progress.fractionCompleted
			self.navigationProgressBar?.setProgress(Float(percent), animated: true)
		}
	}

	@objc private func refreshSources() {
		#if !targetEnvironment(macCatalyst)
		collectionView.refreshControl!.endRefreshing()
		#endif

		if let rootViewController = parent?.parent as? RootViewController {
			rootViewController.refreshSources()
		}
	}

}

extension HomeViewController {

	private enum Section: Int, CaseIterable {
		case appNotice, error
	}

	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		Section.allCases.count
	}

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch Section(rawValue: section)! {
		case .appNotice: return Device.isDemo ? 1 : 0
		case .error:     return errorCount == 0 ? 0 : 1
		}
	}

	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch Section(rawValue: indexPath.section)! {
		case .appNotice:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! HomeErrorCollectionViewCell
			cell.text = .localize("You’re using a sandboxed demo of Zebra.")
			return cell

		case .error:
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ErrorCell", for: indexPath) as! HomeErrorCollectionViewCell
			let errorCount = self.errorCount
			cell.text = String.localizedStringWithFormat(.localize("Zebra encountered %@ errors."),
																									 errorCount,
																									 NumberFormatter.localizedString(from: errorCount as NSNumber, number: .decimal))
			return cell
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
		CGSize(width: collectionView.frame.size.width,
					 height: 120)
	}

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch Section(rawValue: indexPath.section)! {
		case .appNotice:
			// TODO: Display sandboxed.json
			return

		case .error:
			let viewController = ErrorsViewController()
			navigationController?.pushViewController(viewController, animated: true)
		}
	}

}

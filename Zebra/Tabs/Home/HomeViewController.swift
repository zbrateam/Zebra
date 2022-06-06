//
//  HomeViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class HomeViewController: ListCollectionViewController {

	private var progressBar: UIProgressView!
	private var progressLabel: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Home")
		collectionView.register(HomeErrorCollectionViewCell.self, forCellWithReuseIdentifier: "ErrorCell")

#if !targetEnvironment(macCatalyst)
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(nil, action: #selector(RootViewController.refreshSources), for: .valueChanged)
		collectionView.refreshControl = refreshControl
#endif

		// TODO: Remove
		progressBar = UIProgressView(progressViewStyle: .default)
		progressBar.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(progressBar)

		progressLabel = UILabel()
		progressLabel.translatesAutoresizingMaskIntoConstraints = false
		progressLabel.font = .monospacedDigitSystemFont(ofSize: 0, weight: .medium)
		view.addSubview(progressLabel)

		NSLayoutConstraint.activate([
			progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			progressBar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			progressBar.widthAnchor.constraint(equalToConstant: 300),

			progressLabel.centerXAnchor.constraint(equalTo: progressBar.centerXAnchor),
			progressLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
		])
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
		DispatchQueue.main.async {
			self.collectionView.reloadData()

			let progress = SourceRefreshController.shared.progress
			let percent = progress.fractionCompleted
			self.progressBar.progress = Float(percent)
			self.progressLabel.text = NumberFormatter.localizedString(from: percent as NSNumber, number: .percent)

			#if !targetEnvironment(macCatalyst)
			let refreshControl = self.collectionView.refreshControl!
			let isRefreshing = !progress.isFinished && !progress.isCancelled
			if isRefreshing != refreshControl.isRefreshing {
				if isRefreshing {
					refreshControl.beginRefreshing()
				} else {
					refreshControl.endRefreshing()
				}
			}
			#endif
		}
	}

	private var errorCount: UInt {
		// Filter to only errors. Warnings are mostly annoying and not particularly useful.
		UInt(SourceRefreshController.shared.refreshErrors.count) + ErrorManager.shared.errorCount(at: .error)
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
																									 NSDecimalNumber(value: errorCount),
																									 NumberFormatter.localizedString(from: errorCount as NSNumber, number: .decimal))
			return cell
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
		CGSize(width: collectionView.frame.size.width,
					 height: 120)
	}

}

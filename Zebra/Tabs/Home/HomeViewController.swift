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

		NSLayoutConstraint.activate([
			progressBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			progressBar.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			progressBar.widthAnchor.constraint(equalToConstant: 300)
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
			self.progressBar.progress = Float(SourceRefreshController.shared.progress.fractionCompleted)
		}
	}

	private var errorCount: Int {
		// Filter to only errors. Warings are mostly annoying and not particularly useful.
		SourceRefreshController.shared.refreshErrors
			.reduce(0, { count, item in
				switch item.level {
				case .warning: return count
				case .error:   return count + 1
				@unknown default: fatalError()
				}
			})
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
			cell.text = String.localizedStringWithFormat(.localize("Zebra encountered %li errors."), errorCount)
			return cell
		}
	}

	override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
		CGSize(width: collectionView.frame.size.width,
					 height: 120)
	}

}

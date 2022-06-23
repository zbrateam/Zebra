//
//  LoadingViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

	private var loadingView: LoadingView!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBackground

		loadingView = LoadingView()
		loadingView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(loadingView)

		NSLayoutConstraint.activate([
			loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			loadingView.topAnchor.constraint(equalTo: view.topAnchor),
			loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		loadingView.isHidden = false
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		loadingView.isHidden = true
	}

}

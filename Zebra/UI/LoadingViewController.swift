//
//  LoadingViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBackground

		let activityIndicator = UIActivityIndicatorView(style: .medium)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.startAnimating()
		activityIndicator.color = .tertiaryLabel
		view.addSubview(activityIndicator)

		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
	}

}

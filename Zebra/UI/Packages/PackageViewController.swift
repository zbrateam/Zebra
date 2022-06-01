//
//  PackageViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class PackageViewController: UIViewController {

	let package: Package

	init(package: Package) {
		self.package = package
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		title = .localize("Package")
		view.backgroundColor = .systemBackground
	}

}

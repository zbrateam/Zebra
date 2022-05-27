//
//  PackageListViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 28/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit
import Plains

class PackageListViewController: ListCollectionViewController {

	var packages = [Package]()

	convenience init(packages: [Package]) {
		self.init()
		self.packages = packages
	}

	convenience init(source: Source?, section: String?) {
		// TODO: This init method
		self.init()
	}

}

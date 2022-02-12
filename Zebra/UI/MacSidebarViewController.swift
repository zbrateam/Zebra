//
//  MacSidebarViewController.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

//@available(*, unavailable)
//@available(macCatalyst, introduced: 14.0)
class MacSidebarViewController: UITableViewController {

	private typealias AppTab = RootViewController.AppTab

	override func viewDidLoad() {
		super.viewDidLoad()

		clearsSelectionOnViewWillAppear = false
		tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
	}

}

extension MacSidebarViewController { // UITableViewDataSource, UITableViewDelegate

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		AppTab.allCases.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		let item = AppTab.allCases[indexPath.row]
		var config = UIListContentConfiguration.sidebarCell()
		config.text = item.name
		config.image = item.icon
		cell.contentConfiguration = config

		return cell
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		36
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let rootViewController = splitViewController as! RootViewController
		rootViewController.selectTab(AppTab(rawValue: indexPath.row)!)
	}

}

extension MacSidebarViewController: RootViewControllerDelegate {

	func selectTab(_ tab: RootViewController.AppTab) {
		tableView.selectRow(at: IndexPath(row: tab.rawValue, section: 0),
												animated: false,
												scrollPosition: .middle)
	}

}

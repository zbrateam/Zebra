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

		for item in RootViewController.tabKeyCommands {
			addKeyCommand(item)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		selectTab(.home)
	}

	private func selectTab(_ tab: AppTab) {
		tableView.selectRow(at: IndexPath(row: tab.rawValue, section: 0),
												animated: false,
												scrollPosition: .middle)

		for item in RootViewController.tabKeyCommands {
			let tab2 = AppTab(rawValue: item.propertyList as! Int)!
			item.state = tab2 == tab ? .on : .off
		}
		UIMenuSystem.main.setNeedsRebuild()
	}

	@objc func switchToTab(_ sender: UIKeyCommand) {
		let tab = AppTab(rawValue: sender.propertyList as! Int)!
		selectTab(tab)
	}

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		let menu = UIMenu(options: .displayInline,
											children:
												keyCommands!
											)
		builder.insertSibling(menu, afterMenu: .view)
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
		selectTab(AppTab(rawValue: indexPath.row)!)
	}

}

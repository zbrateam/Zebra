//
//  AppDelegate.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		#if targetEnvironment(macCatalyst)
		let helperBundleURL = Bundle.main.privateFrameworksURL!.appendingPathComponent("ZebraCatalystHelper.framework")
		let helperBundle = Bundle(url: helperBundleURL)
		helperBundle?.load()
		#endif

		setenv("PATH", Device.path.cString, 1)

		ZBPlainsController.setUp()

		return true
	}

	// MARK: - UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "App", sessionRole: .windowApplication)
	}

	// MARK: - Menu

	private struct LinkMenuItem {
		let title: String
		let url: String
	}

	@IBAction private func openLink(_ sender: UIKeyCommand) {
		let urlString = sender.propertyList as! String
		URLController.open(url: URL(string: urlString)!, sender: UIViewController())
	}

	private func openFileURL(_ url: URL) {
		#if targetEnvironment(macCatalyst)
		let finalURL = url
		#else
		var components = URLComponents(url: "filza://view")
		components.path = url.path
		let finalURL = components.url
		#endif
		UIApplication.shared.open(finalURL, options: [:], completionHandler: nil)
	}

	@IBAction private func openDataDirectory() {
		openFileURL(ZBPlainsController.dataURL)
	}

	@IBAction private func openCachesDirectory() {
		openFileURL(ZBPlainsController.cacheURL)
	}

	override func buildMenu(with builder: UIMenuBuilder) {
		super.buildMenu(with: builder)

		switch builder.system {
		case .main:
			// Remove irrelevant menu sections
			builder.remove(menu: .newScene)
			builder.remove(menu: .format)
			builder.remove(menu: .text)
			builder.remove(menu: .toolbar)

			if #available(iOS 15, *) {
				builder.remove(menu: .sidebar)
			}

			// Add Preferences to Zebra menu
			builder.insertSibling(UIMenu(options: .displayInline,
																	 children: [
																		UIKeyCommand(title: .localize("Preferences"),
																								 action: #selector(RootViewController.openPreferences),
																								 input: ",",
																								 modifierFlags: .command)
																	 ]),
														afterMenu: .about)
			builder.replace(menu: .about,
											with: UIMenu(options: .displayInline,
																	 children: [
																		UICommand(title: .localize("About Zebra"),
																							action: #selector(RootViewController.openAbout))
																	 ]))

			// Add Open Package to File menu
			let openMenu = UIMenu(options: .displayInline,
														children: [
															UIKeyCommand(title: .localize("Open Package…"),
																					 action: #selector(RootViewController.openPackage),
																					 input: "o",
																					 modifierFlags: .command)
														])
			builder.insertChild(openMenu, atStartOfMenu: .file)

			// Add Sources menu
			let addSourceMenu = UIMenu(options: .displayInline,
																 children: [
																	UIKeyCommand(title: .localize("Add Source…"),
																							 action: #selector(RootViewController.addSource),
																							 input: "n",
																							 modifierFlags: .command)
																 ])
			let importExportSourcesMenu = UIMenu(options: .displayInline,
																					 children: [
																						UIKeyCommand(title: .localize("Import Sources…"),
																												 action: #selector(RootViewController.importSources),
																												 input: "o",
																												 modifierFlags: [.command, .shift]),
																						UIKeyCommand(title: .localize("Export Sources…"),
																												 action: #selector(RootViewController.exportSources),
																												 input: "s",
																												 modifierFlags: [.command, .shift])
																					 ])
			let refreshSourcesMenu = UIMenu(options: .displayInline,
																			children: [
																				UIKeyCommand(title: .localize("Check for Updates"),
																										 action: #selector(RootViewController.refreshSources),
																										 input: "r",
																										 modifierFlags: .command)
																			])
			let sourcesMenu = UIMenu(title: .localize("Sources"),
															 children: [
																addSourceMenu,
																importExportSourcesMenu,
																refreshSourcesMenu,
															 ])
			builder.insertSibling(sourcesMenu, afterMenu: .view)

			// Add tabs to View menu
			let tabsMenu = UIMenu(options: .displayInline,
														children: RootViewController.tabKeyCommands)
			builder.insertChild(tabsMenu, atStartOfMenu: .view)

			let searchMenu = UIMenu(options: .displayInline,
															children: [
																UIKeyCommand(title: .localize("Search"),
																						 image: UIImage(systemName: "magnifyingglass"),
																						 action: #selector(RootViewController.openSearch),
																						 input: "f",
																						 modifierFlags: .command)
															])
			builder.insertChild(searchMenu, atStartOfMenu: .view)

			// Add links to Help menu
			let links = [
				LinkMenuItem(title: .localize("Get Help"),
										 url: "https://getzbra.com/repo/depictions/xyz.willy.Zebra/bug_report.html"),
				LinkMenuItem(title: .localize("Zebra Website"),
										 url: "https://getzbra.com/"),
				LinkMenuItem(title: .localize("What’s New in Zebra"),
										 url: "https://github.com/zbrateam/Zebra/releases"),
				LinkMenuItem(title: .localize("Join Discord"),
										 url: "https://discord.gg/6CPtHBU"),
				LinkMenuItem(title: .localize("@ZebraTeam on Twitter"),
										 url: "https://twitter.com/getzebra")
			]
			let helpLinks = links.map { item in
				UICommand(title: item.title,
									action: #selector(self.openLink),
									propertyList: item.url)
			}
			let helpMenu = UIMenu(options: .displayInline,
														children: helpLinks)
			builder.replaceChildren(ofMenu: .help) { _ in [] }
			builder.insertChild(helpMenu, atEndOfMenu: .help)

			let debugMenu = UIMenu(title: .localize("Troubleshooting"),
														 children: [
															UICommand(title: .localize("Reveal Data Folder…"),
																				action: #selector(self.openDataDirectory)),
															UICommand(title: .localize("Reveal Caches Folder…"),
																				action: #selector(self.openCachesDirectory))
														 ])
			builder.insertChild(debugMenu, atEndOfMenu: .help)

		default: break
		}
	}

}

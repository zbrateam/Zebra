//
//  AppSceneDelegate.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class AppSceneDelegate: BaseSceneDelegate, IdentifiableSceneDelegate {

	static let activityType = "App"

	#if targetEnvironment(macCatalyst)
	var toolbarItems = [NSToolbarItem.Identifier]() {
		didSet { updateToolbar() }
	}
	#endif

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: scene)
		window!.tintColor = .accent
		window!.rootViewController = RootViewController()
		window!.makeKeyAndVisible()

		scene.title = "Zebra"

		#if targetEnvironment(macCatalyst)
		let toolbar = NSToolbar(identifier: "main")
		toolbar.displayMode = .iconOnly
		toolbar.delegate = self

		scene.sizeRestrictions?.minimumSize = CGSize(width: 1170, height: 720)

		scene.titlebar?.toolbar = toolbar
		scene.titlebar?.toolbarStyle = .unified
		#endif
	}

}

#if targetEnvironment(macCatalyst)
extension AppSceneDelegate: NSToolbarDelegate {

	private func updateToolbar() {
		guard let toolbar = window?.windowScene?.titlebar?.toolbar else {
			return
		}

		for _ in toolbar.items {
			toolbar.removeItem(at: 0)
		}
		for item in toolbarItems {
			toolbar.insertItem(withItemIdentifier: item, at: toolbar.items.count)
		}
	}

	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		toolbarItems
	}

	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		toolbarItems
	}

	func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		[]
	}

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		let item = NSToolbarItem(itemIdentifier: itemIdentifier)

		switch itemIdentifier {
		case .back:
			item.isBordered = true
			item.isNavigational = true
			item.action = #selector(RootViewController.goBack)
			item.image = UIImage(systemName: "chevron.backward")
			item.label = .back

		default: break
		}

		return item
	}

}
#endif

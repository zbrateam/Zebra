//
//  AppSceneDelegate.swift
//  Zebra
//
//  Created by Adam Demasi on 9/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class AppSceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: windowScene)
		window!.tintColor = .accent
		window!.rootViewController = RootViewController()
		window!.makeKeyAndVisible()

		scene.title = "Zebra"

#if targetEnvironment(macCatalyst)
		let toolbar = NSToolbar(identifier: "main")
		toolbar.displayMode = .iconOnly
		toolbar.delegate = self

		windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1170, height: 720)

		windowScene.titlebar?.toolbar = toolbar
		windowScene.titlebar?.titleVisibility = .hidden
		windowScene.titlebar?.toolbarStyle = .unified
#endif
	}

}

#if targetEnvironment(macCatalyst)
extension AppSceneDelegate: NSToolbarDelegate {

	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		[]
	}

	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		toolbarDefaultItemIdentifiers(toolbar)
	}

	func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		[]
	}

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		return NSToolbarItem(itemIdentifier: itemIdentifier)
	}

}
#endif

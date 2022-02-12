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
	var toolbarItems = [NSToolbarItem.Identifier]() {
		didSet { updateToolbar() }
	}

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
		windowScene.titlebar?.toolbarStyle = .unified
#endif
	}

	private func updateToolbar() {
		guard let toolbar = window?.windowScene?.titlebar?.toolbar else {
			return
		}

		let currentIdentifiers = toolbar.items.map { item in item.itemIdentifier }
		let difference = currentIdentifiers.difference(from: toolbarItems).inferringMoves()
		for item in difference {
			switch item {
			case .insert(let offset, let element, let associatedWith):
				if let associatedWith = associatedWith {
					toolbar.removeItem(at: associatedWith)
				}
				toolbar.insertItem(withItemIdentifier: element, at: offset)

			case .remove(let offset, _, _):
				toolbar.removeItem(at: offset)
			}
		}
	}

}

#if targetEnvironment(macCatalyst)
extension AppSceneDelegate: NSToolbarDelegate {

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
			
		default: return nil
		}
	}

}
#endif

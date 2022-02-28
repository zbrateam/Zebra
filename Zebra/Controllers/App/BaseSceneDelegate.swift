//
//  BaseSceneDelegate.swift
//  Zebra
//
//  Created by Adam Demasi on 28/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class BaseSceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		for item in URLContexts {
			URLController.open(url: item.url, sender: window?.rootViewController)
		}
	}

}

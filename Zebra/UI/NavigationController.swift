//
//  NavigationController.swift
//  Zebra
//
//  Created by Adam Demasi on 14/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

	override init(rootViewController: UIViewController) {
		super.init(navigationBarClass: NavigationBar.self, toolbarClass: nil)
		viewControllers = [rootViewController]
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func pushViewController(_ viewController: UIViewController, animated: Bool) {
		// Prevent large title except on root items
		if !viewControllers.isEmpty {
			viewController.navigationItem.largeTitleDisplayMode = .never
		}

		navigationProgressBar?.setProgress(0, animated: animated)
		return super.pushViewController(viewController, animated: animated)
	}

	override func popViewController(animated: Bool) -> UIViewController? {
		navigationProgressBar?.setProgress(0, animated: animated)
		return super.popViewController(animated: animated)
	}

	override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
		navigationProgressBar?.setProgress(0, animated: animated)
		return super.popToViewController(viewController, animated: animated)
	}

	override func popToRootViewController(animated: Bool) -> [UIViewController]? {
		navigationProgressBar?.setProgress(0, animated: animated)
		return super.popToRootViewController(animated: animated)
	}

}

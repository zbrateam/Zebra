//
//  PackageSceneDelegate.swift
//  Zebra
//
//  Created by Adam Demasi on 12/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import UIKit

class PackageSceneDelegate: UIResponder, UIWindowSceneDelegate {

	static let activityType = "Package"

	var window: UIWindow?

	private var navigationController: UINavigationController? {
		window?.rootViewController as? UINavigationController
	}

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let scene = scene as? UIWindowScene else {
			return
		}

		window = UIWindow(windowScene: scene)
		window!.tintColor = .accent
		window!.rootViewController = UINavigationController(rootViewController: LoadingViewController())
		navigationController!.setNavigationBarHidden(true, animated: false)
		window!.makeKeyAndVisible()

#if targetEnvironment(macCatalyst)
		let toolbar = NSToolbar(identifier: "main")
		toolbar.displayMode = .iconOnly

		scene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 720)
		scene.sizeRestrictions?.minimumSize = CGSize(width: 600, height: 720)

		scene.titlebar?.toolbar = toolbar
		scene.titlebar?.toolbarStyle = .unified
#endif

		updateState(scene: scene, activity: connectionOptions.userActivities.first)
	}

	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		for item in URLContexts {
			URLController.open(url: item.url, sender: window!.rootViewController!)
		}
	}

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		guard let scene = scene as? UIWindowScene else {
			return
		}
		updateState(scene: scene, activity: userActivity)
	}

	func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
		guard let scene = scene as? UIWindowScene else {
			return
		}
		updateState(scene: scene, activity: userActivity)
	}

	func scene(_ scene: UIScene, restoreInteractionStateWith stateRestorationActivity: NSUserActivity) {
		guard let scene = scene as? UIWindowScene else {
			return
		}
		updateState(scene: scene, activity: stateRestorationActivity)
	}

	func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
		guard let currentActivity = userActivity else {
			return nil
		}
		let activity = NSUserActivity(activityType: Self.activityType)
		activity.userInfo = currentActivity.userInfo
		return activity
	}

	private func updateState(scene: UIWindowScene, activity: NSUserActivity?) {
		guard let urlString = activity?.userInfo?["url"] as? String,
					let url = URL(string: urlString),
					url.scheme == "file" else {
						// We’re probably not meant to be here?
						handleLoadFailed(scene: scene)
						return
					}

		do {
			let package = try PLPackageManager.sharedInstance().addDebFile(url)
			navigationController?.viewControllers = [ZBPackageViewController(package: package)]

			let scene = window!.windowScene!
			scene.title = url.lastPathComponent
			#if targetEnvironment(macCatalyst)
			scene.titlebar?.representedURL = url
			#endif
		} catch {
			handleLoadFailed(scene: scene, error: error)
		}
	}

	private func handleLoadFailed(scene: UIWindowScene, error: Error? = nil) {
		if let viewController = navigationController?.viewControllers.first,
			 type(of: viewController) == ZBPackageViewController.self {
			// Just ignore, we already loaded something.
			return
		}

		let alertController = UIAlertController(title: .localize("Couldn’t open file because an error occurred."),
																						message: error?.localizedDescription,
																						preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: .ok, style: .cancel, handler: { _ in
			let options = UIWindowSceneDestructionRequestOptions()
			options.windowDismissalAnimation = .decline
			UIApplication.shared.requestSceneSessionDestruction(scene.session, options: options, errorHandler: nil)
		}))
		navigationController?.present(alertController, animated: true, completion: nil)
	}

}

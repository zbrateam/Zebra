//
//  UIApplication+Additions.swift
//  NewTerm (iOS)
//
//  Created by Adam Demasi on 22/9/21.
//

import UIKit

extension UIApplication {

	func runningSceneSessions(withIdentifier identifier: String) -> Set<UISceneSession> {
		return openSessions.filter { session in
			if let delegate = session.scene?.delegate as? IdentifiableSceneDelegate {
				return type(of: delegate).activityType == identifier
			}
			return false
		}
	}

	func activateScene(userActivity: NSUserActivity,
										 requestedBy requestingScene: UIScene? = nil,
										 asSingleton: Bool = true,
										 withProminentPresentation prominentPresentation: Bool = false) {
		let options: UIScene.ActivationRequestOptions
		if #available(iOS 15, *) {
			let windowSceneOptions = UIWindowScene.ActivationRequestOptions()
#if !targetEnvironment(macCatalyst)
			if prominentPresentation {
				windowSceneOptions.preferredPresentationStyle = .prominent
			}
#endif
			options = windowSceneOptions
		} else {
			options = UIScene.ActivationRequestOptions()
		}
		options.requestingScene = requestingScene

		// Find an existing scene, if one exists. If it does, the activate call will bring that into
		// focus instead of creating a new scene.
		let sceneSession = asSingleton ? runningSceneSessions(withIdentifier: userActivity.activityType).first : nil
		requestSceneSessionActivation(sceneSession,
																	userActivity: userActivity,
																	options: options,
																	errorHandler: nil)
	}

}

protocol IdentifiableSceneDelegate: AnyObject {
	static var activityType: String { get }
}

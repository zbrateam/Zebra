//
//  PLPackage+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 11/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Plains

extension Package {

	// MARK: - Actions

	@objc var mightRequirePayment: Bool {
		// TODO: ? Is this used by something?
		false
	}

	@objc var possibleActions: ZBPackageActionType {
		var actions: ZBPackageActionType = []
		if let _ = source {
			if isInstalled {
				actions.insert(.reinstall)
				if hasUpdate {
					actions.insert(.upgrade)
				}
				if lesserVersions.count > 1 {
					actions.insert(.downgrade)
				}
			} else {
				actions.insert(.install)
			}
		}
		if isInstalled {
			actions.insert(.remove)
		}
		return actions
	}

	@objc var possibleExtraActions: ZBPackageExtraActionType {
		var actions: ZBPackageExtraActionType = []
		if isInstalled {
			actions.insert(isHeld ? .showUpdates : .hideUpdates)
		}
		return actions
	}

}

//
//  PLPackage+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 11/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension PLPackage {

	// MARK: - Actions

	@objc var mightRequirePayment: Bool {
		// TODO: ? Is this used by something?
		false
	}

	@objc var possibleActions: ZBPackageActionType {
		var actions: ZBPackageActionType = []
		if let _ = source {
			if installed {
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
		if installed {
			actions.insert(.remove)
		}
		return actions
	}

	@objc var possibleExtraActions: ZBPackageExtraActionType {
		var actions: ZBPackageExtraActionType = []
		if installed {
			actions.insert(held ? .showUpdates : .hideUpdates)
		}
		return actions
	}

}

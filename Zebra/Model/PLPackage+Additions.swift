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

	// We do a bunch of cleaning up we shouldn‘t really need to do because Packix.
	private static let osVersionRegex = "::ios(ios)?(\\d+(\\.\\d+)*).*$"

	var isCommercial: Bool { tags.contains("cydia::commercial") }

	var isCompatible: Bool {
		let minimumTag = tags.first(where: { $0.matches(regex: "^compatible_min\(Self.osVersionRegex)", options: .caseInsensitive) })
		let maximumTag = tags.first(where: { $0.matches(regex: "^compatible_max\(Self.osVersionRegex)", options: .caseInsensitive) })
		let minimumVersion = minimumTag?.replacingOccurrences(regex: "^compatible_min\(Self.osVersionRegex)", with: "$2", options: .caseInsensitive) ?? "0.0"
		let maximumVersion = maximumTag?.replacingOccurrences(regex: "^compatible_max\(Self.osVersionRegex)", with: "$2", options: .caseInsensitive) ?? "99.99"
		let systemVersion = UIDevice.current.systemVersion
		return minimumVersion.compare(systemVersion, options: .numeric) != .orderedDescending &&
			maximumVersion.compare(systemVersion, options: .numeric) != .orderedAscending
	}

	// MARK: - Actions

	var possibleActions: ZBPackageActionType {
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

	var possibleExtraActions: ZBPackageExtraActionType {
		var actions: ZBPackageExtraActionType = []
		if isInstalled {
			actions.insert(isHeld ? .showUpdates : .hideUpdates)
		}
		return actions
	}

}

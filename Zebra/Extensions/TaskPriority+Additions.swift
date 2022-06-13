//
//  TaskPriority+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 13/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension TaskPriority {
	// It‘s deprecated, but still seems to be used by the system in some instances. Not checking for
	// this can cause a runtime warning about QoS .userInteractive depending on QoS .default, which is
	// a potential deadlock. Since TaskPriority.init(rawValue:) is public, should be safe to do this.
	private static let deprecatedUserInteractive = TaskPriority(rawValue: 33)

	var qos: DispatchQoS {
		switch self {
		case .medium:
			return .default
		case .low, .utility:
			return .utility
		case .background:
			return .background
		case .high, .userInitiated:
			return .userInitiated
		case .deprecatedUserInteractive:
			return .userInteractive
		default:
			return .default
		}
	}
}

//
//  TaskPriority+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 13/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension TaskPriority {
	var qos: DispatchQoS {
		switch self {
		case .high:          return .userInitiated
		case .medium:        return .default
		case .low:           return .utility
		case .utility:       return .utility
		case .background:    return .background
		case .userInitiated: return .userInitiated
		default:             return .default
		}
	}
}

//
//  NetworkController.swift
//  Zebra
//
//  Created by Adam Demasi on 16/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Network

class NetworkController: NSObject {

	private static let monitor: NWPathMonitor = {
		let monitor = NWPathMonitor()
		monitor.start(queue: .main)
		return monitor
	}()

	static var currentPath: NWPath { monitor.currentPath }

	static var isOnline: Bool {
		switch currentPath.status {
		case .satisfied:
			true
		case .unsatisfied, .requiresConnection:
			false
		@unknown default:
			false
		}
	}

}

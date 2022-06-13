//
//  DeviceCommands.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

@objc(ZBDeviceCommands)
class DeviceCommands: NSObject {

	@objc class func restartSystemApp() {
		Task(priority: .userInitiated) {
			if SlingshotController.isSimulated {
				return
			}
			try await Command.execute("sbreload", arguments: [])
		}
	}

	@objc class func reboot() {
		Task(priority: .userInitiated) {
			if SlingshotController.isSimulated {
				return
			}

			#if targetEnvironment(macCatalyst)
			// TODO: I’m sure we can issue a proper macOS reboot signal somehow, right?
			return
			#else
			do {
				if try await Command.execute("sync", arguments: [], asRoot: true) != nil {
					if try await Command.execute("ldrestart", arguments: [], asRoot: true) != nil {
						return
					}
				}
			} catch {
				// Fall through
			}

			// ldrestart failed, try reboot
			try await Command.execute("reboot", arguments: [], asRoot: true)
			#endif
		}
	}

	@objc class func uicache(paths: [String]?) {
		Task(priority: .userInitiated) {
			let args = paths == nil || paths!.isEmpty ? ["-a"] : ["-p"] + paths!
			try await Command.execute("uicache", arguments: args)
		}
	}

	@objc class func relaunchZebra() {
		Task(priority: .userInitiated) {
			// If you change this, remember to update the relaunch daemon
			let seconds = 1

			if !SlingshotController.isSimulated {
				try await Command.execute("launchctl", arguments: ["start", "com.getzbra.zebra2.Relaunch"], asRoot: true)
			}

			await UIApplication.shared.suspend()
			DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
				exit(0)
			}
		}
	}

}

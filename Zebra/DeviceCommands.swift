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

	@discardableResult
	@objc class func restartSystemApp() -> Bool {
		if SlingshotController.isSimulated {
			return true
		}
		return Command.execute("sbreload", arguments: []) != nil
	}

	@discardableResult
	@objc class func reboot() -> Bool {
		if SlingshotController.isSimulated {
			return true
		}

		#if targetEnvironment(macCatalyst)
		// TODO: I’m sure we can issue a proper macOS reboot signal somehow, right?
		return true
		#else
		if Command.execute("sync", arguments: [], asRoot: true) != nil &&
				Command.execute("ldrestart", arguments: [], asRoot: true) != nil {
			return true
		}

		// ldrestart failed, try reboot
		return Command.execute("reboot", arguments: [], asRoot: true) != nil
		#endif
	}

	@discardableResult
	@objc class func uicache(paths: [String]?) -> Bool {
		let args = paths == nil || paths!.isEmpty ? ["-a"] : ["-p"] + paths!
		return Command.execute("uicache", arguments: args) != nil
	}

	@objc class func relaunchZebra() {
		// If you change this, remember to update the relaunch daemon
		let seconds = 1

		if !SlingshotController.isSimulated {
			Command.execute("launchctl", arguments: ["start", "xyz.willy.Zebra.Relaunch"], asRoot: true)
		}

		UIApplication.shared.suspend()
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(seconds)) {
			exit(0)
		}
	}

}

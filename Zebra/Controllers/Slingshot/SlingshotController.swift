//
//  SlingshotController.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

@objc(ZBSlingshotController)
class SlingshotController: NSObject {

	@objc static let superslingPath = "\(Device.distroRootPrefix)/libexec/zebra/supersling"

	#if targetEnvironment(simulator)
	@objc static let isSimulated = true
	#elseif targetEnvironment(macCatalyst)
	@objc static let isSimulated = false
	#else
	@objc static let isSimulated = !FileManager.default.fileExists(atPath: superslingPath)
	#endif

	@objc static func testSlingshot() throws {
		if isSimulated {
			// Nothing to do because there’s no slingshot anyway.
			return
		}

		// Stat supersling. This will be the first thing to fail if it doesn’t exist.
		var slingStat = stat()
		if stat(superslingPath, &slingStat) != 0 {
			throw NSError(domain: NSCocoaErrorDomain,
										code: 50,
										userInfo: [
											NSLocalizedDescriptionKey: String.localize("Unable to access su/sling. Please verify that \(superslingPath) exists.")
										])
		}

		// Make sure it’s owned by root:wheel.
		if slingStat.st_uid != 0 || slingStat.st_gid != 0 {
			throw NSError(domain: NSCocoaErrorDomain,
										code: 51,
										userInfo: [
											NSLocalizedDescriptionKey: String.localize("su/sling is not owned by root:wheel. Please verify the permissions of the file located at \(superslingPath).")
										])
		}

		// Make sure the setuid and setgid bits are set in the file mode.
		if (slingStat.st_mode & S_ISUID) == 0 || (slingStat.st_mode & S_ISGID) == 0 {
			throw NSError(domain: NSCocoaErrorDomain,
										code: 52,
										userInfo: [
											NSLocalizedDescriptionKey: String.localize("su/sling does not have permission to set the uid or gid. Please verify the permissions of the file located at \(superslingPath).")
										])
		}
	}

}

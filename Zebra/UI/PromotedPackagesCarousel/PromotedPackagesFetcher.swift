//
//  PromotedPackageFetcher.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

struct PromotedPackagesFetcher {

	static func getCached(sourceUUID: String) -> [PromotedPackageBanner]? {
		do {
			let data = try Data(contentsOf: SourceRefreshController.listsURL/"\(sourceUUID)sileo-featured.json")
			let json = try JSONDecoder().decode(PromotedPackagesObject.self, from: data)
			return json.banners
		} catch {
			// Ignore error, therefore ignoring the local cache
			return nil
		}
	}

}

//
//  PromotedPackageFetcher.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import Plains

struct PromotedPackagesFetcher {

	private static func getFeaturedItems(sourceUUID: String) -> [PromotedPackageBanner]? {
		if let data = try? Data(contentsOf: SourceRefreshController.listsURL/"\(sourceUUID)sileo-featured.json"),
			 let json = try? JSONDecoder().decode(PromotedPackagesObject.self, from: data),
			 !json.banners.isEmpty {
			return json.banners
				.compactMap { item in
					guard let url = item.url.secureURL else {
						return nil
					}
					return PromotedPackageBanner(title: item.title,
																			 package: item.package,
																			 url: url,
																			 displayText: item.displayText,
																			 hideShadow: item.hideShadow)
				}
		}
		return nil
	}

	static func getCached(sourceUUID: String) async -> [PromotedPackageBanner] {
		if let items = getFeaturedItems(sourceUUID: sourceUUID),
			 !items.isEmpty {
			return items
		}

		// Let’s do our best to find some banners to show.
		if let source = SourceManager.shared.source(forUUID: sourceUUID) {
			return Array(await PackageManager.shared
				.fetchPackages(in: source) { $0["Name"] != nil && $0.headerURL != nil && $0.role == .user && $0.isCompatible }
				.compactMap { item in
					guard let url = item.headerURL?.secureURL else {
						return nil
					}
					return PromotedPackageBanner(title: item.name,
																			 package: item.identifier,
																			 url: url,
																			 displayText: true,
																			 hideShadow: false)
				}
				.shuffled()
				.safeSubSequence(0..<20))
		}

		return []
	}

	static func getHomeCarouselItems() async -> [PromotedPackageBanner] {
		// Combine source featured banners with a random handful of compatible packages with banners.
		let featuredItems = SourceManager.shared.sources
			.flatMap { getFeaturedItems(sourceUUID: $0.uuid) ?? [] }
			.compactMap { PromotedPackageBanner(title: $0.title,
																					package: $0.package,
																					url: $0.url,
																					displayText: true,
																					hideShadow: false) }
		return Array(featuredItems
			.shuffled()
			.safeSubSequence(0..<20))
	}

}

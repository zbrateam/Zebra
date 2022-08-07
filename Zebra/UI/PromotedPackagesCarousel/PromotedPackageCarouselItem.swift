//
//  PromotedPackageCarouselItem.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

struct PromotedPackagesObject: Codable {
	let productDataClass, itemSize: String
	let itemCornerRadius: Int
	let banners: [PromotedPackageBanner]

	enum CodingKeys: String, CodingKey {
		case productDataClass = "class"
		case itemSize, itemCornerRadius, banners
	}
}

// MARK: - Banner

struct PromotedPackageBanner: Codable, Hashable {
	let title, package: String
	let url: URL
	let displayText, hideShadow: Bool?
}

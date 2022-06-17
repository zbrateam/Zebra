//
//  CarouselItem.swift
//  Zebra
//
//  Created by Adam Demasi on 5/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

struct CarouselItem: Codable, Hashable {
	internal var uuid = UUID()

	let title: String
	let subtitle: String?
	let url: URL?
	let imageURL: URL?

	func hash(into hasher: inout Hasher) {
		hasher.combine(uuid)
		hasher.combine(title)
		hasher.combine(subtitle)
		hasher.combine(url)
		hasher.combine(imageURL)
	}
}

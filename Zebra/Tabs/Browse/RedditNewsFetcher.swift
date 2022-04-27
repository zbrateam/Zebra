//
//  RedditNewsFetcher.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

fileprivate struct RedditNewsRoot: Codable {
	let data: [RedditNewsItem]
}

fileprivate struct RedditNewsItem: Codable {
	let title: String
	let url: String
	let thumbnail: String?
	let tags: RedditNewsTag?
}

fileprivate enum RedditNewsTag: String, Codable {
	case news = "news"
	case release = "release"
	case releaseFree = "release,free"
	case releasePaid = "release,paid"
	case update = "update"
	case updateFree = "update,free"
	case updatePaid = "update,paid"
	case upcoming = "upcoming"

	var text: String {
		switch self {
		case .news:        return .localize("News")
		case .release:     return .localize("Release")
		case .releaseFree: return .localize("Free Release")
		case .releasePaid: return .localize("Paid Release")
		case .update:      return .localize("Update")
		case .updateFree:  return .localize("Free Update")
		case .updatePaid:  return .localize("Paid Update")
		case .upcoming:    return .localize("Upcoming")
		}
	}
}

fileprivate extension String {
	var redditAPIUnescaped: String {
		self
			.replacingOccurrences(of: "&lt;", with: "<")
			.replacingOccurrences(of: "&gt;", with: ">")
			.replacingOccurrences(of: "&amp;", with: "&")
	}
}

class RedditNewsFetcher {

	private static let cacheURL = Device.cacheURL/"reddit-news.json"

	static func getCached() -> [CarouselItem]? {
		do {
			let json = try Data(contentsOf: cacheURL)
			return try JSONDecoder().decode([CarouselItem].self, from: json)
		} catch {
			// Ignore error, therefore ignoring the local cache
			return nil
		}
	}

	static func fetch() async throws -> [CarouselItem] {
		let request = URLRequest(url: URL(string: "https://zbrateam.github.io/api/reddit-news-relevance.json")!)

		let json: RedditNewsRoot = try await HTTPRequest.json(for: request)
		let items = json.data.compactMap { item in
			CarouselItem(title: item.title.redditAPIUnescaped,
									 subtitle: (item.tags ?? .news).text,
									 url: URL(string: item.url.redditAPIUnescaped)!,
									 imageURL: URL(string: item.thumbnail?.redditAPIUnescaped ?? ""))
		}

		let cacheJSON = try JSONEncoder().encode(items)
		try cacheJSON.write(to: cacheURL, options: .atomic)
		return items
	}

}

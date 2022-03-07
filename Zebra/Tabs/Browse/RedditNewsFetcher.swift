//
//  RedditNewsFetcher.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

struct RedditData<T: Codable>: Codable {
	let data: T
}

struct RedditListing<T: Codable>: Codable {
	let children: [RedditData<T>]
}

struct RedditPost: Codable {
	let id: String
	let created: TimeInterval
	let title: String
	let linkFlairCSSClass: String
	let permalink: String?
	let thumbnail: String?
	let preview: RedditPreview?
	let mediaMetadata: [String: RedditMediaMetadata]?

	enum CodingKeys: String, CodingKey {
		case id = "id"
		case created = "created_utc"
		case title = "title"
		case linkFlairCSSClass = "link_flair_css_class"
		case permalink = "permalink"
		case thumbnail = "thumbnail"
		case preview = "preview"
		case mediaMetadata = "media_metadata"
	}
}

struct RedditPreview: Codable {
	let images: [RedditPreviewImage]
}

struct RedditPreviewImage: Codable {
	let source: RedditPreviewImageSource
}

struct RedditPreviewImageSource: Codable {
	let url: String
	let width: Int
	let height: Int
}

struct RedditMediaMetadata: Codable {
	let type: String
	let source: RedditMediaSource

	enum CodingKeys: String, CodingKey {
		case type = "e"
		case source = "s"
	}
}

struct RedditMediaSource: Codable {
	let width: Int
	let height: Int
	let url: String?

	enum CodingKeys: String, CodingKey {
		case width = "x"
		case height = "y"
		case url = "u"
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
		var url = URLComponents(string: "https://www.reddit.com/r/jailbreak/search.json")!
		url.queryItems = [
			URLQueryItem(name: "q", value: "subreddit:jailbreak (flair:Release OR flair:Update OR flair:Upcoming OR flair:News)"),
			URLQueryItem(name: "restrict_sr", value: "on"),
			URLQueryItem(name: "sort", value: "relevance"),
			URLQueryItem(name: "t", value: "month")
		]
		let request = URLRequest(url: url.url!)

		let json: RedditData<RedditListing<RedditPost>> = try await HTTPRequest.json(for: request)
		let items = (json.data.children as [RedditData<RedditPost>])
			.sorted(by: { a, b in a.data.created > b.data.created })
			.compactMap { item -> CarouselItem? in
				guard let permalink = item.data.permalink else {
					return nil
				}
				var url = URLComponents(string: "https://www.reddit.com/")!
				url.path = permalink.redditAPIUnescaped

				var thumbnailURL: URL?
				switch item.data.thumbnail {
				case .none, "nsfw":
					break

				case .some(let urlString):
					if let previewImage = item.data.preview?.images.first?.source,
						 let previewImageURL = URL(string: previewImage.url) {
						thumbnailURL = URL(string: previewImageURL.absoluteString.redditAPIUnescaped)
					} else if let mediaItem = item.data.mediaMetadata?.first(where: { _, value in value.type == "Image" && value.source.url != nil })?.value,
										let mediaURL = URL(string: mediaItem.source.url!) {
						thumbnailURL = URL(string: mediaURL.absoluteString.redditAPIUnescaped)
					} else if urlString != "self" {
						thumbnailURL = URL(string: urlString.redditAPIUnescaped)
					}
				}

				var cleanedTitle = item.data.title.redditAPIUnescaped
				if cleanedTitle.starts(with: "["),
					 let bracketIndex = cleanedTitle.range(of: "] ") {
					cleanedTitle = String(cleanedTitle.suffix(from: bracketIndex.upperBound))
				}
				return CarouselItem(title: cleanedTitle,
														subtitle: item.data.linkFlairCSSClass,
														url: url.url!,
														imageURL: thumbnailURL)
			}

		let cacheJSON = try JSONEncoder().encode(items)
		try cacheJSON.write(to: cacheURL, options: .atomic)
		return items
	}

}

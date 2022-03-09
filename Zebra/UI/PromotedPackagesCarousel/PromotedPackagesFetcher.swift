//
//  PromotedPackageFetcher.swift
//  Zebra
//
//  Created by MidnightChips on 3/8/22.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
class PromotedPackagesFetcher {
    private static let cacheURL = Device.cacheURL / "reddit-news.json"

    static func getCached(repo: URL) -> [PromotedPackageBanner]? {
        do {
            let json = try Data(contentsOf: Device.cacheURL / "\(getEscapedName(repo: repo.absoluteString))")
            return try JSONDecoder().decode([PromotedPackageBanner].self, from: json)
        } catch {
            // Ignore error, therefore ignoring the local cache
            return nil
        }
    }

    static func getEscapedName(repo: String) -> String {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)

        let newFilename = repo
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
        return newFilename
    }

    static func fetch(repo: URL) async throws -> [PromotedPackageBanner] {
        // let requestUrl = URL(string: "https://chariz.com/api/sileo/featured.json")!
        let requestUrl = repo / "sileo-featured.json"
        let request = URLRequest(url: requestUrl)
        do {
            let json: PromotedPackagesObject = try await HTTPRequest.json(for: request)
            let items = (json.banners as [PromotedPackageBanner])
            let cacheJSON = try JSONEncoder().encode(items)
            try cacheJSON.write(to: Device.cacheURL / "\(getEscapedName(repo: repo.absoluteString)).json", options: .atomic)
            return items
        } catch {
            return []
        }
    }
}

//
//  HTTPRequest.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class HTTPRequest {

	static func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
		return try await withCheckedThrowingContinuation { result in
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				do {
					if let error = error {
						throw error
					}
					guard let data = data,
								let response = response as? HTTPURLResponse,
								response.statusCode == 200 else {
						throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: nil)
					}
					result.resume(returning: (data, response))
				} catch {
					result.resume(throwing: error)
				}
			}
			task.resume()
		}
	}

	static func json<T: Codable>(for request: URLRequest) async throws -> T {
		let (data, _) = try await data(for: request)
		return try JSONDecoder().decode(T.self, from: data)
	}

}

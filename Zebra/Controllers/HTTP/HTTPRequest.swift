//
//  HTTPRequest.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

class HTTPRequest {

	static func data(for request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
		return try await withCheckedThrowingContinuation { result in
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				do {
					if let error = self.error(for: response, error: error) {
						throw error
					}
					guard let data = data,
								let response = response as? HTTPURLResponse else {
						throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse)
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

	private static func error(for response: URLResponse?, error: Error?) -> NSError? {
		if let error = error {
			return error as NSError
		}
		guard let response = response as? HTTPURLResponse else {
			return NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: nil)
		}
		if response.statusCode < 200 || response.statusCode >= 400 {
			return NSError(domain: NSURLErrorDomain, code: response.statusCode, userInfo: [
				NSLocalizedDescriptionKey: "\(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))"
			])
		}
		return nil
	}

}

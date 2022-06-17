//
//  HTTPRequest.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

enum HTTPError: Error {
	case general(error: Error)
	case statusCode(statusCode: Int, response: HTTPURLResponse)
	case badResponse

	var response: HTTPURLResponse? {
		switch self {
		case .general(_), .badResponse:
			return nil
		case .statusCode(_, let response):
			return response
		}
	}

	private var statusCodeString: String {
		switch self {
		case .statusCode(let statusCode, _):
			return "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode).localizedCapitalized)"

		default: fatalError()
		}
	}

	var localizedDescription: String {
		switch self {
		case .general(let error):
			return error.localizedDescription

		case .statusCode(let statusCode, _):
			switch statusCode {
			case 401, 403:
				return "\(String.localize("The server denied access.")) (\(statusCodeString))"
			case 402:
				return "\(String.localize("The server denied access because you haven’t purchased this item.")) (\(statusCodeString))"
			case 500..<600:
				return "\(String.localize("The server is temporarily experiencing issues. Try again later.")) (\(statusCodeString))"
			default:
				return "\(String.localize("The server returned an unexpected error.")) (\(statusCodeString))"
			}

		case .badResponse:
			return .localize("The server returned an unexpected response.")
		}
	}
}

class HTTPRequest {

	struct Response<T> {
		let statusCode: Int
		let data: T?
		let response: HTTPURLResponse?
		let error: Error?
	}

	static func data(session: URLSession = .shared, for request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
		return try await withCheckedThrowingContinuation { result in
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				do {
					if let error = self.error(for: response, error: error, forAsync: true) {
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

	static func json<T: Codable>(session: URLSession = .shared, for request: URLRequest) async throws -> T {
		let (data, _) = try await data(session: session, for: request)
		return try JSONDecoder().decode(T.self, from: data)
	}

	static func download(session: URLSession = .shared, for request: URLRequest, completion: @escaping (Response<URL>) -> Void) {
		let task = session.downloadTask(with: request) { url, response, error in
			if let error = self.error(for: response, error: error) {
				completion(Response(statusCode: 0, data: nil, response: nil, error: error))
				return
			}
			guard let url = url,
						let response = response as? HTTPURLResponse else {
				completion(Response(statusCode: 0, data: url, response: nil, error: HTTPError.badResponse))
				return
			}
			completion(Response(statusCode: response.statusCode, data: url, response: response, error: nil))
		}
		task.resume()
	}

	private static func error(for response: URLResponse?, error: Error?, forAsync: Bool = false) -> Error? {
		if let error = error {
			return HTTPError.general(error: error)
		}

		guard let response = response as? HTTPURLResponse else {
			return HTTPError.badResponse
		}

		if forAsync {
			switch response.statusCode {
			case 200..<300:
				return nil

			default:
				return HTTPError.statusCode(statusCode: response.statusCode, response: response)
			}
		}
		return nil
	}

}

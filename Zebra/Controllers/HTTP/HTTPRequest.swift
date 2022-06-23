//
//  HTTPRequest.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

enum HTTPError: Error, LocalizedError {
	case general(error: Error)
	case cancelled
	case badResponse
	case statusCode(statusCode: Int, response: HTTPURLResponse)

	var response: HTTPURLResponse? {
		switch self {
		case .general(_), .cancelled, .badResponse:
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

		case .cancelled:
			return .localize("The request was cancelled.")

		case .badResponse:
			return .localize("The server returned an unexpected response.")

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
		}
	}
}

struct Response<T> {
	let statusCode: Int
	let data: T?
	let response: HTTPURLResponse?
	let error: Error?
}

extension URLSession {

	func data(with request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
		var task: URLSessionTask!

		return try await withTaskCancellationHandler { [task] in
			task?.cancel()
		} operation: {
			try await withCheckedThrowingContinuation { result in
				task = dataTask(with: request) { data, response, error in
					if let error = self.error(for: response, error: error, forAsync: true) {
						result.resume(throwing: HTTPError.general(error: error))
					} else {
						guard let response = response as? HTTPURLResponse else {
							result.resume(throwing: HTTPError.badResponse)
							return
						}
						result.resume(returning: (data!, response))
					}
				}
				task.resume()
			}
		}
	}

	func json<T: Codable>(with request: URLRequest, type: T.Type = T.self, decoder: JSONDecoder = .init()) async throws -> T {
		let (data, _) = try await self.data(with: request)
		return try decoder.decode(T.self, from: data)
	}

	func download(with request: URLRequest, completion: @escaping (Response<URL>) -> Void) {
		let task = downloadTask(with: request) { url, response, error in
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

	private func error(for response: URLResponse?, error: Error?, forAsync: Bool = false) -> Error? {
		if let error = error as? NSError {
			switch (error.domain, error.code) {
			case (NSURLErrorDomain, NSURLErrorCancelled):
				return HTTPError.cancelled

			default:
				return HTTPError.general(error: error)
			}
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

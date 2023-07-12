//
//  HTTPRequest.swift
//  Zebra
//
//  Created by Adam Demasi on 4/3/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

enum HTTPError: Error, LocalizedError {
	case general(error: Error)
	case cancelled
	case badResponse
	case status(response: HTTPResponse)

	var response: HTTPResponse? {
		switch self {
		case .general(_), .cancelled, .badResponse:
			nil
		case .status(let response):
			response
		}
	}

	private var statusCodeString: String {
		switch self {
		case .status(let response):
			"\(response.status.code) \(response.status.reasonPhrase)"

		default: fatalError()
		}
	}

	var localizedDescription: String {
		switch self {
		case .general(let error):
			error.localizedDescription

		case .cancelled:
			.localize("The request was cancelled.")

		case .badResponse:
			.localize("The server returned an unexpected response.")

		case .status(let response):
			switch response.status {
			case .unauthorized, .forbidden:
				"\(String.localize("The server denied access.")) (\(statusCodeString))"

			case .paymentRequired:
				"\(String.localize("The server denied access because you haven’t purchased this item.")) (\(statusCodeString))"

			default:
				switch response.status.kind {
				case .serverError:
					"\(String.localize("The server is temporarily experiencing issues. Try again later.")) (\(statusCodeString))"

				default:
					"\(String.localize("The server returned an unexpected error.")) (\(statusCodeString))"
				}
			}
		}
	}
}

struct Response<T> {
	let data: T?
	let response: HTTPResponse?
	let error: Error?

	var statusCode: Int { response?.status.code ?? 0 }
}

extension URLSession {

	func data(with request: URLRequest) async throws -> (data: Data, response: HTTPResponse) {
		do {
			let (data, response) = try await data(for: request)
			if let error = self.error(for: response, error: nil, forAsync: true) {
				throw HTTPError.general(error: error)
			}
			guard let response = (response as? HTTPURLResponse)?.httpResponse else {
				throw HTTPError.badResponse
			}
			return (data, response)
		} catch {
			throw HTTPError.general(error: self.error(for: nil, error: error, forAsync: true) ?? error)
		}
	}

	func json<T: Codable>(with request: URLRequest, type: T.Type = T.self, decoder: JSONDecoder = .init()) async throws -> T {
		let (data, _) = try await self.data(with: request)
		return try decoder.decode(T.self, from: data)
	}

	func download(with request: URLRequest, completion: @escaping (Response<URL>) -> Void) {
		let task = downloadTask(with: request) { url, response, error in
			if let error = self.error(for: response, error: error) {
				completion(Response(data: nil, response: nil, error: error))
				return
			}

			guard let url = url,
						let response = (response as? HTTPURLResponse)?.httpResponse else {
				completion(Response(data: url, response: nil, error: HTTPError.badResponse))
				return
			}
			completion(Response(data: url, response: response, error: nil))
		}
		task.resume()
	}

	private func error(for urlResponse: URLResponse?, error: Error?, forAsync: Bool = false) -> Error? {
		if let error = error as? NSError {
			switch (error.domain, error.code) {
			case (NSURLErrorDomain, NSURLErrorCancelled):
				return HTTPError.cancelled

			default:
				return HTTPError.general(error: error)
			}
		}

		guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
			return HTTPError.badResponse
		}

		if forAsync {
			switch response.status.kind {
			case .informational, .successful, .redirection: // 1xx-3xx
				return nil

			case .clientError, .serverError, .invalid: // 4xx-5xx
				return HTTPError.status(response: response)
			}
		}
		return nil
	}

}

//
//  URLSession+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

extension URLSession {

	static let standard: URLSession = {
		let config = URLSessionConfiguration.ephemeral.copy() as! URLSessionConfiguration
		// Disable setting or storing cookies. Requests made via zbra_standardSession shouldn’t be
		// using cookies.
		config.httpCookieStorage = nil
		config.httpAdditionalHeaders = URLController.httpHeaders
		config.tlsMinimumSupportedProtocolVersion = .TLSv12
		return URLSession(configuration: config)
	}()

	static let download: URLSession = {
		let config = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
		// Disable setting or storing cookies. Requests made via zbra_standardSession shouldn’t be
		// using cookies.
		config.httpMaximumConnectionsPerHost = 8
		config.httpAdditionalHeaders = URLController.aptHeaders
		config.tlsMinimumSupportedProtocolVersion = .TLSv12
		return URLSession(configuration: config)
	}()

}

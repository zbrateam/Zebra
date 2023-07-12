//
//  URLSession+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation
import HTTPTypes

extension URLSession {

	static let standard: URLSession = {
		let config = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
		config.httpCookieStorage = nil
		config.httpCookieAcceptPolicy = .never
		config.httpAdditionalHeaders = URLController.httpHeaders.dictionary
		config.tlsMinimumSupportedProtocolVersion = .TLSv12
		return URLSession(configuration: config)
	}()

	static let image: URLSession = {
		let config = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
		config.urlCache = nil
		config.httpCookieStorage = nil
		config.httpCookieAcceptPolicy = .never
		config.httpAdditionalHeaders = URLController.httpHeaders.dictionary
		config.tlsMinimumSupportedProtocolVersion = .TLSv12
		return URLSession(configuration: config)
	}()

	static let download: URLSession = {
		let config = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
		config.httpCookieStorage = nil
		config.httpCookieAcceptPolicy = .never
		config.httpAdditionalHeaders = URLController.aptHeaders.dictionary
		config.httpShouldUsePipelining = true
		config.tlsMinimumSupportedProtocolVersion = .TLSv12
		config.shouldUseExtendedBackgroundIdleMode = true
		return URLSession(configuration: config)
	}()

}

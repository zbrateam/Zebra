//
//  SourceFileHandler.swift
//  Zebra
//
//  Created by Adam Demasi on 25/5/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import Foundation

protocol SourceFileHandlerProtocol: AnyObject {
	typealias Job = SourceRefreshController.Job

	func process(sourceFile: SourceFile, job: Job) async throws -> Job?
}

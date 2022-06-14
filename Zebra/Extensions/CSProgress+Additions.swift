//
//  CSProgress+Additions.swift
//  Zebra
//
//  Created by Adam Demasi on 13/6/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

import CSProgress

public typealias Progress = CSProgress

extension CSProgress {
	var isFinished: Bool { completedUnitCount == totalUnitCount }
}

//
//  Darwin+Extensions.swift
//  Zebra
//
//  Created by Adam Demasi on 8/2/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

// Macros copied from <sys/wait.h>
fileprivate func _WSTATUS(_ value: Int32) -> Int32 {
	return value & 0177
}

func WIFEXITED(_ value: Int32) -> Bool {
	return _WSTATUS(value) == 0
}

func WEXITSTATUS(_ value: Int32) -> Int32 {
	return (value >> 8) & 0xff
}

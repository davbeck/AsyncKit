//
//  Errors.swift
//  overwatch-ios
//
//  Created by David Beck on 1/23/18.
//  Copyright © 2018 ACS Technologies Group, Inc. All rights reserved.
//

import Foundation


public func CancelledError() -> Swift.Error {
	return CocoaError(.userCancelled)
}


extension Error {
	public var isCancelled: Bool {
		switch self {
		case let error as CocoaError:
			return error.code == .userCancelled
		case let error as URLError:
			return error.code == .cancelled
		default:
			return false
		}
	}
}


public struct UnexpectedError: Error, CustomStringConvertible {
	public let info: String
	public let file: String
	public let line: Int
	public let function: String
	
	public init(_ info: String = "", file: String = #file, line: Int = #line, function: String = #function) {
		self.info = info
		self.file = file
		self.line = line
		self.function = function
	}
	
	public var description: String {
		return "Unexpected error, \(info) in \(file):\(line) - \(function)"
	}
}

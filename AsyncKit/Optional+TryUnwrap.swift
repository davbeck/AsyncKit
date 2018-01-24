import Foundation


public struct OptionalUnwrapError: Error, CustomStringConvertible {
	let message: String?
	let wrappedType: Any.Type
	
	init(message: String? = nil, wrappedType: Any.Type) {
		self.message = message
		self.wrappedType = wrappedType
	}
	
	public var description: String {
		return "Optional<\(wrappedType)> was nil: \(message ?? "")"
	}
}


postfix operator *

extension Optional {
	public func unwrap(_ message: String? = nil) throws -> Wrapped {
		if let value = self {
			return value
		} else {
			throw OptionalUnwrapError(message: message, wrappedType: Wrapped.self)
		}
	}
}


extension Optional where Wrapped == String {
	public var isEmpty: Bool {
		return self?.isEmpty ?? true
	}
}

extension Optional where Wrapped == Collection {
	public var isEmpty: Bool {
		return self?.isEmpty ?? true
	}
}


extension Array {
	public init(_ optional: Element?) {
		if let value = optional {
			self.init(arrayLiteral: value)
		} else {
			self.init()
		}
	}
}

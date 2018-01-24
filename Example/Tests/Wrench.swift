import Foundation


struct WrenchError: Error {
	let message: String
}

struct Wrench {
	func `throw`() throws {
		throw WrenchError(message: "a wrench has been thrown in the works")
	}
}

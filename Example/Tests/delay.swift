import XCTest

internal func delay(_ duration: TimeInterval, block: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
		block()
	})
}


struct SimpleError: Error, Equatable {
}


func ==(lhs: SimpleError, rhs: SimpleError) -> Bool {
	return true
}

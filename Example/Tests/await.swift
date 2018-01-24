import XCTest
import AsyncKit


struct WaitFailure: Swift.Error {
	let result: XCTWaiter.Result
}

extension Promise {
	func expectation(description: String = "Promise", shouldFailOnCatch: Bool = true, file: StaticString = #file, line: UInt = #line) -> XCTestExpectation {
		let expectation = XCTestExpectation(description: description)
		
		`catch`({ error in
			if shouldFailOnCatch {
				XCTFail("\(error)", file: file, line: line)
			}
		})
			.always({
				expectation.fulfill()
			})
		
		return expectation
	}
	
	
	func await(description: String = "Promise", timeout: TimeInterval = 20, shouldFailOnCatch: Bool = true, file: StaticString = #file, line: UInt = #line) throws -> Value {
		var result: Result<Value>?
		let waitResult = XCTWaiter.wait(for: [
			self
				.then({ result = Result.success($0) })
				.catch({ result = Result.failure($0) })
				.expectation(description: description, shouldFailOnCatch: shouldFailOnCatch),
			], timeout: timeout)
		
		guard waitResult == .completed else {
			XCTFail("\(description) wait failed after \(timeout)", file: file, line: line)
			throw WaitFailure(result: waitResult)
		}
		
		return try result.unwrap().unwrap()
	}
}

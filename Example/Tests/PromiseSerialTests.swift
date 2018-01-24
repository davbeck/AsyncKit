import XCTest
import AsyncKit


class PromiseSerialTests: XCTestCase {
	enum Error: Swift.Error {
		case alreadyExcecuting
	}
	
	
	func testSerialMap() throws {
		let numbers = Array((0..<10))
		let expectations = numbers.map({ self.expectation(description: "\($0)") })
		
		let promise = Array(zip(numbers, expectations))
			.serialMap(on: DispatchQueue.global(), { (number, expectation) -> Promise<Int> in
				expectation.fulfill()
				return Promise(value: number)
			})
			.then({ result in
				XCTAssertEqual(result, numbers)
			})
		
		_ = try promise.await(description: "serial map")
		
		wait(for: expectations, timeout: 10, enforceOrder: true)
	}
}

import XCTest
import AsyncKit


class DelegateEmitterTests: XCTestCase {
	func testObserveAsync() throws {
		let expectedPayload = UUID()
		let expectedValues = Array(0..<3)
		let emitter = DelegateEmitter<UUID, Int>()
		
		let expectations = expectedValues.map({ i -> XCTestExpectation in
			let expectation = self.expectation(description: "observer \(i)")
			emitter.observeAsync({ payload in
				XCTAssertEqual(payload, expectedPayload)
				expectation.fulfill()
				
				return Promise(value: i)
			})
			
			return expectation
		})
		
		let values = try emitter.emit(expectedPayload).await()
		XCTAssertEqual(values, expectedValues)
		
		wait(for: expectations, timeout: 5)
	}
	
	func testObserveSync() throws {
		let expectedPayload = UUID()
		let expectedValues = Array(0..<3)
		let emitter = DelegateEmitter<UUID, Int>()
		
		let expectations = expectedValues.map({ i -> XCTestExpectation in
			let expectation = self.expectation(description: "observer \(i)")
			emitter.observe({ payload in
				XCTAssertEqual(payload, expectedPayload)
				expectation.fulfill()
				
				return i
			})
			
			return expectation
		})
		
		let values = try emitter.emit(expectedPayload).await()
		XCTAssertEqual(values, expectedValues)
		
		wait(for: expectations, timeout: 5)
	}
	
	func testObserveVoid() {
		let expectedPayload = UUID()
		let emitter = DelegateEmitter<UUID, Void>()
		
		let expectation = self.expectation(description: "observer")
		emitter.observe({ payload in
			XCTAssertEqual(payload, expectedPayload)
			expectation.fulfill()
		})
		
		wait(for: [
			expectation,
			emitter.emit(expectedPayload)
				.expectation(),
		], timeout: 5)
	}
}

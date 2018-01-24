import XCTest
import AsyncKit


class ObservableOnceTests: XCTestCase {
	func testExistingValue() {
		let observable = ObservableValue<Int>(value: 0)
		
		XCTAssertEqual(observable.once().value, 0)
		
		let filtered = observable.filter({ $0 > 5 })
		let filteredPromise = filtered.once()
		XCTAssertTrue(filteredPromise.isPending)
		
		observable.value = 10
		XCTAssertEqual(filteredPromise.value, 10)
	}
}

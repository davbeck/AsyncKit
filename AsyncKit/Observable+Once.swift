import Foundation


extension Observable {
	public func once() -> Promise<Payload> {
		let promise = Promise<Payload>()
		
		let observer = observe(on: nil) { payload in
			promise.fulfill(payload)
		}
		
		promise.always(on: nil) {
			observer.remove()
		}
		
		return promise
	}
}

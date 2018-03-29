import Foundation


public struct PromiseCheckError: Error {}

public struct TimeoutError: Swift.Error, CustomStringConvertible {
	let timeout: TimeInterval
	
	public init(timeout: TimeInterval) {
		self.timeout = timeout
	}
	
	public var description: String {
		return "Request timed out after \(timeout) seconds."
	}
}

extension Promise {
	/// Wait for all the promises you give it to fulfill, and once they have, fulfill itself
	/// with the array of all fulfilled values.
	public static func all(_ promises: [Promise<Value>]) -> Promise<[Value]> {
		return Promise<[Value]>(work: { fulfill, reject in
			guard !promises.isEmpty else { fulfill([]); return }
			for promise in promises {
				promise.then({ value in
					if !promises.contains(where: { $0.isRejected || $0.isPending }) {
						fulfill(promises.compactMap({ $0.value }))
					}
				}).catch({ error in
					reject(error)
				})
			}
		})
	}
	
	/// Resolves itself after some delay.
	/// - parameter delay: In seconds
	public static func delay(_ delay: TimeInterval) -> Promise<()> {
		return Promise<()>(work: { fulfill, reject in
			DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: {
				fulfill(())
			})
		})
	}
	
	/// This promise will be rejected after a delay.
	public static func timeout<T>(_ timeout: TimeInterval) -> Promise<T> {
		return Promise<T>(work: { fulfill, reject in
			delay(timeout).then(on: nil, { _ in
				reject(TimeoutError(timeout: timeout))
			})
		})
	}
	
	/// Fulfills or rejects with the first promise that completes
	/// (as opposed to waiting for all of them, like `.all()` does).
	public static func race<T>(_ promises: [Promise<T>]) -> Promise<T> {
		guard !promises.isEmpty else { fatalError() }
		
		let racePromise = Promise<T>()
		for promise in promises {
			promise.observe(on: nil, racePromise.complete)
		}
		return racePromise
	}
	
	public func addTimeout(_ timeout: TimeInterval) -> Promise<Value> {
		return Promise.race(Array([self, Promise<Value>.timeout(timeout)]))
	}
	
	@discardableResult
	public func always(on queue: ExecutionContext?, _ onComplete: @escaping () -> Void) -> Promise<Value> {
		let promise = Promise<Value>()
		observe(on: queue) { result in
			onComplete()
			promise.complete(result)
		}
		return promise
	}
	
	@discardableResult
	public func always(_ onComplete: @escaping () -> Void) -> Promise<Value> {
		return always(on: MainContext(), onComplete)
	}
	
	
	public func recover(_ recovery: @escaping (Error) throws -> Promise<Value>) -> Promise<Value> {
		let promise = Promise<Value>()
		then(on: nil, promise.fulfill)
			.catch({ error in
				do {
					try recovery(error).observe(promise.complete)
				} catch (let error) {
					promise.reject(error)
				}
			})
		
		return promise
	}
	
	public func ensure(_ check: @escaping (Value) -> Bool) -> Promise<Value> {
		return then({ (value: Value) -> Value in
			guard check(value) else {
				throw PromiseCheckError()
			}
			return value
		})
	}
	
	
	public static func retry(count: Int, delay: TimeInterval, generate: @escaping () -> Promise<Value>) -> Promise<Value> {
		if count <= 0 {
			return generate()
		}
		return Promise<Value>(work: { fulfill, reject in
			generate().recover({ error in
				return self.delay(delay).then({
					return retry(count: count - 1, delay: delay, generate: generate)
				})
			}).then(fulfill).catch(reject)
		})
	}
	
	public func cancel() {
		reject(CancelledError())
	}
}


public func PromiseTimer(_ delay: TimeInterval) -> Promise<Void> {
	return Promise<Void>.delay(delay)
}

public func PromiseTimer(_ fireDate: Date) -> Promise<Void> {
	return Promise<Void>.delay(fireDate.timeIntervalSinceNow)
}

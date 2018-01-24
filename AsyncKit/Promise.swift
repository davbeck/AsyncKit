import Foundation


public protocol ExecutionContext {
	func execute(_ work: @escaping () -> Swift.Void)
}

extension DispatchQueue: ExecutionContext {
	public func execute(_ work: @escaping () -> Void) {
		async(execute: work)
	}
}

public struct MainContext: ExecutionContext {
	public init() {}
	
	public func execute(_ work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			// this is only safe because it is async
			DispatchQueue.main.async(execute: work)
		}
	}
}

public struct CurrentContext: ExecutionContext {
	public init() {}
	
	public func execute(_ work: @escaping () -> Void) {
		work()
	}
}

extension OperationQueue {
	public func operation<Value>(_ work: @escaping () throws -> Value) -> Promise<Value> {
		let promise = Promise<Value>()
		addOperation {
			do {
				let value = try work()
				promise.fulfill(value)
			} catch {
				promise.reject(error)
			}
		}
		
		return promise
	}
}


public final class Promise<Value>: Observable {
	public typealias Payload = Result<Value>
	public typealias R = Result<Value>
	private var state: Payload?
	private var lock = NSLock()
	private var observers: [Observer<Promise<Value>>] = []
	
	public init() {
		state = nil
	}
	
	public init(value: Value) {
		state = .success(value)
	}
	
	public init(error: Error) {
		state = .failure(error)
	}
	
	public convenience init(queue: DispatchQueue? = .global(), work: @escaping (_ fulfill: @escaping (Value) -> Void, _ reject: @escaping (Error) -> Void) throws -> Void) {
		self.init()
		
		if let queue = queue {
			queue.async {
				do {
					try work(self.fulfill, self.reject)
				} catch let error {
					self.reject(error)
				}
			}
		} else {
			do {
				try work(fulfill, reject)
			} catch let error {
				self.reject(error)
			}
		}
	}
	
	public convenience init(queue: DispatchQueue? = .global(), work: @escaping () throws -> Value) {
		self.init()
		
		if let queue = queue {
			queue.async {
				do {
					try self.fulfill(work())
				} catch let error {
					self.reject(error)
				}
			}
		} else {
			do {
				try fulfill(work())
			} catch let error {
				self.reject(error)
			}
		}
	}
	
	/// - note: This one is "flatMap"
	@discardableResult
	public func then<NewValue>(on queue: ExecutionContext? = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Promise<NewValue>) -> Promise<NewValue> {
		let promise = Promise<NewValue>()
		
		observe(on: queue) { result in
			let newResult = result.map(onFulfilled)
			
			switch newResult {
			case .success(let mapped):
				mapped.observe(promise.complete)
			case .failure(let error):
				promise.reject(error)
			}
		}
		
		return promise
	}
	
	/// - note: This one is "map"
	@discardableResult
	public func then<NewValue>(on queue: ExecutionContext? = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
		let promise = Promise<NewValue>()
		
		observe(on: queue) {
			promise.complete($0.map(onFulfilled))
		}
		
		return promise
	}
	
	@discardableResult
	public func then(on queue: ExecutionContext? = DispatchQueue.main, _ onFulfilled: @escaping (Value) throws -> Void) -> Promise<Value> {
		return then(on: queue, { value -> Value in
			try onFulfilled(value)
			return value
		})
	}
	
	@discardableResult
	public func `catch`(on queue: ExecutionContext? = DispatchQueue.main, _ onRejected: @escaping (Error) -> Void) -> Promise<Value> {
		let promise = Promise<Value>()
		
		observe(on: queue) { result in
			if let error = result.error {
				onRejected(error)
			}
			promise.complete(result)
		}
		
		return promise
	}
	
	@discardableResult
	public func observe(on queue: ExecutionContext? = DispatchQueue.main, _ callback: @escaping (Payload) -> Void) -> AnyObserver {
		let observer = Observer(self, queue: queue, callback: callback)
		
		lock.lock()
		let state = self.state
		if state == nil {
			observers.append(observer)
		}
		lock.unlock()
		
		if let state = state {
			observer.emit(state)
		}
		
		return observer
	}
	
	public func remove(_ observer: AnyObserver) {
		lock.lock()
		if let index = observers.index(where: { $0 === observer }) {
			observers.remove(at: index)
		}
		lock.unlock()
	}
	
	public func reject(_ error: Error) {
		complete(.failure(error))
	}
	
	public func fulfill(_ value: Value) {
		complete(.success(value))
	}
	
	public var isPending: Bool {
		lock.lock()
		defer { lock.unlock() }
		
		return state == nil
	}
	
	public var isFulfilled: Bool {
		return value != nil
	}
	
	public var isRejected: Bool {
		return error != nil
	}
	
	public var value: Value? {
		lock.lock()
		defer { lock.unlock() }
		
		return state?.value
	}
	
	public var error: Error? {
		lock.lock()
		defer { lock.unlock() }
		
		return state?.error
	}
	
	public func complete(_ state: Payload) {
		lock.lock()
		let isPending = self.state == nil
		let observers = self.observers
		
		if isPending {
			self.state = state
		}
		lock.unlock()
		
		guard isPending else { return }
		
		for observer in observers {
			observer.emit(state)
		}
	}
}


extension Promise where Value == Void {
	public static var fulfilled: Promise<Void> {
		return Promise(value: ())
	}
	
	public func fulfill() {
		fulfill(Void())
	}
}

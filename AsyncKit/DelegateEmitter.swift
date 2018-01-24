import Foundation


public final class DelegateEmitter<Payload, Result> {
	public class Observer: Equatable, AnyObserver {
		public typealias Callback = (Payload) -> Promise<Result>
		
		fileprivate let queue: ExecutionContext?
		fileprivate let callback: Callback
		fileprivate weak var emitter: DelegateEmitter<Payload, Result>?
		
		fileprivate init(queue: ExecutionContext?, callback: @escaping Callback) {
			self.queue = queue
			self.callback = callback
		}
		
		func emit(_ payload: Payload) -> Promise<Result> {
			if let queue = self.queue {
				return Promise.fulfilled
					.then(on: queue, {
						self.callback(payload)
					})
			} else {
				return callback(payload)
			}
		}
		
		/// Remove the observer from the event so that it stops receiving events and cleans up it's memory
		public func remove() {
			emitter?.remove(self)
		}
		
		public static func == (_ lhs: Observer, _ rhs: Observer) -> Bool {
			return lhs === rhs
		}
	}
	
	private var lock = NSLock()
	private var observers: [Observer] = []
	
	
	public init() {
	}
	
	
	public func emit(_ payload: Payload) -> Promise<[Result]> {
		lock.lock()
		let observers = self.observers
		lock.unlock()
		
		return Promise<Result>.all(observers.map({ $0.emit(payload) }))
	}
	
	@discardableResult
	public func observeAsync(on queue: ExecutionContext? = nil, _ callback: @escaping Observer.Callback) -> Observer {
		let observer = Observer(queue: queue, callback: callback)
		observer.emitter = self
		
		lock.lock()
		observers.append(observer)
		lock.unlock()
		
		return observer
	}
	
	@discardableResult
	public func observe(on queue: ExecutionContext? = nil, _ callback: @escaping (Payload) -> Result) -> Observer {
		return observeAsync(on: queue, { (payload) -> Promise<Result> in
			return Promise(value: callback(payload))
		})
	}
	
	/// Remove an observer
	///
	/// Equivalent to `Observer.remove`.
	///
	/// - Parameter observer: The observer to remove.
	public func remove(_ observer: Observer) {
		lock.lock()
		if let index = observers.index(of: observer) {
			observers.remove(at: index)
		}
		lock.unlock()
	}
}


extension DelegateEmitter where Payload == Void {
	public func emit() -> Promise<[Result]> {
		return emit(Void())
	}
}

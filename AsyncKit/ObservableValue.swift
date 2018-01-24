import Foundation


public class ObservableValue<Value>: Observable {
	public typealias Payload = Value
	
	private var lock = NSLock()
	private var observers: [Observer<ObservableValue<Value>>] = []
	private var _value: Value
	
	public var value: Value {
		get {
			lock.lock()
			defer { self.lock.unlock() }
			
			return _value
		}
		set {
			lock.lock()
			_value = newValue
			let observers = self.observers
			lock.unlock()
			
			for observer in observers {
				observer.emit(newValue)
			}
		}
	}
	
	public init(value: Value) {
		_value = value
	}
	
	@discardableResult
	public func observe(on queue: ExecutionContext?, _ callback: @escaping (Payload) -> Void) -> AnyObserver {
		let observer = Observer(self, queue: queue, callback: callback)
		
		lock.lock()
		let value = _value
		lock.unlock()
		observer.emit(value)
		
		// we want to emit the current value before adding it to our observers
		// (and potentially emitting a change)
		// but we still need to be locked for both individually
		lock.lock()
		observers.append(observer)
		lock.unlock()
		
		return observer
	}
	
	/// Remove an observer
	///
	/// Equivalent to `Observer.remove`.
	///
	/// - Parameter observer: The observer to remove.
	public func remove(_ observer: AnyObserver) {
		lock.lock()
		if let index = observers.index(where: { $0 === observer }) {
			observers.remove(at: index)
		}
		lock.unlock()
	}
}

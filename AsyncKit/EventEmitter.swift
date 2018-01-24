import Foundation


/// An emitter of a single event.
///
/// An event emitter excecutes any observing callbacks when it is emitted.
///
/// Payload is the type of data that is sent with events.
public class EventEmitter<Value>: Observable {
	public typealias Payload = Value
	
	private var lock = NSLock()
	private var observers: [Observer<EventEmitter<Value>>] = []
	
	public init() {
	}
	
	
	/// Emit an event and notify observers
	///
	/// If `notificationName` is not nil, a notification will also be posted. If Payload is a `NotificationPayload`, it's `notificationUserInfo` will be used for the 'userInfo' dictionary. The object is always the event emitter.
	///
	/// - Parameter payload: The payload to send to the observers.
	public func emit(_ payload: Payload) {
		lock.lock()
		let observers = self.observers
		lock.unlock()
		
		for observer in observers {
			observer.emit(payload)
		}
	}
	
	
	/// Create a new observer with a callback
	///
	/// - Parameters:
	///   - queue: The queue the callback should be called on. Defaults to the event's queue.
	///   - callback: The block to be called when the event is emitted.
	/// - Returns: A new observer that can be used to remove the observer.
	@discardableResult
	public func observe(on queue: ExecutionContext? = nil, _ callback: @escaping (Value) -> Void) -> AnyObserver {
		let observer = Observer(self, queue: queue, callback: callback)
		
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


extension EventEmitter where Payload == Void {
	public func emit() {
		emit(Void())
	}
}

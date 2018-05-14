import Foundation
import Dispatch


/// A type erased observable that can be used in any context.
public struct AnyObservable<Value>: Observable {
	public typealias Payload = Value
	
	
	public init<O: Observable>(_ rawObservable: O) where O.Payload == Payload {
		self.init(
			observe: { rawObservable.observe(on: $0, $1) },
			remove: { rawObservable.remove($0) }
		)
	}
	
	public init(observe: @escaping (_ queue: ExecutionContext?, _ callback: @escaping (Value) -> Void) -> AnyObserver, remove: @escaping (_ observer: AnyObserver) -> Void) {
		_observe = observe
		_remove = remove
	}
	
	private let _remove: (_ observer: AnyObserver) -> Void
	public func remove(_ observer: AnyObserver) {
		_remove(observer)
	}
	
	private let _observe: (_ queue: ExecutionContext?, _ callback: @escaping (Value) -> Void) -> AnyObserver
	@discardableResult
	public func observe(on queue: ExecutionContext?, _ callback: @escaping (Value) -> Void) -> AnyObserver {
		return _observe(queue, callback)
	}
}

/// An object that emits events.
public protocol Observable {
	associatedtype Payload
	
	func remove(_ observer: AnyObserver)
	
	func observe(on queue: ExecutionContext?, _ callback: @escaping (_ payload: Payload) -> Void) -> AnyObserver
}



/// Type erasure for EventEmitter<Payload>.Observer
///
/// You can use this to, for instance, keep an array of observers that should all be cleared at some point.
public protocol AnyObserver: class {
	func remove()
}

/// An event observer
public class Observer<O: Observable>: Equatable, AnyObserver {
	fileprivate let queue: ExecutionContext
	fileprivate let callback: (O.Payload) -> Void
	fileprivate let emitter: O
	
	public init(_ emitter: O, queue: ExecutionContext?, callback: @escaping (O.Payload) -> Void) {
		self.emitter = emitter
		self.queue = queue ?? CurrentContext()
		self.callback = callback
	}
	
	public func emit(_ payload: O.Payload) {
		queue.execute {
			self.callback(payload)
		}
	}
	
	/// Remove the observer from the event so that it stops receiving events and cleans up it's memory
	public func remove() {
		emitter.remove(self)
	}
	
	public static func == (_ lhs: Observer, _ rhs: Observer) -> Bool {
		return lhs === rhs
	}
}

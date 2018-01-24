import Foundation


fileprivate class ObjectObserversManager: NSObject {
	fileprivate var observers: [AnyObserver] = []
	
	deinit {
		for observer in observers {
			observer.remove()
		}
	}
}


private let observerManagerProperty = AssociatedProperty<ObjectObserversManager>(policy: .retain)

extension Observable {
	@discardableResult
	public func observe<Object: NSObjectProtocol>(with object: Object, on queue: ExecutionContext? = nil, _ callback: @escaping (Object, Payload) -> Void) -> AnyObserver {
		let manager = object.lazyLoad(observerManagerProperty, fallback: { ObjectObserversManager() })
		
		let observer = observe(on: queue) { [weak object] payload in
			guard let object = object else { return }
			
			callback(object, payload)
		}
		
		manager.observers.append(observer)
		
		return observer
	}
}

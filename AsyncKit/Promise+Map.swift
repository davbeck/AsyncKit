import Foundation


extension Promise {
	public func map<NewValue>(_ onFulfilled: @escaping (Value) throws -> NewValue) -> Promise<NewValue> {
		return then(onFulfilled)
	}
	
	public func flatMap<NewValue>(_ onFulfilled: @escaping (Value) throws -> NewValue?) -> Promise<NewValue> {
		return map({ try onFulfilled($0).unwrap() })
	}
	
	
	public func asVoid() -> Promise<Void> {
		return map({ _ in return Void() })
	}
	
	public func recover() -> Promise<Value?> {
		return map({ $0 as Value? })
			.recover({ error in
				return Promise<Value?>(value: nil)
			})
	}
}


extension Array {
	public func serialMap<T>(on queue: ExecutionContext = DispatchQueue.main, _ transform: @escaping (Element) throws -> Promise<T>) -> Promise<[T]> {
		var current = Promise<[T]>(value: [])
		for e in self {
			current = current.then(on: queue, { (result) -> Promise<[T]> in
				try transform(e).then(on: queue, { result + [$0] })
			})
		}
		
		return current
	}
}

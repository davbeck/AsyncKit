import Foundation


extension Observable {
	public func flatMap<NewPayload>(on queue: ExecutionContext? = nil, _ transform: @escaping (Payload) -> NewPayload?) -> AnyObservable<NewPayload> {
		return AnyObservable<NewPayload>(observe: { queue, callback in
			return self.observe(on: queue) { oldValue in
				guard let newValue = transform(oldValue) else { return }
				callback(newValue)
			}
		}, remove: { observer in
			self.remove(observer)
		})
	}
	
	public func filter(on queue: ExecutionContext? = nil, _ isIncluded: @escaping (Payload) -> Bool) -> AnyObservable<Payload> {
		return flatMap({ isIncluded($0) ? $0 : nil })
	}
	
	public func map<NewPayload>(on queue: ExecutionContext? = nil, _ transform: @escaping (Payload) -> NewPayload) -> AnyObservable<NewPayload> {
		return flatMap(transform)
	}
	
	public func asVoid() -> AnyObservable<Void> {
		return map({ _ in Void() })
	}
}

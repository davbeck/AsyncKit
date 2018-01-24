import Foundation


class ZipObserver: AnyObserver {
	let lhs: AnyObserver
	let rhs: AnyObserver
	
	init(lhs: AnyObserver, rhs: AnyObserver) {
		self.lhs = lhs
		self.rhs = rhs
	}
	
	func remove() {
		lhs.remove()
		rhs.remove()
	}
}


public func zip<A: Observable, B: Observable>(_ lhs: A, _ rhs: B) -> AnyObservable<(A.Payload, B.Payload)> {
	return AnyObservable(observe: { (queue, callback) -> AnyObserver in
		let queue = queue ?? CurrentContext()
		var a: A.Payload?
		var b: B.Payload?
		
		let aObserver = lhs.observe(on: queue) { value in
			a = value
			if let b = b {
				queue.execute {
					callback((value, b))
				}
			}
		}
		let bObserver = rhs.observe(on: queue) { value in
			b = value
			if let a = a {
				queue.execute {
					callback((a, value))
				}
			}
		}
		
		return ZipObserver(lhs: aObserver, rhs: bObserver)
	}, remove: { observer in
		lhs.remove(observer)
		rhs.remove(observer)
	})
}

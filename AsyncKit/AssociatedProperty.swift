import ObjectiveC


extension objc_AssociationPolicy {
	public static let retain = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN
	public static let retainNonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
	public static let copy = objc_AssociationPolicy.OBJC_ASSOCIATION_COPY
	public static let copyNonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_COPY_NONATOMIC
	public static let assign = objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN
}

public struct AssociatedProperty<T: Any> {
	fileprivate let key = UnsafeRawPointer(UnsafeMutablePointer<UInt8>.allocate(capacity: 1))
	
	public let policy: objc_AssociationPolicy
	
	public init(policy: objc_AssociationPolicy = .retain) {
		self.policy = policy
	}
}

extension NSObjectProtocol {
	public subscript<T>(property: AssociatedProperty<T>) -> T? {
		get {
			return objc_getAssociatedObject(self, property.key) as? T
		}
		set {
			objc_setAssociatedObject(self, property.key, newValue, property.policy)
		}
	}
	
	public func lazyLoad<T>(_ property: AssociatedProperty<T>, fallback load: () -> T) -> T {
		if let value = self[property] {
			return value
		} else {
			let value = load()
			self[property] = value
			return value
		}
	}
}

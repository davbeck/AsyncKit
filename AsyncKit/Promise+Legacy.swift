import Foundation


extension Promise {
	public convenience init(_ legacy: @escaping (_ callback: @escaping (Value?, Swift.Error?) -> Void) throws -> Void) {
		self.init(work: { fulfill, reject in
			try legacy({ value, error in
				if let error = error {
					reject(error)
				} else if let value = value {
					fulfill(value)
				} else {
					reject(UnexpectedError("Both error and image nil"))
				}
			})
		})
	}
}

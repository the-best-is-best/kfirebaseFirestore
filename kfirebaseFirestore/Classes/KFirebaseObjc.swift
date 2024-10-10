import FirebaseFirestore


@objc public class KFirestoreResultUnit: NSObject {
    @objc public let error: Error?

    @objc public init( error: Error?) {
        self.error = error
    }
}

@objc public class KFirestoreListResult: NSObject {
    @objc public let data: [[String : Any]]?
    @objc public let error: Error?

    @objc public init(data: [[String : Any]]?, error: Error?) {
        self.data = data
        self.error = error
    }
}


@objc public class KFirestoreResult: NSObject {
    @objc public let data: [String : Any]?
    @objc public let error: Error?

    @objc public init(data: [String : Any]?, error: Error?) {
        self.data = data
        self.error = error
    }
}

@objc public class KFirestoreFilter: NSObject {
    @objc public let field: String
    @objc public let value: Any

    @objc public init(field: String, value: Any) {
        self.field = field
        self.value = value
    }
}

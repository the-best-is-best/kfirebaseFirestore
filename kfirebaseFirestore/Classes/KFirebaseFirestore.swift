import FirebaseFirestore

@objc public class KFirebaseFirestore: NSObject {
    private let firestore = Firestore.firestore()
    
    // Dictionary to hold multiple listeners
    private var listeners: [String: ListenerRegistration] = [:]

    @objc(addDocs:documentId:data:callback:)
    public func addDocs(
        collection: String,
        documentId: String,
        data: [String: Any],
        callback: @escaping (KFirestoreResultUnit) -> Void
    ) {
        firestore.collection(collection).document(documentId).setData(data) { error in
            if let error = error {
                // Callback with error if there's an error
                callback(KFirestoreResultUnit(error: error))
            } else {
                // Callback with no error
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }

    @objc(getDocs:callback:)
    public func getDocs(
        collection: String,
        callback: @escaping (KFirestoreListResult) -> Void
    ) {
        firestore.collection(collection).getDocuments { querySnapshot, error in
            if let error = error {
                // Callback with error if there's an error
                callback(KFirestoreListResult(data: nil, error: error))
            } else {
                let data = querySnapshot?.documents.map { $0.data() }
                callback(KFirestoreListResult(data: data, error: nil))
            }
        }
    }

    @objc(getDocById:documentId:callback:)
    public func getDocById(
        collection: String,
        documentId: String,
        callback: @escaping (KFirestoreResult) -> Void
    ) {
        firestore.collection(collection).document(documentId).getDocument { documentSnapshot, error in
            if let error = error {
                callback(KFirestoreResult(data: nil, error: error))
            } else {
                let data = documentSnapshot?.data()
                callback(KFirestoreResult(data: data, error: nil))
            }
        }
    }

    @objc(getDocsByFilter:orderBy:limit:filter:callback:)
    public func getDocsByFilter(
        collection: String,
        orderBy: NSString?,
        limit: NSNumber?,
        filters: [[String: Any]],
        callback: @escaping (KFirestoreListResult) -> Void
    ) {
        var query: Query = firestore.collection(collection)

        for filter in filters {
            guard let filterPair = filter as? [String: Any],
                  let operatorStr = filterPair["operator"] as? String,
                  let value = filterPair["value"] else {
                print("Invalid filter: \(filter)")
                continue
            }

            let field = (filterPair["field"] as? String)?.split(separator: " ").first.map { String($0) } ?? ""

            switch operatorStr {
            case "==": query = query.whereField(field, isEqualTo: value)
            case "<": query = query.whereField(field, isLessThan: value)
            case "<=": query = query.whereField(field, isLessThanOrEqualTo: value)
            case ">": query = query.whereField(field, isGreaterThan: value)
            case ">=": query = query.whereField(field, isGreaterThanOrEqualTo: value)
            case "!=": query = query.whereField(field, isNotEqualTo: value)
            case "array-contains": query = query.whereField(field, arrayContains: value)
            case "array-contains-any":
                if let arrayValue = value as? [Any] {
                    query = query.whereField(field, arrayContainsAny: arrayValue)
                }
            case "in":
                if let arrayValue = value as? [Any] {
                    query = query.whereField(field, in: arrayValue)
                }
            case "not-in":
                if let arrayValue = value as? [Any] {
                    query = query.whereField(field, notIn: arrayValue)
                }
            default: print("Unsupported operator: \(operatorStr)")
            }
        }

        if let orderBy = orderBy {
            query = query.order(by: orderBy as String)
        }

        if let limit = limit?.intValue, limit > 0 {
            query = query.limit(to: limit)
        }

        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                callback(KFirestoreListResult(data: nil, error: error))
            } else if let documents = querySnapshot?.documents {
                let data = documents.map { $0.data() }
                callback(KFirestoreListResult(data: data, error: nil))
            } else {
                callback(KFirestoreListResult(data: [], error: nil))
            }
        }
    }

    @objc(updateDocument:documentId:data:callback:)
    public func updateDocument(
        collection: String,
        documentId: String,
        data: [String: Any],
        callback: @escaping (KFirestoreResultUnit) -> Void
    ) {
        firestore.collection(collection).document(documentId).updateData(data) { error in
            if let error = error {
                callback(KFirestoreResultUnit(error: error))
            } else {
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }

    @objc(deleteDoc:documentId:callback:)
    public func deleteDoc(
        collection: String,
        documentId: String,
        callback: @escaping (KFirestoreResultUnit) -> Void
    ) {
        firestore.collection(collection).document(documentId).delete { error in
            if let error = error {
                callback(KFirestoreResultUnit(error: error))
            } else {
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }

    @objc(batchWriteDoc:updateOperations:deleteOperations:callback:)
    public func batchWriteDoc(
        addOperations: [NSDictionary],
        updateOperations: [NSDictionary],
        deleteOperations: [NSDictionary],
        callback: @escaping (KFirestoreResultUnit) -> Void
    ) {
        let batch = firestore.batch()

        for operation in addOperations {
            guard let collection = operation["collection"] as? String,
                  let data = operation["data"] as? [String: Any] else { continue }
            let documentRef = firestore.collection(collection).document()
            batch.setData(data, forDocument: documentRef)
        }

        for operation in updateOperations {
            guard let collection = operation["collection"] as? String,
                  let documentId = operation["documentId"] as? String,
                  let data = operation["data"] as? [String: Any] else { continue }
            let documentRef = firestore.collection(collection).document(documentId)
            batch.updateData(data, forDocument: documentRef)
        }

        for operation in deleteOperations {
            guard let collection = operation["collection"] as? String,
                  let documentId = operation["documentId"] as? String else { continue }
            let documentRef = firestore.collection(collection).document(documentId)
            batch.deleteDocument(documentRef)
        }

        batch.commit { error in
            if let error = error {
                callback(KFirestoreResultUnit(error: error))
            } else {
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }

    // Start a real-time listener and store it with a unique key
    @objc(startRealTimeListener:listenerId:callback:)
    public func startRealTimeListener(
        collection: String,
        listenerId: String,
        callback: @escaping (KFirestoreListResult) -> Void
    ) {
        let listener = firestore.collection(collection)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    callback(KFirestoreListResult(data: nil, error: error))
                } else {
                    let data = querySnapshot?.documents.map { $0.data() }
                    callback(KFirestoreListResult(data: data, error: nil))
                }
            }
        
        // Store the listener with the provided listenerId
        listeners[listenerId] = listener
    }

    // Stop a specific listener by listenerId
    @objc(stopRealTimeListenerById:)
    public func stopRealTimeListenerById(listenerId: String) {
        if let listener = listeners[listenerId] {
            listener.remove()
            listeners.removeValue(forKey: listenerId)
        }
    }

    // Stop all listeners
    @objc(stopAllListeners)
    public func stopAllListeners() {
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
}

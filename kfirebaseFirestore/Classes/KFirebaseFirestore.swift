import FirebaseFirestore



@objc public class KFirebaseFirestore: NSObject {
    private let firestore = Firestore.firestore()
    
    private var listener: ListenerRegistration?

    
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
                let data = querySnapshot?.documents.map { $0.data() } // Extract data from documents
                callback(KFirestoreListResult(data: data, error: nil)) // Return data instead of documents
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
                let data = documentSnapshot?.data() // Extract data from document
                callback(KFirestoreResult(data: data, error: nil)) // Return data instead of document
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
            
            // Log filter details
            print("Applying filter: \(field) \(operatorStr) \(value)")

            // Apply filter logic as before
            switch operatorStr {
            case "==":
                query = query.whereField(field, isEqualTo: value)
            case "<":
                if let numberValue = value as? NSNumber {
                    query = query.whereField(field, isLessThan: numberValue)
                }
            case "<=":
                if let numberValue = value as? NSNumber {
                    query = query.whereField(field, isLessThanOrEqualTo: numberValue)
                }
            case ">":
                if let numberValue = value as? NSNumber {
                    query = query.whereField(field, isGreaterThan: numberValue)
                }
            case ">=":
                if let numberValue = value as? NSNumber {
                    query = query.whereField(field, isGreaterThanOrEqualTo: numberValue)
                }
            case "!=":
                query = query.whereField(field, isNotEqualTo: value)
            case "array-contains":
                query = query.whereField(field, arrayContains: value)
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
            default:
                print("Unsupported operator: \(operatorStr)")
                continue
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
    ){
        
        firestore.collection(collection).document(documentId).updateData(data) { error in
            if let error = error {
                // Callback with error if there's an error
                callback(KFirestoreResultUnit(error: error))
            } else {
                // Callback with no error
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }
    @objc(deleteDoc:documentId:callback:)
    public func deleteDoc(
        collection: String,
        documentId: String,
        callback: @escaping (KFirestoreResultUnit) -> Void
    ){
        firestore.collection(collection).document(documentId).delete(){ error in
            if let error = error {
                // Callback with error if there's an error
                callback(KFirestoreResultUnit(error: error))
            } else {
                // Callback with no error
                callback(KFirestoreResultUnit(error: nil))
            }
            
        }

    }
   
    @objc(batchWriteDoc:updateOperations:deleteOperations:callback:)
    public func batchWriteDoc(
        addOperations: [NSDictionary], // collection and data
        updateOperations: [NSDictionary], // collection, documentId, data
        deleteOperations: [NSDictionary], // collection and documentId
        callback: @escaping (KFirestoreResultUnit) -> Void
    ) {
        let batch = Firestore.firestore().batch()

        // Add operations
        for operation in addOperations {
            guard let collection = operation["collection"] as? String,
                  let data = operation["data"] as? [String: Any] else { continue }
            let documentRef = Firestore.firestore().collection(collection).document() // Auto ID
            batch.setData(data, forDocument: documentRef)
        }

        // Update operations
        for operation in updateOperations {
            guard let collection = operation["collection"] as? String,
                  let documentId = operation["documentId"] as? String,
                  let data = operation["data"] as? [String: Any] else { continue }
            let documentRef = Firestore.firestore().collection(collection).document(documentId)
            batch.setData(data, forDocument: documentRef)
        }

        // Delete operations
        for operation in deleteOperations {
            guard let collection = operation["collection"] as? String,
                  let documentId = operation["documentId"] as? String else { continue }
            let documentRef = Firestore.firestore().collection(collection).document(documentId)
            batch.deleteDocument(documentRef)
        }

        // Commit the batch
        batch.commit { error in
            if let error = error {
                callback(KFirestoreResultUnit(error: error))
            } else {
                callback(KFirestoreResultUnit(error: nil))
            }
        }
    }
    
    @objc(startRealTimeListener:callback:)
       public func startRealTimeListener(
           collection: String,
           callback: @escaping (KFirestoreListResult) -> Void
       ) {
           listener = firestore.collection(collection)
               .addSnapshotListener { (querySnapshot, error) in
                   if let error = error {
                       // Callback with error if there's an error
                       callback(KFirestoreListResult(data: nil, error: error))
                   } else {
                       let data = querySnapshot?.documents.map { $0.data() }
                       callback(KFirestoreListResult(data: data, error: nil)) // Return the data
                   }
               }
       }

       // Stop listener method
       @objc(stopRealTimeListener)
       public func stopRealTimeListener() {
           listener?.remove()
           listener = nil
       }
}

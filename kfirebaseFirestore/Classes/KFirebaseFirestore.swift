import FirebaseFirestore



@objc public class KFirebaseFirestore: NSObject {
    private let firestore = Firestore.firestore()
    
    
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
        orderBy: String,
        limit: Int,
        filters: [KFirestoreFilter],
        callback: @escaping (KFirestoreListResult) -> Void
    ) {
        // Initialize the query with the specified collection
        var query: Query = firestore.collection(collection)
        
        // Loop through filters to build the query
        for filter in filters {
            let field = filter.field
            let value = filter.value
            
            switch value {
            case let stringValue as String:
                query = query.whereField(field, isEqualTo: stringValue)
            case let intValue as Int:
                query = query.whereField(field, isEqualTo: intValue)
            case let doubleValue as Double:
                query = query.whereField(field, isEqualTo: doubleValue)
            case let longValue as Int64: // Firestore's Long type is represented as Int64 in Swift
                query = query.whereField(field, isEqualTo: longValue)
            default:
                break
            }
        }
        
        // Add ordering to the query
        query = query.order(by: orderBy)
        
        // Add limit to the query
        query = query.limit(to: limit)
        
        // Execute the query
        query.getDocuments { (querySnapshot, error) in
            if let error = error {
                callback(KFirestoreListResult(data: nil, error: error))
            } else if let documents = querySnapshot?.documents {
                let data = documents.map { $0.data() } // Extract data from documents
                callback(KFirestoreListResult(data: data, error: nil)) // Return data instead of documents
            } else {
                // Return an empty result if there are no documents
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

}

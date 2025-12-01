//
//  FirebaseManager.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {
        // Configure Firestore settings to prefer server data
        let settings = db.settings
        settings.cacheSettings = MemoryCacheSettings()
        db.settings = settings
    }
    
    // MARK: - Generic CRUD Operations
    
    func fetchDocuments<T: Decodable>(from collection: String, source: FirestoreSource = .default) async throws -> [T] {
        let snapshot = try await db.collection(collection).getDocuments(source: source)
        return snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }
    
    func fetchDocument<T: Decodable>(from collection: String, id: String) async throws -> T? {
        let document = try await db.collection(collection).document(id).getDocument()
        return try? document.data(as: T.self)
    }
    
    func addDocument<T: Encodable>(to collection: String, data: T) async throws -> String {
        let docRef = try db.collection(collection).addDocument(from: data)
        return docRef.documentID
    }
    
    func updateDocument<T: Encodable>(in collection: String, id: String, data: T) async throws {
        try db.collection(collection).document(id).setData(from: data, merge: true)
    }
    
    func deleteDocument(from collection: String, id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    // MARK: - Real-time Listeners
    
    func listenToCollection<T: Decodable>(
        _ collection: String,
        completion: @escaping ([T]) -> Void
    ) -> ListenerRegistration {
        return db.collection(collection).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            let items = documents.compactMap { document in
                try? document.data(as: T.self)
            }
            completion(items)
        }
    }
    
    // MARK: - Users Specific Operations
    
    func fetchUsers() async throws -> [User] {
        try await fetchDocuments(from: FirebaseCollection.users, source: .server)
    }
    
    func addUser(_ user: User) async throws -> String {
        try await addDocument(to: FirebaseCollection.users, data: user)
    }
    
    func updateUser(_ user: User) async throws {
        guard let id = user.id else { throw NSError(domain: "UserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"]) }
        try await updateDocument(in: FirebaseCollection.users, id: id, data: user)
    }
    
    func deleteUser(id: String) async throws {
        try await deleteDocument(from: FirebaseCollection.users, id: id)
    }
    
    // MARK: - Feed Specific Operations
    
    func fetchFeedItems() async throws -> [FeedItem] {
        try await fetchDocuments(from: FirebaseCollection.feed, source: .server)
    }
    
    func addFeedItem(_ item: FeedItem) async throws -> String {
        try await addDocument(to: FirebaseCollection.feed, data: item)
    }
    
    func updateFeedItem(_ item: FeedItem) async throws {
        guard let id = item.id else { throw NSError(domain: "FeedError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Feed item ID is missing"]) }
        try await updateDocument(in: FirebaseCollection.feed, id: id, data: item)
    }
    
    func deleteFeedItem(id: String) async throws {
        try await deleteDocument(from: FirebaseCollection.feed, id: id)
    }
    
    // MARK: - Territory Specific Operations
    
    func fetchTerritories() async throws -> [RemoteTerritory] {
        try await fetchDocuments(from: FirebaseCollection.territories, source: .server)
    }
    
    func addTerritory(_ territory: RemoteTerritory) async throws -> String {
        try await addDocument(to: FirebaseCollection.territories, data: territory)
    }
    
    func updateTerritory(_ territory: RemoteTerritory) async throws {
        guard let id = territory.id else { throw NSError(domain: "TerritoryError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Territory ID is missing"]) }
        try await updateDocument(in: FirebaseCollection.territories, id: id, data: territory)
    }
    
    func deleteTerritory(id: String) async throws {
        try await deleteDocument(from: FirebaseCollection.territories, id: id)
    }
}

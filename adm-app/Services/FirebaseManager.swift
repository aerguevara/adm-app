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
    
    func batchUpdateUsers(_ users: [User]) async throws {
        let batch = db.batch()
        
        for user in users {
            guard let id = user.id else { continue }
            let docRef = db.collection(FirebaseCollection.users).document(id)
            try batch.setData(from: user, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Feed Specific Operations
    
    func fetchFeedItems() async throws -> [FeedItem] {
        let snapshot = try await db.collection(FirebaseCollection.feed).getDocuments(source: .server)
        return snapshot.documents.compactMap { document in
            var item = try? document.data(as: FeedItem.self)
            // Ensure we keep the Firestore document ID even if it's not stored as a field
            if item?.id == nil {
                item?.id = document.documentID
            }
            return item
        }
    }
    
    func fetchFeedItems(for userId: String) async throws -> [FeedItem] {
        let snapshot = try await db.collection(FirebaseCollection.feed)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(source: .server)
        
        return snapshot.documents.compactMap { document in
            var item = try? document.data(as: FeedItem.self)
            if item?.id == nil {
                item?.id = document.documentID
            }
            return item
        }
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
    
    // MARK: - Activities
    
    func deleteActivity(id: String) async throws {
        try await deleteDocument(from: FirebaseCollection.activities, id: id)
    }
    
    func deleteActivities(for userId: String) async throws {
        let snapshot = try await db.collection(FirebaseCollection.activities)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(source: .server)
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    // MARK: - Territory Specific Operations
    
    func fetchTerritories() async throws -> [RemoteTerritory] {
        try await fetchDocuments(from: FirebaseCollection.territories, source: .server)
    }
    
    func fetchTerritories(for userId: String) async throws -> [RemoteTerritory] {
        let snapshot = try await db.collection(FirebaseCollection.territories)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(source: .server)
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: RemoteTerritory.self)
        }
    }
    
    func fetchActivities(filterUserId: String? = nil) async throws -> [ActivitySession] {
        var query: Query = db.collection(FirebaseCollection.activities)
        if let userId = filterUserId {
            query = query.whereField("userId", isEqualTo: userId)
        }
        
        let snapshot = try await query.getDocuments(source: .server)
        
        return snapshot.documents.compactMap { document in
            let rawData = document.data()
            
            // Prefer typed decoding; if it fails return a tolerant manual parse
            if var session = try? document.data(as: ActivitySession.self) {
                if session.id == nil {
                    session.id = document.documentID
                }
                if session.userId.isEmpty {
                    session.userId = rawData["userId"] as? String ?? ""
                }
                return session
            } else {
                return ActivitySession.from(document: document)
            }
        }
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
    
    // MARK: - Follow Operations
    
    func fetchFollowers(for userId: String) async throws -> [FollowRelationship] {
        let snapshot = try await db.collection(FirebaseCollection.users)
            .document(userId)
            .collection("followers")
            .getDocuments(source: .server)
        
        return snapshot.documents.compactMap { document in
            if var follower = try? document.data(as: FollowRelationship.self) {
                if follower.id == nil {
                    follower.id = document.documentID
                }
                return follower
            } else {
                let data = document.data()
                let displayName = data["displayName"] as? String ?? ""
                let avatarURL = data["avatarURL"] as? String
                let followedAt = (data["followedAt"] as? Timestamp)?.dateValue()
                return FollowRelationship(id: document.documentID, displayName: displayName, avatarURL: avatarURL, followedAt: followedAt)
            }
        }
    }
    
    func fetchFollowing(for userId: String) async throws -> [FollowRelationship] {
        let snapshot = try await db.collection(FirebaseCollection.users)
            .document(userId)
            .collection("following")
            .getDocuments(source: .server)
        
        return snapshot.documents.compactMap { document in
            if var following = try? document.data(as: FollowRelationship.self) {
                if following.id == nil {
                    following.id = document.documentID
                }
                return following
            } else {
                let data = document.data()
                let displayName = data["displayName"] as? String ?? ""
                let avatarURL = data["avatarURL"] as? String
                let followedAt = (data["followedAt"] as? Timestamp)?.dateValue()
                return FollowRelationship(id: document.documentID, displayName: displayName, avatarURL: avatarURL, followedAt: followedAt)
            }
        }
    }
    
    func follow(user: User, targetUser: User) async throws {
        guard let userId = user.id, let targetId = targetUser.id else {
            throw NSError(domain: "FollowError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User IDs are missing"])
        }
        
        let batch = db.batch()
        let followerData: [String: Any] = [
            "displayName": user.displayName,
            "avatarURL": user.avatarURL ?? "",
            "followedAt": FieldValue.serverTimestamp()
        ]
        let followingData: [String: Any] = [
            "displayName": targetUser.displayName,
            "avatarURL": targetUser.avatarURL ?? "",
            "followedAt": FieldValue.serverTimestamp()
        ]
        
        let userFollowingRef = db.collection(FirebaseCollection.users)
            .document(userId)
            .collection("following")
            .document(targetId)
        
        let targetFollowersRef = db.collection(FirebaseCollection.users)
            .document(targetId)
            .collection("followers")
            .document(userId)
        
        batch.setData(followingData, forDocument: userFollowingRef, merge: true)
        batch.setData(followerData, forDocument: targetFollowersRef, merge: true)
        
        try await batch.commit()
    }
    
    func unfollow(userId: String, targetUserId: String) async throws {
        let batch = db.batch()
        
        let userFollowingRef = db.collection(FirebaseCollection.users)
            .document(userId)
            .collection("following")
            .document(targetUserId)
        
        let targetFollowersRef = db.collection(FirebaseCollection.users)
            .document(targetUserId)
            .collection("followers")
            .document(userId)
        
        batch.deleteDocument(userFollowingRef)
        batch.deleteDocument(targetFollowersRef)
        
        try await batch.commit()
    }
    
    func removeFollower(userId: String, followerUserId: String) async throws {
        let batch = db.batch()
        
        let userFollowersRef = db.collection(FirebaseCollection.users)
            .document(userId)
            .collection("followers")
            .document(followerUserId)
        
        let followerFollowingRef = db.collection(FirebaseCollection.users)
            .document(followerUserId)
            .collection("following")
            .document(userId)
        
        batch.deleteDocument(userFollowersRef)
        batch.deleteDocument(followerFollowingRef)
        
        try await batch.commit()
    }
}

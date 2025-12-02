//
//  User.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var displayName: String
    var email: String?
    var joinedAt: Date
    var lastUpdated: Date?
    var level: Int
    var xp: Int
    var previousRank: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case joinedAt
        case lastUpdated
        case level
        case xp
        case previousRank
    }
    
    // Initializer for creating new users
    init(id: String? = nil, displayName: String, email: String? = nil, joinedAt: Date = Date(), lastUpdated: Date? = Date(), level: Int = 1, xp: Int = 0, previousRank: Int? = nil) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.joinedAt = joinedAt
        self.lastUpdated = lastUpdated
        self.level = level
        self.xp = xp
        self.previousRank = previousRank
    }
}

//
//  FollowRelationship.swift
//  adm-app
//
//  Created by Codex on 5/12/25.
//

import Foundation
import FirebaseFirestore

struct FollowRelationship: Identifiable, Codable, Hashable {
    var id: String?
    var displayName: String
    var avatarURL: String?
    var followedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case avatarURL
        case followedAt
    }
    
    init(id: String? = nil, displayName: String = "", avatarURL: String? = nil, followedAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.followedAt = followedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        self.avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        self.followedAt = try container.decodeIfPresent(Date.self, forKey: .followedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encodeIfPresent(followedAt, forKey: .followedAt)
    }
}

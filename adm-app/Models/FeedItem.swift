//
//  FeedItem.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import Foundation
import FirebaseFirestore

struct FeedItem: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var date: Date
    var isPersonal: Bool
    var rarity: String
    var relatedUserName: String
    var subtitle: String
    var title: String
    var type: String
    var userId: String
    var xpEarned: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case isPersonal
        case rarity
        case relatedUserName
        case subtitle
        case title
        case type
        case userId
        case xpEarned
    }
    
    // Initializer for creating new feed items
    init(id: String? = nil, date: Date = Date(), isPersonal: Bool = true, rarity: String = "common", relatedUserName: String = "", subtitle: String, title: String, type: String, userId: String, xpEarned: Int = 0) {
        self.id = id
        self.date = date
        self.isPersonal = isPersonal
        self.rarity = rarity
        self.relatedUserName = relatedUserName
        self.subtitle = subtitle
        self.title = title
        self.type = type
        self.userId = userId
        self.xpEarned = xpEarned
    }
    
    // Custom decoding to avoid dropping documents with missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        self.isPersonal = try container.decodeIfPresent(Bool.self, forKey: .isPersonal) ?? true
        self.rarity = try container.decodeIfPresent(String.self, forKey: .rarity) ?? "common"
        self.relatedUserName = try container.decodeIfPresent(String.self, forKey: .relatedUserName) ?? ""
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "unknown"
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        self.xpEarned = try container.decodeIfPresent(Int.self, forKey: .xpEarned) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(isPersonal, forKey: .isPersonal)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(relatedUserName, forKey: .relatedUserName)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(userId, forKey: .userId)
        try container.encode(xpEarned, forKey: .xpEarned)
    }
}

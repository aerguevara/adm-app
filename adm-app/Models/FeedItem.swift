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
}

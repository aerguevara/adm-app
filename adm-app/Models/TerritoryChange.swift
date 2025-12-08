//
//  TerritoryChange.swift
//  adm-app
//
//  Created by Codex on 9/12/25.
//

import Foundation
import FirebaseFirestore

struct TerritoryChange: Identifiable, Codable, Hashable {
    var id: String?
    var territoryId: String?
    var changeType: String
    var changedAt: Date
    var activityEndAt: Date?
    var expiresAt: Date?
    var newActivityId: String?
    var newUserId: String?
    var previousActivityId: String?
    var previousUserId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case territoryId
        case changeType
        case changedAt
        case activityEndAt
        case expiresAt
        case newActivityId
        case newUserId
        case previousActivityId
        case previousUserId
    }
    
    init(
        id: String? = nil,
        territoryId: String? = nil,
        changeType: String = "",
        changedAt: Date = Date(),
        activityEndAt: Date? = nil,
        expiresAt: Date? = nil,
        newActivityId: String? = nil,
        newUserId: String? = nil,
        previousActivityId: String? = nil,
        previousUserId: String? = nil
    ) {
        self.id = id
        self.territoryId = territoryId
        self.changeType = changeType
        self.changedAt = changedAt
        self.activityEndAt = activityEndAt
        self.expiresAt = expiresAt
        self.newActivityId = newActivityId
        self.newUserId = newUserId
        self.previousActivityId = previousActivityId
        self.previousUserId = previousUserId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.territoryId = try container.decodeIfPresent(String.self, forKey: .territoryId)
        self.changeType = try container.decodeIfPresent(String.self, forKey: .changeType) ?? ""
        self.changedAt = try container.decodeIfPresent(Date.self, forKey: .changedAt) ?? Date()
        self.activityEndAt = try container.decodeIfPresent(Date.self, forKey: .activityEndAt)
        self.expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        self.newActivityId = try container.decodeIfPresent(String.self, forKey: .newActivityId)
        self.newUserId = try container.decodeIfPresent(String.self, forKey: .newUserId)
        self.previousActivityId = try container.decodeIfPresent(String.self, forKey: .previousActivityId)
        self.previousUserId = try container.decodeIfPresent(String.self, forKey: .previousUserId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(territoryId, forKey: .territoryId)
        try container.encode(changeType, forKey: .changeType)
        try container.encode(changedAt, forKey: .changedAt)
        try container.encodeIfPresent(activityEndAt, forKey: .activityEndAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(newActivityId, forKey: .newActivityId)
        try container.encodeIfPresent(newUserId, forKey: .newUserId)
        try container.encodeIfPresent(previousActivityId, forKey: .previousActivityId)
        try container.encodeIfPresent(previousUserId, forKey: .previousUserId)
    }
}

//
//  ActivitySession.swift
//  adm-app
//
//  Created by Codex on 3/12/25.
//

import Foundation
import FirebaseFirestore

struct ActivityRoutePoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case timestamp
    }
}

struct ActivityXPBreakdown: Codable, Hashable {
    var xpBase: Int
    var xpTerritory: Int
    var xpStreak: Int
    var xpWeeklyRecord: Int
    var xpBadges: Int
    var total: Int
    
    enum CodingKeys: String, CodingKey {
        case xpBase
        case xpTerritory
        case xpStreak
        case xpWeeklyRecord
        case xpBadges
        case total
    }
    
    init(xpBase: Int = 0, xpTerritory: Int = 0, xpStreak: Int = 0, xpWeeklyRecord: Int = 0, xpBadges: Int = 0, total: Int = 0) {
        self.xpBase = xpBase
        self.xpTerritory = xpTerritory
        self.xpStreak = xpStreak
        self.xpWeeklyRecord = xpWeeklyRecord
        self.xpBadges = xpBadges
        self.total = total
    }
}

struct ActivityTerritoryStats: Codable, Hashable {
    var newCellsCount: Int
    var defendedCellsCount: Int
    var recapturedCellsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case newCellsCount
        case defendedCellsCount
        case recapturedCellsCount
    }
    
    init(newCellsCount: Int = 0, defendedCellsCount: Int = 0, recapturedCellsCount: Int = 0) {
        self.newCellsCount = newCellsCount
        self.defendedCellsCount = defendedCellsCount
        self.recapturedCellsCount = recapturedCellsCount
    }
}

struct ActivityMission: Codable, Hashable, Identifiable {
    var id: String
    var userId: String
    var category: String
    var name: String
    var description: String
    var rarity: String
}

struct ActivitySession: Identifiable, Codable, Hashable {
    var id: String?
    var startDate: Date
    var endDate: Date
    var activityType: String
    var distanceMeters: Double
    var durationSeconds: Double
    var route: [ActivityRoutePoint]
    var xpBreakdown: ActivityXPBreakdown
    var territoryStats: ActivityTerritoryStats
    var missions: [ActivityMission]
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case activityType
        case distanceMeters
        case durationSeconds
        case route
        case xpBreakdown
        case territoryStats
        case missions
    }
    
    init(
        id: String? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(),
        activityType: String = "otherOutdoor",
        distanceMeters: Double = 0,
        durationSeconds: Double = 0,
        route: [ActivityRoutePoint] = [],
        xpBreakdown: ActivityXPBreakdown = ActivityXPBreakdown(),
        territoryStats: ActivityTerritoryStats = ActivityTerritoryStats(),
        missions: [ActivityMission] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.activityType = activityType
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.route = route
        self.xpBreakdown = xpBreakdown
        self.territoryStats = territoryStats
        self.missions = missions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()
        self.endDate = try container.decodeIfPresent(Date.self, forKey: .endDate) ?? Date()
        self.activityType = try container.decodeIfPresent(String.self, forKey: .activityType) ?? "otherOutdoor"
        self.distanceMeters = try container.decodeIfPresent(Double.self, forKey: .distanceMeters) ?? 0
        self.durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) ?? 0
        self.route = try container.decodeIfPresent([ActivityRoutePoint].self, forKey: .route) ?? []
        self.xpBreakdown = try container.decodeIfPresent(ActivityXPBreakdown.self, forKey: .xpBreakdown) ?? ActivityXPBreakdown()
        self.territoryStats = try container.decodeIfPresent(ActivityTerritoryStats.self, forKey: .territoryStats) ?? ActivityTerritoryStats()
        self.missions = try container.decodeIfPresent([ActivityMission].self, forKey: .missions) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(activityType, forKey: .activityType)
        try container.encode(distanceMeters, forKey: .distanceMeters)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(route, forKey: .route)
        try container.encode(xpBreakdown, forKey: .xpBreakdown)
        try container.encode(territoryStats, forKey: .territoryStats)
        try container.encode(missions, forKey: .missions)
    }
}

extension ActivitySession {
    static func from(document: QueryDocumentSnapshot) -> ActivitySession {
        let data = document.data()
        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        let activityType = data["activityType"] as? String ?? "otherOutdoor"
        let distanceMeters = data["distanceMeters"] as? Double ?? (data["distanceMeters"] as? NSNumber)?.doubleValue ?? 0
        let durationSeconds = data["durationSeconds"] as? Double ?? (data["durationSeconds"] as? NSNumber)?.doubleValue ?? 0
        
        let routeArray = data["route"] as? [[String: Any]] ?? []
        let route: [ActivityRoutePoint] = routeArray.map { point in
            let lat = point["latitude"] as? Double ?? (point["latitude"] as? NSNumber)?.doubleValue ?? 0
            let lon = point["longitude"] as? Double ?? (point["longitude"] as? NSNumber)?.doubleValue ?? 0
            let ts = (point["timestamp"] as? Timestamp)?.dateValue()
            return ActivityRoutePoint(latitude: lat, longitude: lon, timestamp: ts)
        }
        
        let xpMap = data["xpBreakdown"] as? [String: Any] ?? [:]
        let xpBreakdown = ActivityXPBreakdown(
            xpBase: xpMap["xpBase"] as? Int ?? (xpMap["xpBase"] as? NSNumber)?.intValue ?? 0,
            xpTerritory: xpMap["xpTerritory"] as? Int ?? (xpMap["xpTerritory"] as? NSNumber)?.intValue ?? 0,
            xpStreak: xpMap["xpStreak"] as? Int ?? (xpMap["xpStreak"] as? NSNumber)?.intValue ?? 0,
            xpWeeklyRecord: xpMap["xpWeeklyRecord"] as? Int ?? (xpMap["xpWeeklyRecord"] as? NSNumber)?.intValue ?? 0,
            xpBadges: xpMap["xpBadges"] as? Int ?? (xpMap["xpBadges"] as? NSNumber)?.intValue ?? 0,
            total: xpMap["total"] as? Int ?? (xpMap["total"] as? NSNumber)?.intValue ?? 0
        )
        
        let territoryMap = data["territoryStats"] as? [String: Any] ?? [:]
        let territoryStats = ActivityTerritoryStats(
            newCellsCount: territoryMap["newCellsCount"] as? Int ?? (territoryMap["newCellsCount"] as? NSNumber)?.intValue ?? 0,
            defendedCellsCount: territoryMap["defendedCellsCount"] as? Int ?? (territoryMap["defendedCellsCount"] as? NSNumber)?.intValue ?? 0,
            recapturedCellsCount: territoryMap["recapturedCellsCount"] as? Int ?? (territoryMap["recapturedCellsCount"] as? NSNumber)?.intValue ?? 0
        )
        
        let missionsArray = data["missions"] as? [[String: Any]] ?? []
        let missions: [ActivityMission] = missionsArray.compactMap { mission in
            guard let id = mission["id"] as? String else { return nil }
            let userId = mission["userId"] as? String ?? ""
            let category = mission["category"] as? String ?? ""
            let name = mission["name"] as? String ?? ""
            let description = mission["description"] as? String ?? ""
            let rarity = mission["rarity"] as? String ?? ""
            return ActivityMission(id: id, userId: userId, category: category, name: name, description: description, rarity: rarity)
        }
        
        return ActivitySession(
            id: document.documentID,
            startDate: startDate,
            endDate: endDate,
            activityType: activityType,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            route: route,
            xpBreakdown: xpBreakdown,
            territoryStats: territoryStats,
            missions: missions
        )
    }
}

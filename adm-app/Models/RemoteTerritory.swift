//
//  RemoteTerritory.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import Foundation
import FirebaseFirestore

struct Coordinate: Codable, Hashable, Identifiable {
    var id = UUID()
    var latitude: Double
    var longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

struct RemoteTerritory: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var boundary: [Coordinate]
    var centerLatitude: Double
    var centerLongitude: Double
    var expiresAt: Date
    var timestamp: Date
    var activityEndAt: Date?
    var userId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case boundary
        case centerLatitude
        case centerLongitude
        case expiresAt
        case timestamp
        case activityEndAt
        case userId
    }
    
    var isExpired: Bool {
        expiresAt < Date()
    }
    
    // Initializer for creating new territories
    init(id: String? = nil, boundary: [Coordinate] = [], centerLatitude: Double, centerLongitude: Double, expiresAt: Date, timestamp: Date = Date(), activityEndAt: Date? = nil, userId: String) {
        self.id = id
        self.boundary = boundary
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.expiresAt = expiresAt
        self.timestamp = timestamp
        self.activityEndAt = activityEndAt
        self.userId = userId
    }
}

//
//  Constants.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import Foundation

enum FirebaseCollection {
    static let users = "users"
    static let feed = "feed"
    static let territories = "remote_territories"
}

enum FeedType: String, CaseIterable {
    case territoryConquered = "territoryConquered"
    case levelUp = "levelUp"
    case achievement = "achievement"
    case challenge = "challenge"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .territoryConquered: return "Territory Conquered"
        case .levelUp: return "Level Up"
        case .achievement: return "Achievement"
        case .challenge: return "Challenge"
        case .other: return "Other"
        }
    }
}

enum Rarity: String, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        rawValue.capitalized
    }
}

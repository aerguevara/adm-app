//
//  FeedItemWithUser.swift
//  adm-app
//
//  Created by Anyelo Reyes on 2/12/25.
//

import Foundation

struct FeedItemWithUser: Identifiable, Hashable {
    let feedItem: FeedItem
    let user: User?
    
    var id: String? { feedItem.id }
    
    // Convenience accessors
    var displayName: String {
        user?.displayName ?? "Unknown User"
    }
    
    var userLevel: Int {
        user?.level ?? 0
    }
    
    var userXP: Int {
        user?.xp ?? 0
    }
}

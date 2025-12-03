//
//  TerritoryWithUser.swift
//  adm-app
//
//  Created by Codex on 3/12/25.
//

import Foundation

struct TerritoryWithUser: Identifiable, Hashable {
    let territory: RemoteTerritory
    let user: User?
    
    var id: String? { territory.id }
    
    var displayName: String {
        user?.displayName ?? "Unknown User"
    }
}

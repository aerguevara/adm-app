//
//  MainAdminView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct MainAdminView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            UsersListView()
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
                .tag(0)
            
            ActivitiesListView()
                .tabItem {
                    Label("Activities", systemImage: "figure.walk.motion")
                }
                .tag(1)
            
            FeedListView()
                .tabItem {
                    Label("Feed", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(2)
            
            TerritoriesListView()
                .tabItem {
                    Label("Territories", systemImage: "map.fill")
                }
                .tag(3)
        }
        .tabViewStyle(.automatic)
        .tint(.blue)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainAdminView()
}

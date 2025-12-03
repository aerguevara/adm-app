//
//  TerritoriesListView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct TerritoriesListView: View {
    @StateObject private var viewModel = TerritoriesViewModel()
    @State private var showingAddTerritory = false
    @State private var showingDeleteAllAlert = false
    @State private var searchText = ""
    @State private var selectedUserId: String = TerritoriesListView.allUsersFilterId
    
    private static let allUsersFilterId = "__all_users__"
    
    var filteredTerritories: [TerritoryWithUser] {
        var territories = viewModel.territoriesWithUsers
        
        if selectedUserId != TerritoriesListView.allUsersFilterId {
            territories = territories.filter { $0.territory.userId == selectedUserId }
        }
        
        if searchText.isEmpty {
            return territories
        }
        
        return territories.filter { territory in
            territory.territory.userId.localizedCaseInsensitiveContains(searchText) ||
            territory.displayName.localizedCaseInsensitiveContains(searchText) ||
            String(territory.territory.centerLatitude).contains(searchText) ||
            String(territory.territory.centerLongitude).contains(searchText)
        }
    }
    
    var userFilterOptions: [(id: String, name: String)] {
        let userDictionary = viewModel.territoriesWithUsers.reduce(into: [String: String]()) { result, item in
            result[item.territory.userId] = item.displayName
        }
        
        let sortedUsers = userDictionary
            .map { ($0.key, $0.value) }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
        
        return [(TerritoriesListView.allUsersFilterId, "All Users")] + sortedUsers
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTerritories) { territoryWithUser in
                    NavigationLink(destination: TerritoryDetailView(territory: territoryWithUser.territory)) {
                        TerritoryRow(territory: territoryWithUser)
                    }
                }
                .onDelete(perform: deleteTerritories)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading territories...")
                } else if filteredTerritories.isEmpty {
                    ContentUnavailableView {
                        Label("No Territories", systemImage: "map")
                    } description: {
                        Text(searchText.isEmpty ? "No territories found" : "No territories match '\(searchText)'")
                    }
                }
            }
            .navigationTitle("Territories")
            .searchable(text: $searchText, prompt: "Search by user name/ID or coordinates")
            .refreshable {
                await viewModel.loadTerritories()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        Label("Delete All", systemImage: "trash.fill")
                    }
                    .disabled(viewModel.territoriesWithUsers.isEmpty)
                    
                    Menu {
                        Picker("Filter by User", selection: $selectedUserId) {
                            ForEach(userFilterOptions, id: \.id) { option in
                                Text(option.name).tag(option.id)
                            }
                        }
                    } label: {
                        Label("User Filter", systemImage: "person.2.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTerritory = true
                    } label: {
                        Label("Add Territory", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTerritory) {
                AddTerritoryView()
            }
            .alert("Delete All Territories", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    Task {
                        let filter = selectedUserId == TerritoriesListView.allUsersFilterId ? nil : selectedUserId
                        await viewModel.deleteAllTerritories(filterUserId: filter)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(filteredTerritories.count) territories? This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if viewModel.territoriesWithUsers.isEmpty {
                    Task {
                        await viewModel.loadTerritories()
                    }
                }
            }
        }
        .task {
            await viewModel.loadTerritories()
        }
    }
    
    private func deleteTerritories(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let territory = filteredTerritories[index]
                await viewModel.deleteTerritory(territory)
            }
            if selectedUserId != TerritoriesListView.allUsersFilterId {
                await viewModel.loadTerritories()
            }
        }
    }
}

struct TerritoryRow: View {
    let territory: TerritoryWithUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Territory", systemImage: "map.fill")
                    .font(.headline)
                
                Spacer()
                
                if territory.territory.isExpired {
                    Label("Expired", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Center: \(String(format: "%.4f", territory.territory.centerLatitude)), \(String(format: "%.4f", territory.territory.centerLongitude))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(territory.territory.boundary.count) boundary points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Label(territory.displayName, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Created: \(territory.territory.timestamp.shortDate)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Expires: \(territory.territory.expiresAt.shortDate)")
                        .font(.caption2)
                        .foregroundStyle(territory.territory.isExpired ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class TerritoriesViewModel: ObservableObject {
    @Published var territoriesWithUsers: [TerritoryWithUser] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadTerritories() async {
        isLoading = true
        do {
            async let territoriesTask = firebaseManager.fetchTerritories()
            async let usersTask = firebaseManager.fetchUsers()
            
            let territories = try await territoriesTask
            let users = try await usersTask
            
            let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id ?? "", $0) })
            
            territoriesWithUsers = territories.map { territory in
                let user = userDict[territory.userId]
                return TerritoryWithUser(territory: territory, user: user)
            }
            territoriesWithUsers.sort { $0.territory.timestamp > $1.territory.timestamp } // Most recent first
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func deleteTerritory(_ territory: TerritoryWithUser) async {
        guard let id = territory.territory.id else { return }
        
        do {
            try await firebaseManager.deleteTerritory(id: id)
            await loadTerritories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteAllTerritories(filterUserId: String? = nil) async {
        isLoading = true
        do {
            let itemsToDelete: [TerritoryWithUser]
            if let filterUserId = filterUserId {
                itemsToDelete = territoriesWithUsers.filter { $0.territory.userId == filterUserId }
            } else {
                itemsToDelete = territoriesWithUsers
            }
            
            // Delete all territories
            for territory in itemsToDelete {
                if let id = territory.territory.id {
                    try await firebaseManager.deleteTerritory(id: id)
                }
            }
            await loadTerritories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    TerritoriesListView()
}

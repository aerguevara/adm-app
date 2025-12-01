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
    
    var filteredTerritories: [RemoteTerritory] {
        if searchText.isEmpty {
            return viewModel.territories
        } else {
            return viewModel.territories.filter { territory in
                territory.userId.localizedCaseInsensitiveContains(searchText) ||
                String(territory.centerLatitude).contains(searchText) ||
                String(territory.centerLongitude).contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading territories...")
                } else if filteredTerritories.isEmpty {
                    ContentUnavailableView {
                        Label("No Territories", systemImage: "map.slash")
                    } description: {
                        Text(searchText.isEmpty ? "No territories found" : "No territories match '\(searchText)'")
                    }
                } else {
                    List {
                        ForEach(filteredTerritories) { territory in
                            NavigationLink(destination: TerritoryDetailView(territory: territory)) {
                                TerritoryRow(territory: territory)
                            }
                        }
                        .onDelete(perform: deleteTerritories)
                    }
                    .refreshable {
                        await viewModel.loadTerritories()
                    }
                }
            }
            .navigationTitle("Territories")
            .searchable(text: $searchText, prompt: "Search by user ID or coordinates")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        Label("Delete All", systemImage: "trash.fill")
                    }
                    .disabled(viewModel.territories.isEmpty)
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
                        await viewModel.deleteAllTerritories()
                    }
                }
            } message: {
                Text("Are you sure you want to delete ALL \(viewModel.territories.count) territories? This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if viewModel.territories.isEmpty {
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
        }
    }
}

struct TerritoryRow: View {
    let territory: RemoteTerritory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Territory", systemImage: "map.fill")
                    .font(.headline)
                
                Spacer()
                
                if territory.isExpired {
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
                    Text("Center: \(String(format: "%.4f", territory.centerLatitude)), \(String(format: "%.4f", territory.centerLongitude))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(territory.boundary.count) boundary points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Label(territory.userId, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Created: \(territory.timestamp.shortDate)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Expires: \(territory.expiresAt.shortDate)")
                        .font(.caption2)
                        .foregroundStyle(territory.isExpired ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class TerritoriesViewModel: ObservableObject {
    @Published var territories: [RemoteTerritory] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadTerritories() async {
        isLoading = true
        do {
            territories = try await firebaseManager.fetchTerritories()
            territories.sort { $0.timestamp > $1.timestamp } // Most recent first
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func deleteTerritory(_ territory: RemoteTerritory) async {
        guard let id = territory.id else { return }
        
        do {
            try await firebaseManager.deleteTerritory(id: id)
            await loadTerritories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteAllTerritories() async {
        isLoading = true
        do {
            // Delete all territories
            for territory in territories {
                if let id = territory.id {
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

//
//  ActivitiesListView.swift
//  adm-app
//
//  Created by Codex on 4/12/25.
//

import SwiftUI

struct ActivitiesListView: View {
    @StateObject private var viewModel = ActivitiesViewModel()
    @State private var searchText = ""
    @State private var selectedUserId = ActivitiesListView.allUsersFilterId
    
    private static let allUsersFilterId = "__all_users__"
    
    private var filteredActivities: [ActivityWithUser] {
        var activities = viewModel.activities
        
        if selectedUserId != ActivitiesListView.allUsersFilterId {
            activities = activities.filter { $0.activity.userId == selectedUserId }
        }
        
        if !searchText.isEmpty {
            activities = activities.filter { item in
                item.displayName.localizedCaseInsensitiveContains(searchText) ||
                item.activity.activityType.localizedCaseInsensitiveContains(searchText) ||
                item.activity.userId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return activities
    }
    
    private var totalXPEarned: Int {
        filteredActivities.reduce(0) { $0 + $1.activity.xpBreakdown.total }
    }
    
    private var userFilterOptions: [(id: String, name: String)] {
        var map: [String: String] = [:]
        for item in viewModel.activities {
            let name = item.displayName.isEmpty ? "Sin nombre" : item.displayName
            map[item.activity.userId] = name
        }
        let sorted = map.map { ($0.key, $0.value) }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
        return [(ActivitiesListView.allUsersFilterId, "Todos los usuarios")] + sorted
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("XP total en vista", systemImage: "bolt.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("+\(totalXPEarned) XP")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal)
                .padding(.top, 6)

                userFilterChips

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                        ForEach(filteredActivities) { item in
                            NavigationLink {
                                ActivityDetailView(activity: item.activity)
                            } label: {
                                ActivityCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .overlay {
                if filteredActivities.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView {
                        Label("No Activities", systemImage: "figure.walk")
                    } description: {
                        Text(searchText.isEmpty ? "No activities found" : "No activities match '\(searchText)'")
                    } actions: {
                        Button("Reload") {
                            Task { await viewModel.loadActivities() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Activities")
            .searchable(text: $searchText, prompt: "Search by user or activity")
            .refreshable {
                await viewModel.loadActivities()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .task {
            await viewModel.loadActivities()
        }
        .loadingOverlay(isPresented: viewModel.isLoading, message: "Loading activities...")
    }

    private var userFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(userFilterOptions, id: \.id) { option in
                    let isSelected = selectedUserId == option.id
                    Button {
                        withAnimation { selectedUserId = option.id }
                    } label: {
                        InfoChip(text: option.name,
                                 systemImage: "person.crop.circle",
                                 tint: isSelected ? .blue : .gray,
                                 filled: isSelected)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 4)
    }
}

struct ActivityCardView: View {
    let item: ActivityWithUser

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.displayName.isEmpty ? "Unknown User" : item.displayName)
                        .font(.headline)

                    HStack(spacing: 8) {
                        if item.userLevel > 0 {
                            InfoChip(text: "Lv \(item.userLevel)", systemImage: "star.fill", tint: .yellow, filled: false)
                        }
                        InfoChip(text: item.activity.startDate.mediumDate, systemImage: "calendar", tint: .blue, filled: false)
                    }
                }

                Spacer()

                InfoChip(text: item.activity.activityType.capitalized,
                         systemImage: "figure.walk",
                         tint: .blue)
            }

            HStack(spacing: 8) {
                InfoChip(text: distanceString, systemImage: "figure.walk", tint: .green, filled: false)
                InfoChip(text: durationString, systemImage: "clock", tint: .purple, filled: false)
                if item.activity.xpBreakdown.total > 0 {
                    InfoChip(text: "+\(item.activity.xpBreakdown.total) XP", systemImage: "bolt.fill", tint: .orange)
                }
            }

            if hasTerritoryImpact {
                HStack(spacing: 10) {
                    if item.activity.territoryStats.newCellsCount > 0 {
                        InfoChip(text: "\(item.activity.territoryStats.newCellsCount) new", systemImage: "sparkles", tint: .green, filled: false)
                    }
                    if item.activity.territoryStats.defendedCellsCount > 0 {
                        InfoChip(text: "\(item.activity.territoryStats.defendedCellsCount) defended", systemImage: "shield.fill", tint: .blue, filled: false)
                    }
                    if item.activity.territoryStats.recapturedCellsCount > 0 {
                        InfoChip(text: "\(item.activity.territoryStats.recapturedCellsCount) recaptured", systemImage: "arrow.clockwise", tint: .purple, filled: false)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
        )
    }
    
    private var distanceString: String {
        let km = item.activity.distanceMeters / 1000
        return String(format: "%.2f km", km)
    }
    
    private var durationString: String {
        let totalSeconds = Int(item.activity.durationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    private var hasTerritoryImpact: Bool {
        let stats = item.activity.territoryStats
        return stats.newCellsCount > 0 || stats.defendedCellsCount > 0 || stats.recapturedCellsCount > 0
    }
}

struct ActivityWithUser: Identifiable {
    let activity: ActivitySession
    let user: User?
    
    var id: String {
        activity.id ?? UUID().uuidString
    }
    
    var displayName: String {
        user?.displayName ?? "Unknown User"
    }
    
    var userLevel: Int {
        user?.level ?? 0
    }
}

@MainActor
class ActivitiesViewModel: ObservableObject {
    @Published var activities: [ActivityWithUser] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadActivities() async {
        isLoading = true
        do {
            async let activitiesTask = firebaseManager.fetchActivities()
            async let usersTask = firebaseManager.fetchUsers()
            
            let activities = try await activitiesTask
            let users = try await usersTask
            
            let userDictionary: [String: User] = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                guard let id = user.id else { return nil }
                return (id, user)
            })
            
            var combined = activities.map { activity in
                ActivityWithUser(activity: activity, user: userDictionary[activity.userId])
            }
            
            combined.sort { $0.activity.endDate > $1.activity.endDate }
            self.activities = combined
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

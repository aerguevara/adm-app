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
            VStack(alignment: .leading, spacing: 12) {
                header
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
        .groupedBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Actividades")
                    .font(.title3.weight(.semibold))
                Text("Filtra por usuario o tipo y revisa el impacto de cada salida")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                InfoChip(text: "\(filteredActivities.count) mostradas", systemImage: "figure.walk", tint: .blue, filled: false)
                InfoChip(text: "+\(totalXPEarned) XP", systemImage: "bolt.fill", tint: .orange)
                Spacer()
            }
        }
        .padding(.horizontal)
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
            
            HStack(spacing: 8) {
                Image(systemName: item.activity.route.isEmpty ? "xmark.octagon" : "checkmark.seal.fill")
                    .foregroundStyle(item.hasRoutes ? .green : .red)
                Text(item.hasRoutes ? "Con rutas" : "Sin rutas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(item.hasRoutes ? .green : .red)
            }
            .padding(.top, 2)
        }
        .cardStyle()
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
    var routeCount: Int?
    
    var id: String {
        activity.id ?? UUID().uuidString
    }
    
    var displayName: String {
        user?.displayName ?? "Unknown User"
    }
    
    var userLevel: Int {
        user?.level ?? 0
    }
    
    var hasRoutes: Bool {
        if let routeCount, routeCount > 0 {
            return true
        }
        return !activity.route.isEmpty
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
                ActivityWithUser(
                    activity: activity,
                    user: userDictionary[activity.userId],
                    routeCount: activity.route.isEmpty ? nil : activity.route.count
                )
            }
            
            combined.sort { $0.activity.endDate > $1.activity.endDate }
            self.activities = combined
            Task { await self.loadRouteCountsIfNeeded() }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    private func loadRouteCountsIfNeeded() async {
        let itemsNeedingRoutes = activities.filter { $0.routeCount == nil && ($0.activity.id != nil) }
        guard !itemsNeedingRoutes.isEmpty else { return }
        
        await withTaskGroup(of: (String, Int)?.self) { group in
            for item in itemsNeedingRoutes {
                guard let id = item.activity.id else { continue }
                group.addTask {
                    do {
                        let count = try await self.firebaseManager.fetchRouteCount(for: id)
                        return (id, count)
                    } catch {
                        return nil
                    }
                }
            }
            
            var routeCounts: [String: Int] = [:]
            for await result in group {
                if let (id, count) = result {
                    routeCounts[id] = count
                }
            }
            
            guard !routeCounts.isEmpty else { return }
            
            await MainActor.run {
                self.activities = self.activities.map { item in
                    guard let id = item.activity.id, let count = routeCounts[id] else { return item }
                    var updated = item
                    updated.routeCount = count
                    return updated
                }
            }
        }
    }
}

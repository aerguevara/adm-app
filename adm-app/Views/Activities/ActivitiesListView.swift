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
    @State private var selectedActivityType = "All"
    
    private var filteredActivities: [ActivityWithUser] {
        var activities = viewModel.activities
        
        if selectedActivityType != "All" {
            activities = activities.filter { item in
                item.activity.activityType.localizedCaseInsensitiveCompare(selectedActivityType) == .orderedSame
            }
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
    
    private var activityTypes: [String] {
        let types = Set(viewModel.activities.map { $0.activity.activityType })
        return ["All"] + types.sorted()
    }
    
    var body: some View {
        NavigationStack {
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
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading activities...")
                } else if filteredActivities.isEmpty {
                    ContentUnavailableView {
                        Label("No Activities", systemImage: "figure.walk")
                    } description: {
                        Text(searchText.isEmpty ? "No activities found" : "No activities match '\(searchText)'")
                    }
                }
            }
            .navigationTitle("Activities")
            .searchable(text: $searchText, prompt: "Search by user or activity")
            .refreshable {
                await viewModel.loadActivities()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Activity Type", selection: $selectedActivityType) {
                            ForEach(activityTypes, id: \.self) { type in
                                Text(type == "All" ? "All Types" : type.capitalized).tag(type)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
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
    }
}

struct ActivityCardView: View {
    let item: ActivityWithUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName.isEmpty ? "Unknown User" : item.displayName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        if item.userLevel > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption2)
                                Text("Lv \(item.userLevel)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(item.activity.startDate.mediumDate)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
                
                Text(item.activity.activityType.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            Text(quickSummary)
                .font(.subheadline)
            
            HStack(spacing: 12) {
                Label(distanceString, systemImage: "figure.walk")
                Label(durationString, systemImage: "clock")
                if item.activity.xpBreakdown.total > 0 {
                    Label("+\(item.activity.xpBreakdown.total) XP", systemImage: "bolt.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if hasTerritoryImpact {
                HStack(spacing: 10) {
                    if item.activity.territoryStats.newCellsCount > 0 {
                        Label("\(item.activity.territoryStats.newCellsCount) new", systemImage: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    if item.activity.territoryStats.defendedCellsCount > 0 {
                        Label("\(item.activity.territoryStats.defendedCellsCount) defended", systemImage: "shield.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    if item.activity.territoryStats.recapturedCellsCount > 0 {
                        Label("\(item.activity.territoryStats.recapturedCellsCount) recaptured", systemImage: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundStyle(.purple)
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
    
    private var quickSummary: String {
        var parts: [String] = []
        if item.activity.distanceMeters > 0 {
            parts.append(distanceString)
        }
        parts.append(durationString)
        if item.activity.xpBreakdown.total > 0 {
            parts.append("+\(item.activity.xpBreakdown.total) XP")
        }
        if parts.isEmpty {
            parts.append("No metrics recorded")
        }
        return parts.joined(separator: " • ")
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
            
            combined.sort { $0.activity.startDate > $1.activity.startDate }
            self.activities = combined
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

//
//  FeedListView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct FeedListView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showingAddFeed = false
    @State private var showingDeleteAllAlert = false
    @State private var searchText = ""
    @State private var selectedType: String = "All"
    @State private var selectedUserId: String = FeedListView.allUsersFilterId
    
    private static let allUsersFilterId = "__all_users__"
    
    var filteredFeedItems: [FeedItemWithUser] {
        var items = viewModel.feedItemsWithUsers
        
        // Filter by type
        if selectedType != "All" {
            items = items.filter { $0.feedItem.type == selectedType }
        }
        
        // Filter by user
        if selectedUserId != FeedListView.allUsersFilterId {
            items = items.filter { $0.feedItem.userId == selectedUserId }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            items = items.filter { item in
                item.feedItem.title.localizedCaseInsensitiveContains(searchText) ||
                item.feedItem.subtitle.localizedCaseInsensitiveContains(searchText) ||
                item.displayName.localizedCaseInsensitiveContains(searchText) ||
                item.feedItem.userId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    var feedTypes: [String] {
        ["All"] + FeedType.allCases.map { $0.rawValue }
    }
    
    var userFilterOptions: [(id: String, name: String)] {
        let userDictionary = viewModel.feedItemsWithUsers.reduce(into: [String: String]()) { result, item in
            result[item.feedItem.userId] = item.displayName
        }
        
        let sortedUsers = userDictionary
            .map { ($0.key, $0.value) }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
        
        return [(FeedListView.allUsersFilterId, "All Users")] + sortedUsers
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                    ForEach(filteredFeedItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            NavigationLink(destination: FeedDetailView(feedItem: item.feedItem)) {
                                FeedRow(item: item)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteFeedItem(item.feedItem) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading feed...")
                } else if filteredFeedItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Feed Items", systemImage: "list.bullet.clipboard")
                    } description: {
                        Text(searchText.isEmpty ? "No feed items found" : "No items match '\(searchText)'")
                    }
                }
            }
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "Search feed items")
            .refreshable {
                await viewModel.loadFeedItems()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter by Type", selection: $selectedType) {
                            ForEach(feedTypes, id: \.self) { type in
                                Text(type == "All" ? "All Types" : FeedType(rawValue: type)?.displayName ?? type)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    
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
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        Label("Delete All", systemImage: "trash.fill")
                    }
                    .disabled(viewModel.feedItemsWithUsers.isEmpty)
                    
                    Button {
                        showingAddFeed = true
                    } label: {
                        Label("Add Feed Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFeed) {
                AddFeedView()
            }
            .alert("Delete All Feed Items", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    Task {
                        let filter = selectedUserId == FeedListView.allUsersFilterId ? nil : selectedUserId
                        await viewModel.deleteAllFeedItems(filterUserId: filter)
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(filteredFeedItems.count) feed items? This action cannot be undone.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if viewModel.feedItemsWithUsers.isEmpty {
                    Task {
                        await viewModel.loadFeedItems()
                    }
                }
            }
        }
        .task {
            await viewModel.loadFeedItems()
        }
    }
    
    private func deleteFeedItems(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let item = filteredFeedItems[index]
                await viewModel.deleteFeedItem(item.feedItem)
            }
            // If a user filter is active, reload to ensure filtered view reflects deletions
            if selectedUserId != FeedListView.allUsersFilterId {
                await viewModel.loadFeedItems()
            }
        }
    }
}

struct FeedRow: View {
    let item: FeedItemWithUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.feedItem.title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.rarityColor(for: item.feedItem.rarity))
                        .font(.caption2)
                    Text(item.feedItem.rarity.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rarityColor(for: item.feedItem.rarity))
                }
            }
            
            Text(item.feedItem.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // User information section
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text(item.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
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
                
                if item.userXP > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                            .font(.caption2)
                        Text("\(item.userXP) XP")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(6)
            
            HStack {
                Label(item.feedItem.type, systemImage: typeIcon(for: item.feedItem.type))
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                if item.feedItem.xpEarned > 0 {
                    Label("+\(item.feedItem.xpEarned) XP", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                Text(item.feedItem.date.shortDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func typeIcon(for type: String) -> String {
        switch type {
        case "territoryConquered": return "map.fill"
        case "levelUp": return "arrow.up.circle.fill"
        case "achievement": return "trophy.fill"
        case "challenge": return "flag.fill"
        default: return "circle.fill"
        }
    }
}

@MainActor
class FeedViewModel: ObservableObject {
    @Published var feedItemsWithUsers: [FeedItemWithUser] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadFeedItems() async {
        isLoading = true
        do {
            // Fetch feed items and users in parallel
            async let feedItemsTask = firebaseManager.fetchFeedItems()
            async let usersTask = firebaseManager.fetchUsers()
            
            let feedItems = try await feedItemsTask
            let users = try await usersTask
            
            // Create a dictionary for quick user lookup
            let userDict = Dictionary(uniqueKeysWithValues: users.map { ($0.id ?? "", $0) })
            
            // Combine feed items with user data
            feedItemsWithUsers = feedItems.map { feedItem in
                let user = userDict[feedItem.userId]
                return FeedItemWithUser(feedItem: feedItem, user: user)
            }
            
            // Sort by date, most recent first
            feedItemsWithUsers.sort { $0.feedItem.date > $1.feedItem.date }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func deleteFeedItem(_ item: FeedItem) async {
        guard let id = item.id else { return }
        
        do {
            try await firebaseManager.deleteFeedItem(id: id)
            await loadFeedItems()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteAllFeedItems(filterUserId: String? = nil) async {
        isLoading = true
        do {
            let itemsToDelete: [FeedItemWithUser]
            if let filterUserId = filterUserId {
                itemsToDelete = feedItemsWithUsers.filter { $0.feedItem.userId == filterUserId }
            } else {
                itemsToDelete = feedItemsWithUsers
            }
            
            for item in itemsToDelete {
                if let id = item.feedItem.id {
                    try await firebaseManager.deleteFeedItem(id: id)
                }
            }
            await loadFeedItems()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    FeedListView()
}

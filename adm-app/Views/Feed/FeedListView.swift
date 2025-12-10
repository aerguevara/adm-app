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
    @State private var useGridLayout = true
    
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
            VStack(spacing: 12) {
                header
                filterChips

                ScrollView {
                    if useGridLayout {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                            feedCards
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            feedCards
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .overlay {
                    if filteredFeedItems.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView {
                            Label("No Feed Items", systemImage: "list.bullet.clipboard")
                        } description: {
                            Text(searchText.isEmpty ? "No feed items found" : "No items match '\(searchText)'")
                        } actions: {
                            Button("Add feed item") { showingAddFeed = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "Search feed items")
            .refreshable {
                await viewModel.loadFeedItems()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAllAlert = true
                        } label: {
                            Label("Delete visible items", systemImage: "trash.fill")
                        }
                        .disabled(filteredFeedItems.isEmpty)
                    } label: {
                        Label("Bulk actions", systemImage: "exclamationmark.triangle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
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
        .loadingOverlay(isPresented: viewModel.isLoading, message: "Loading feed...")
        .groupedBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Noticias y logros")
                    .font(.title3.weight(.semibold))
                Text("Explora eventos, logros y acciones compartidas por la comunidad")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                InfoChip(text: "\(filteredFeedItems.count) items", systemImage: "sparkles", tint: .purple, filled: false)
                InfoChip(text: useGridLayout ? "Vista de tarjetas" : "Vista de lista", systemImage: "rectangle.grid.2x2", tint: .blue, filled: false)
                Spacer()
                Picker("Layout", selection: $useGridLayout) {
                    Text("Tarjetas").tag(true)
                    Text("Lista").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
        }
        .padding(.horizontal)
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(feedTypes, id: \.self) { type in
                        let isSelected = selectedType == type
                        Button {
                            withAnimation { selectedType = type }
                        } label: {
                            InfoChip(text: type == "All" ? "All Types" : (FeedType(rawValue: type)?.displayName ?? type),
                                     systemImage: "line.3.horizontal.decrease.circle",
                                     tint: isSelected ? .blue : .gray,
                                     filled: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(userFilterOptions, id: \.id) { option in
                        let isSelected = selectedUserId == option.id
                        Button {
                            withAnimation { selectedUserId = option.id }
                        } label: {
                            InfoChip(text: option.name,
                                     systemImage: "person.crop.circle",
                                     tint: isSelected ? .purple : .gray,
                                     filled: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            HStack {
                Label("\(filteredFeedItems.count) items", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        withAnimation { useGridLayout = false }
                    } label: {
                        Image(systemName: "list.bullet")
                            .padding(8)
                            .background(useGridLayout ? Color.clear : Color.accentColor.opacity(0.15))
                            .clipShape(Circle())
                    }

                    Button {
                        withAnimation { useGridLayout = true }
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .padding(8)
                            .background(useGridLayout ? Color.accentColor.opacity(0.15) : Color.clear)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }

    private var feedCards: some View {
        ForEach(filteredFeedItems) { item in
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(destination: FeedDetailView(feedItem: item.feedItem)) {
                    FeedRow(item: item)
                }
                .buttonStyle(.plain)
            }
            .cardStyle()
            .contextMenu {
                Button(role: .destructive) {
                    Task { await viewModel.deleteFeedItem(item.feedItem) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.blue)
                        Text(item.displayName)
                            .font(.subheadline.weight(.semibold))
                        if item.userLevel > 0 {
                            InfoChip(text: "Lv \(item.userLevel)", systemImage: "star.fill", tint: .yellow, filled: false)
                        }
                        if item.userXP > 0 {
                            InfoChip(text: "\(item.userXP) XP", systemImage: "bolt.fill", tint: .orange, filled: false)
                        }
                    }

                    Text(item.feedItem.title)
                        .font(.headline)
                    Text(item.feedItem.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    InfoChip(text: item.feedItem.rarity.capitalized,
                             systemImage: "sparkles",
                             tint: Color.rarityColor(for: item.feedItem.rarity))
                    InfoChip(text: item.feedItem.date.shortDate,
                             systemImage: "calendar",
                             tint: .blue,
                             filled: false)
                }
            }

            HStack(spacing: 8) {
                InfoChip(text: FeedType(rawValue: item.feedItem.type)?.displayName ?? item.feedItem.type.capitalized,
                         systemImage: typeIcon(for: item.feedItem.type),
                         tint: .blue,
                         filled: false)
                InfoChip(text: item.feedItem.isPersonal ? "Personal" : "Compartido",
                         systemImage: item.feedItem.isPersonal ? "person.fill" : "person.2.fill",
                         tint: .purple,
                         filled: false)
                if item.feedItem.xpEarned > 0 {
                    InfoChip(text: "+\(item.feedItem.xpEarned) XP", systemImage: "bolt.fill", tint: .orange)
                }
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

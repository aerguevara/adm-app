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
    @State private var searchText = ""
    @State private var selectedType: String = "All"
    
    var filteredFeedItems: [FeedItem] {
        var items = viewModel.feedItems
        
        // Filter by type
        if selectedType != "All" {
            items = items.filter { $0.type == selectedType }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle.localizedCaseInsensitiveContains(searchText) ||
                item.userId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    var feedTypes: [String] {
        ["All"] + FeedType.allCases.map { $0.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading feed...")
                } else if filteredFeedItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Feed Items", systemImage: "list.bullet.clipboard")
                    } description: {
                        Text(searchText.isEmpty ? "No feed items found" : "No items match '\(searchText)'")
                    }
                } else {
                    List {
                        ForEach(filteredFeedItems) { item in
                            NavigationLink(destination: FeedDetailView(feedItem: item)) {
                                FeedRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteFeedItems)
                    }
                    .refreshable {
                        await viewModel.loadFeedItems()
                    }
                }
            }
            .navigationTitle("Feed")
            .searchable(text: $searchText, prompt: "Search feed items")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter by Type", selection: $selectedType) {
                            ForEach(feedTypes, id: \.self) { type in
                                Text(type == "All" ? "All Types" : FeedType(rawValue: type)?.displayName ?? type)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
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
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
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
                await viewModel.deleteFeedItem(item)
            }
        }
    }
}

struct FeedRow: View {
    let item: FeedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.rarityColor(for: item.rarity))
                        .font(.caption2)
                    Text(item.rarity.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rarityColor(for: item.rarity))
                }
            }
            
            Text(item.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(item.type, systemImage: typeIcon(for: item.type))
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                if item.xpEarned > 0 {
                    Label("+\(item.xpEarned) XP", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                Text(item.date.shortDate)
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
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadFeedItems() async {
        isLoading = true
        do {
            feedItems = try await firebaseManager.fetchFeedItems()
            feedItems.sort { $0.date > $1.date } // Most recent first
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
}

#Preview {
    FeedListView()
}

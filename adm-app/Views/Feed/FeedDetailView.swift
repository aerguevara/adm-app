//
//  FeedDetailView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct FeedDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FeedDetailViewModel
    @State private var showingDeleteAlert = false
    
    init(feedItem: FeedItem) {
        _viewModel = StateObject(wrappedValue: FeedDetailViewModel(feedItem: feedItem))
    }
    
    var body: some View {
        Form {
            Section("Content") {
                TextField("Title", text: $viewModel.title)
                
                TextField("Subtitle", text: $viewModel.subtitle, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Type & Rarity") {
                Picker("Type", selection: $viewModel.type) {
                    ForEach(FeedType.allCases, id: \.rawValue) { feedType in
                        Text(feedType.displayName).tag(feedType.rawValue)
                    }
                }
                
                Picker("Rarity", selection: $viewModel.rarity) {
                    ForEach(Rarity.allCases, id: \.rawValue) { rarity in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color.rarityColor(for: rarity.rawValue))
                            Text(rarity.displayName)
                        }
                        .tag(rarity.rawValue)
                    }
                }
            }
            
            Section("Details") {
                TextField("User ID", text: $viewModel.userId)
                
                TextField("Related User Name", text: $viewModel.relatedUserName)
                
                Stepper("XP Earned: \(viewModel.xpEarned)", value: $viewModel.xpEarned, in: 0...10000, step: 5)
                
                Toggle("Is Personal", isOn: $viewModel.isPersonal)
            }
            
            Section("Timestamp") {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Feed Item", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Feed Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveFeedItem()
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert("Delete Feed Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteFeedItem()
                    if !viewModel.showError {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this feed item?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

@MainActor
class FeedDetailViewModel: ObservableObject {
    @Published var title: String
    @Published var subtitle: String
    @Published var type: String
    @Published var rarity: String
    @Published var userId: String
    @Published var relatedUserName: String
    @Published var xpEarned: Int
    @Published var isPersonal: Bool
    @Published var date: Date
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let feedItem: FeedItem
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !title.isEmpty && !subtitle.isEmpty && !userId.isEmpty
    }
    
    init(feedItem: FeedItem) {
        self.feedItem = feedItem
        self.title = feedItem.title
        self.subtitle = feedItem.subtitle
        self.type = feedItem.type
        self.rarity = feedItem.rarity
        self.userId = feedItem.userId
        self.relatedUserName = feedItem.relatedUserName
        self.xpEarned = feedItem.xpEarned
        self.isPersonal = feedItem.isPersonal
        self.date = feedItem.date
    }
    
    func saveFeedItem() async {
        let updatedItem = FeedItem(
            id: feedItem.id,
            date: date,
            isPersonal: isPersonal,
            rarity: rarity,
            relatedUserName: relatedUserName,
            subtitle: subtitle,
            title: title,
            type: type,
            userId: userId,
            xpEarned: xpEarned
        )
        
        do {
            try await firebaseManager.updateFeedItem(updatedItem)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteFeedItem() async {
        guard let id = feedItem.id else { return }
        
        do {
            try await firebaseManager.deleteFeedItem(id: id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

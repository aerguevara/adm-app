//
//  AddFeedView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct AddFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFeedViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Usuario") {
                    if viewModel.isLoadingUsers {
                        ProgressView("Cargando usuarios...")
                    } else if viewModel.users.isEmpty {
                        ContentUnavailableView {
                            Label("Sin usuarios", systemImage: "person.slash")
                        } description: {
                            Text("No hay usuarios disponibles para asignar el feed")
                        }
                    } else {
                        Picker("Selecciona usuario", selection: $viewModel.userId) {
                            ForEach(viewModel.users, id: \.id) { user in
                                if let id = user.id {
                                    Text(user.displayName.isEmpty ? (user.email ?? "Sin nombre") : user.displayName)
                                        .tag(id)
                                }
                            }
                        }
                        .onChange(of: viewModel.userId) { _, newValue in
                            viewModel.updateRelatedNameForSelectedUser(newValue)
                        }
                    }
                }
                
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
                        .textInputAutocapitalization(.never)
                    
                    TextField("Related User Name (optional)", text: $viewModel.relatedUserName)
                    
                    Stepper("XP Earned: \(viewModel.xpEarned)", value: $viewModel.xpEarned, in: 0...10000, step: 5)
                    
                    Toggle("Is Personal", isOn: $viewModel.isPersonal)
                }
                
                Section {
                    Text("The feed item will be created with the current timestamp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Feed Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await viewModel.addFeedItem()
                            if !viewModel.showError {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .task {
                await viewModel.loadUsers()
            }
        }
    }
}

@MainActor
class AddFeedViewModel: ObservableObject {
    @Published var title = ""
    @Published var subtitle = ""
    @Published var type = FeedType.territoryConquered.rawValue
    @Published var rarity = Rarity.common.rawValue
    @Published var userId = ""
    @Published var relatedUserName = ""
    @Published var xpEarned = 0
    @Published var isPersonal = true
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var users: [User] = []
    @Published var isLoadingUsers = false
    
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !title.isEmpty && !subtitle.isEmpty && !userId.isEmpty
    }
    
    func loadUsers() async {
        isLoadingUsers = true
        defer { isLoadingUsers = false }
        do {
            let fetched = try await firebaseManager.fetchUsers()
            users = fetched
                .filter { $0.id != nil }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            if userId.isEmpty, let firstId = users.first?.id {
                userId = firstId
                updateRelatedNameForSelectedUser(firstId)
            } else if !userId.isEmpty {
                updateRelatedNameForSelectedUser(userId)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func updateRelatedNameForSelectedUser(_ id: String) {
        guard let selected = users.first(where: { $0.id == id }) else { return }
        relatedUserName = selected.displayName
    }
    
    func addFeedItem() async {
        let newItem = FeedItem(
            date: Date(),
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
            _ = try await firebaseManager.addFeedItem(newItem)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddFeedView()
}

//
//  UsersListView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI
import FirebaseFirestore

struct UsersListView: View {
    @StateObject private var viewModel = UsersViewModel()
    @State private var showingAddUser = false
    @State private var showingDeleteAllAlert = false
    @State private var showingResetAlert = false
    @State private var showingMasterWipeAlert = false
    @State private var useGridLayout = true
    @State private var searchText = ""
    @State private var userToReset: User?
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { user in
                user.displayName.localizedCaseInsensitiveContains(searchText) ||
                (user.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Label("\(filteredUsers.count) users", systemImage: "person.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            withAnimation { useGridLayout = false }
                        } label: {
                            Image(systemName: "list.bullet")
                                .imageScale(.medium)
                                .padding(8)
                                .background(useGridLayout ? Color.clear : Color.accentColor.opacity(0.15))
                                .clipShape(Circle())
                        }

                        Button {
                            withAnimation { useGridLayout = true }
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .imageScale(.medium)
                                .padding(8)
                                .background(useGridLayout ? Color.accentColor.opacity(0.15) : Color.clear)
                                .clipShape(Circle())
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                ScrollView {
                    if useGridLayout {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                            userCards
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            userCards
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .overlay {
                    if filteredUsers.isEmpty && !(viewModel.isLoading || viewModel.isMasterWiping) {
                        ContentUnavailableView {
                            Label("No Users", systemImage: "person.slash")
                        } description: {
                            Text(searchText.isEmpty ? "No users found in the database" : "No users match '\(searchText)'")
                        } actions: {
                            Button("Add user") { showingAddUser = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Users")
            .searchable(text: $searchText, prompt: "Search by name or email")
            .refreshable {
                await viewModel.loadUsers(forceReload: true)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteAllAlert = true
                        } label: {
                            Label("Delete All", systemImage: "trash.fill")
                        }
                        .disabled(viewModel.users.isEmpty)

                        Button(role: .destructive) {
                            showingMasterWipeAlert = true
                        } label: {
                            Label("Borrado maestro", systemImage: "exclamationmark.triangle.fill")
                        }
                        .disabled(viewModel.isMasterWiping)
                    } label: {
                        Label("Bulk actions", systemImage: "exclamationmark.triangle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.closeWeeklyRanking()
                        }
                    } label: {
                        Label("Close Ranking", systemImage: "trophy.circle")
                    }
                    .disabled(viewModel.users.isEmpty)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddUser = true
                    } label: {
                        Label("Add User", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView()
            }
            .alert("Reset data for \(userToReset?.displayName ?? "this user")?", isPresented: $showingResetAlert, presenting: userToReset) { selected in
                Button("Cancel", role: .cancel) {
                    userToReset = nil
                }
                Button("Reset", role: .destructive) {
                    Task {
                        await viewModel.deleteUserData(for: selected)
                        userToReset = nil
                    }
                }
            } message: { selected in
                Text("This will reset XP to 0, level to 1, and delete feed and territories for \(selected.displayName). The user account will remain.")
            }
            .alert("Delete All Users", isPresented: $showingDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    Task {
                        await viewModel.deleteAllUsers()
                    }
                }
            } message: {
                Text("Are you sure you want to delete ALL \(viewModel.users.count) users? This action cannot be undone.")
            }
            .alert("Borrado maestro", isPresented: $showingMasterWipeAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Borrar todo", role: .destructive) {
                    Task { await viewModel.masterWipeAllData() }
                }
            } message: {
                Text("Esto eliminará TODOS los datos de activities (con subcolecciones), feed y remote_territories de todos los usuarios. No elimina las cuentas. ¿Continuar?")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if viewModel.users.isEmpty {
                    Task {
                        await viewModel.loadUsers()
                    }
                }
            }
        }
        .loadingOverlay(isPresented: viewModel.isLoading || viewModel.isMasterWiping,
                        message: viewModel.isMasterWiping ? "Ejecutando borrado maestro..." : "Loading users...")
        .task {
            await viewModel.loadUsers()
        }
    }

    private var userCards: some View {
        ForEach(filteredUsers) { user in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text(user.displayName.isEmpty ? "No Name" : user.displayName)
                        .font(.headline)
                    Spacer()
                    Menu {
                        Button {
                            userToReset = user
                            showingResetAlert = true
                        } label: {
                            Label("Reset progress", systemImage: "arrow.counterclockwise.circle")
                        }

                        Button(role: .destructive) {
                            Task { await viewModel.deleteUser(user) }
                        } label: {
                            Label("Delete user", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink(destination: UserDetailView(user: user)) {
                    UserRow(user: user)
                }
                .buttonStyle(.plain)
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
        }
    }
}

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(urlString: user.avatarURL, size: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(user.displayName.isEmpty ? "No Name" : user.displayName)
                        .font(.headline)
                    Spacer()
                    InfoChip(text: "Lv \(user.level)", systemImage: "star.fill", tint: .yellow)
                        .font(.caption)
                }

                Text(user.email ?? "No email")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    InfoChip(text: "\(user.xp) XP", systemImage: "bolt.fill", tint: .orange)
                    Spacer()
                    InfoChip(text: "Joined \(user.joinedAt.shortDate)", systemImage: "calendar", tint: .blue, filled: false)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var isMasterWiping = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    private var listenerRegistration: ListenerRegistration?
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func loadUsers(forceReload: Bool = false) async {
        if forceReload {
            listenerRegistration?.remove()
            listenerRegistration = nil
        } else {
            // If we are already listening, no need to do anything
            guard listenerRegistration == nil else { return }
        }
        
        isLoading = true
        
        listenerRegistration = firebaseManager.listenToCollection(FirebaseCollection.users) { [weak self] (users: [User]) in
            guard let self = self else { return }
            
            self.users = users.sorted { $0.joinedAt > $1.joinedAt }
            self.isLoading = false
        }
    }
    
    func deleteUser(_ user: User) async {
        guard let id = user.id else { return }
        
        do {
            try await firebaseManager.deleteUser(id: id)
            // No need to reload, listener will handle it
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteUserData(for user: User) async {
        guard let userId = user.id else { return }
        isLoading = true
        do {
            // Reset user XP
            var updatedUser = user
            updatedUser.xp = 0
            updatedUser.level = 1
            try await firebaseManager.updateUser(updatedUser)
            
            // Delete feed items for user
            let feedItems = try await firebaseManager.fetchFeedItems(for: userId)
            for item in feedItems {
                if let id = item.id {
                    try await firebaseManager.deleteFeedItem(id: id)
                }
            }
            
            // Delete activities for user
            let activities = try await firebaseManager.fetchActivities(filterUserId: userId)
            for activity in activities {
                if let id = activity.id {
                    try await firebaseManager.deleteActivityWithChildren(id: id)
                }
            }
            
            // Delete territories for user
            let territories = try await firebaseManager.fetchTerritories(for: userId)
            for territory in territories {
                if let id = territory.id {
                    try await firebaseManager.deleteTerritoryWithChildren(id: id)
                }
            }
            
            await loadUsers(forceReload: true)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func deleteAllUsers() async {
        isLoading = true
        do {
            // Delete all users
            for user in users {
                if let id = user.id {
                    try await firebaseManager.deleteUser(id: id)
                }
            }
            // No need to reload, listener will handle it
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func masterWipeAllData() async {
        isMasterWiping = true
        defer { isMasterWiping = false }
        do {
            // Reset all users XP/level
            for var user in users {
                user.xp = 0
                user.level = 1
                try await firebaseManager.updateUser(user)
            }
            
            // Feed
            let feedItems = try await firebaseManager.fetchFeedItems()
            for item in feedItems {
                if let id = item.id {
                    try await firebaseManager.deleteFeedItem(id: id)
                }
            }
            
            // Activities (with subcollections)
            let activities = try await firebaseManager.fetchActivities()
            for activity in activities {
                if let id = activity.id {
                    try await firebaseManager.deleteActivityWithChildren(id: id)
                }
            }
            
            // Territories (with subcollections)
            try await firebaseManager.deleteTerritories()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func closeWeeklyRanking() async {
        isLoading = true
        
        // 1. Get current users sorted by XP
        let sortedUsers = users.sorted { $0.xp > $1.xp }
        
        // 2. Update previousRank for each user
        var usersToUpdate: [User] = []
        
        for (index, user) in sortedUsers.enumerated() {
            var updatedUser = user
            updatedUser.previousRank = index + 1
            usersToUpdate.append(updatedUser)
        }
        
        // 3. Batch update
        do {
            try await firebaseManager.batchUpdateUsers(usersToUpdate)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    UsersListView()
}

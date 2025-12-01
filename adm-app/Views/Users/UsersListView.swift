//
//  UsersListView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct UsersListView: View {
    @StateObject private var viewModel = UsersViewModel()
    @State private var showingAddUser = false
    @State private var showingDeleteAllAlert = false
    @State private var searchText = ""
    
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
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading users...")
                } else if filteredUsers.isEmpty {
                    ContentUnavailableView {
                        Label("No Users", systemImage: "person.slash")
                    } description: {
                        Text(searchText.isEmpty ? "No users found in the database" : "No users match '\(searchText)'")
                    }
                } else {
                    List {
                        ForEach(filteredUsers) { user in
                            NavigationLink(destination: UserDetailView(user: user)) {
                                UserRow(user: user)
                            }
                        }
                        .onDelete(perform: deleteUsers)
                    }
                    .refreshable {
                        await viewModel.loadUsers()
                    }
                }
            }
            .navigationTitle("Users")
            .searchable(text: $searchText, prompt: "Search by name or email")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showingDeleteAllAlert = true
                    } label: {
                        Label("Delete All", systemImage: "trash.fill")
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
        .task {
            await viewModel.loadUsers()
        }
    }
    
    private func deleteUsers(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let user = filteredUsers[index]
                await viewModel.deleteUser(user)
            }
        }
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(user.displayName.isEmpty ? "No Name" : user.displayName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                    Text("Lv \(user.level)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(user.email ?? "No email")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label("\(user.xp) XP", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Text("Joined: \(user.joinedAt.shortDate)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
class UsersViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadUsers() async {
        isLoading = true
        do {
            users = try await firebaseManager.fetchUsers()
            users.sort { $0.joinedAt > $1.joinedAt } // Most recent first
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
    
    func deleteUser(_ user: User) async {
        guard let id = user.id else { return }
        
        do {
            try await firebaseManager.deleteUser(id: id)
            await loadUsers() // Reload list
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
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
            await loadUsers() // Reload list
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

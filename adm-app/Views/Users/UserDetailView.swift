//
//  UserDetailView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct UserDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UserDetailViewModel
    @State private var showingDeleteAlert = false
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserDetailViewModel(user: user))
    }
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Display Name", text: $viewModel.displayName)
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            
            Section("Stats") {
                Stepper("Level: \(viewModel.level)", value: $viewModel.level, in: 1...100)
                
                Stepper("XP: \(viewModel.xp)", value: $viewModel.xp, in: 0...999999, step: 10)
            }
            
            Section("Timestamps") {
                LabeledContent("Joined At") {
                    Text(viewModel.joinedAt.mediumDate)
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Last Updated") {
                    Text(viewModel.lastUpdated.mediumDate)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete User", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveUser()
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert("Delete User", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser()
                    if !viewModel.showError {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this user? This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

@MainActor
class UserDetailViewModel: ObservableObject {
    @Published var displayName: String
    @Published var email: String
    @Published var level: Int
    @Published var xp: Int
    @Published var joinedAt: Date
    @Published var lastUpdated: Date
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let user: User
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !displayName.isEmpty && !email.isEmpty && email.isValidEmail
    }
    
    init(user: User) {
        self.user = user
        self.displayName = user.displayName
        self.email = user.email
        self.level = user.level
        self.xp = user.xp
        self.joinedAt = user.joinedAt
        self.lastUpdated = user.lastUpdated
    }
    
    func saveUser() async {
        let updatedUser = User(
            id: user.id,
            displayName: displayName,
            email: email,
            joinedAt: joinedAt,
            lastUpdated: Date(), // Update timestamp
            level: level,
            xp: xp
        )
        
        do {
            try await firebaseManager.updateUser(updatedUser)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteUser() async {
        guard let id = user.id else { return }
        
        do {
            try await firebaseManager.deleteUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

//
//  AddUserView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddUserViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Display Name", text: $viewModel.displayName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Email (optional)", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                
                Section("Initial Stats") {
                    Stepper("Level: \(viewModel.level)", value: $viewModel.level, in: 1...100)
                    
                    Stepper("XP: \(viewModel.xp)", value: $viewModel.xp, in: 0...999999, step: 10)
                }
                
                Section {
                    Text("The user will be created with the current timestamp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add User")
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
                            await viewModel.addUser()
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
        }
    }
}

@MainActor
class AddUserViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var email = ""
    @Published var level = 1
    @Published var xp = 0
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !displayName.isEmpty && (email.isEmpty || email.isValidEmail)
    }
    
    func addUser() async {
        let newUser = User(
            displayName: displayName,
            email: email.isEmpty ? nil : email,
            joinedAt: Date(),
            lastUpdated: Date(),
            level: level,
            xp: xp
        )
        
        do {
            _ = try await firebaseManager.addUser(newUser)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddUserView()
}

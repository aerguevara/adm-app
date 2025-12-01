//
//  TerritoryDetailView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct TerritoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TerritoryDetailViewModel
    @State private var showingDeleteAlert = false
    @State private var showingBoundary = false
    
    init(territory: RemoteTerritory) {
        _viewModel = StateObject(wrappedValue: TerritoryDetailViewModel(territory: territory))
    }
    
    var body: some View {
        Form {
            Section("Status") {
                HStack {
                    Text(viewModel.territory.isExpired ? "Expired" : "Active")
                        .foregroundStyle(viewModel.territory.isExpired ? .red : .green)
                    Spacer()
                    Image(systemName: viewModel.territory.isExpired ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(viewModel.territory.isExpired ? .red : .green)
                }
            }
            
            Section("Center Coordinates") {
                HStack {
                    Text("Latitude")
                    Spacer()
                    TextField("Latitude", value: $viewModel.centerLatitude, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Longitude")
                    Spacer()
                    TextField("Longitude", value: $viewModel.centerLongitude, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section {
                Button {
                    showingBoundary.toggle()
                } label: {
                    HStack {
                        Text("Boundary Points")
                        Spacer()
                        Text("\(viewModel.territory.boundary.count) points")
                            .foregroundStyle(.secondary)
                        Image(systemName: showingBoundary ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
                
                if showingBoundary {
                    ForEach(Array(viewModel.territory.boundary.enumerated()), id: \.offset) { index, coord in
                        HStack {
                            Text("Point \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(String(format: "%.4f", coord.latitude)), \(String(format: "%.4f", coord.longitude))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Details") {
                TextField("User ID", text: $viewModel.userId)
                    .textInputAutocapitalization(.never)
            }
            
            Section("Timestamps") {
                DatePicker("Created", selection: $viewModel.timestamp, displayedComponents: [.date, .hourAndMinute])
                
                DatePicker("Expires", selection: $viewModel.expiresAt, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Territory", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Territory Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await viewModel.saveTerritory()
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
        .alert("Delete Territory", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTerritory()
                    if !viewModel.showError {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this territory?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

@MainActor
class TerritoryDetailViewModel: ObservableObject {
    @Published var centerLatitude: Double
    @Published var centerLongitude: Double
    @Published var userId: String
    @Published var timestamp: Date
    @Published var expiresAt: Date
    @Published var showError = false
    @Published var errorMessage = ""
    
    let territory: RemoteTerritory
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !userId.isEmpty
    }
    
    init(territory: RemoteTerritory) {
        self.territory = territory
        self.centerLatitude = territory.centerLatitude
        self.centerLongitude = territory.centerLongitude
        self.userId = territory.userId
        self.timestamp = territory.timestamp
        self.expiresAt = territory.expiresAt
    }
    
    func saveTerritory() async {
        let updatedTerritory = RemoteTerritory(
            id: territory.id,
            boundary: territory.boundary, // Keep existing boundary
            centerLatitude: centerLatitude,
            centerLongitude: centerLongitude,
            expiresAt: expiresAt,
            timestamp: timestamp,
            userId: userId
        )
        
        do {
            try await firebaseManager.updateTerritory(updatedTerritory)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteTerritory() async {
        guard let id = territory.id else { return }
        
        do {
            try await firebaseManager.deleteTerritory(id: id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

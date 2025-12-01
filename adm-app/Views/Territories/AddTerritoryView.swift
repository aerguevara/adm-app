//
//  AddTerritoryView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI

struct AddTerritoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddTerritoryViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Center Coordinates") {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        TextField("40.447", value: $viewModel.centerLatitude, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("-3.633", value: $viewModel.centerLongitude, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    ForEach(Array(viewModel.boundaryPoints.enumerated()), id: \.offset) { index, point in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Point \(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                TextField("Latitude", value: Binding(
                                    get: { viewModel.boundaryPoints[index].latitude },
                                    set: { viewModel.boundaryPoints[index].latitude = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                
                                Text(",")
                                    .foregroundStyle(.secondary)
                                
                                TextField("Longitude", value: Binding(
                                    get: { viewModel.boundaryPoints[index].longitude },
                                    set: { viewModel.boundaryPoints[index].longitude = $0 }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                
                                Button(role: .destructive) {
                                    viewModel.removeBoundaryPoint(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    
                    Button {
                        viewModel.addBoundaryPoint()
                    } label: {
                        Label("Add Boundary Point", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Boundary Points")
                } footer: {
                    Text("A territory needs at least 3 boundary points to form a valid polygon.")
                }
                
                Section("Details") {
                    TextField("User ID", text: $viewModel.userId)
                        .textInputAutocapitalization(.never)
                    
                    DatePicker("Expires At", selection: $viewModel.expiresAt, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Text("The territory will be created with the current timestamp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Territory")
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
                            await viewModel.addTerritory()
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
class AddTerritoryViewModel: ObservableObject {
    @Published var centerLatitude: Double = 0.0
    @Published var centerLongitude: Double = 0.0
    @Published var userId = ""
    @Published var expiresAt: Date
    @Published var boundaryPoints: [Coordinate] = [
        Coordinate(latitude: 0.0, longitude: 0.0),
        Coordinate(latitude: 0.0, longitude: 0.0),
        Coordinate(latitude: 0.0, longitude: 0.0),
        Coordinate(latitude: 0.0, longitude: 0.0)
    ]
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        // Default expiration: 7 days from now
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    var isValid: Bool {
        !userId.isEmpty && boundaryPoints.count >= 3
    }
    
    func addBoundaryPoint() {
        boundaryPoints.append(Coordinate(latitude: 0.0, longitude: 0.0))
    }
    
    func removeBoundaryPoint(at index: Int) {
        guard boundaryPoints.count > 3 else {
            errorMessage = "A territory must have at least 3 boundary points"
            showError = true
            return
        }
        boundaryPoints.remove(at: index)
    }
    
    func addTerritory() async {
        let newTerritory = RemoteTerritory(
            boundary: boundaryPoints,
            centerLatitude: centerLatitude,
            centerLongitude: centerLongitude,
            expiresAt: expiresAt,
            timestamp: Date(),
            userId: userId
        )
        
        do {
            _ = try await firebaseManager.addTerritory(newTerritory)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddTerritoryView()
}

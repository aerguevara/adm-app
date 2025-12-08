//
//  TerritoryDetailView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI
import MapKit

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
            Section("Mapa") {
                TerritoryMapPreview(
                    boundary: viewModel.territory.boundary,
                    center: CLLocationCoordinate2D(latitude: viewModel.centerLatitude, longitude: viewModel.centerLongitude)
                )
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
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
            
            Section("Owners (historial)") {
                if viewModel.isLoadingHistory {
                    ProgressView("Loading history...")
                } else if viewModel.history.isEmpty {
                    ContentUnavailableView {
                        Label("Sin historial", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("No hay cambios registrados para este territorio")
                    }
                } else {
                    ForEach(viewModel.history) { change in
                        TerritoryChangeRow(
                            change: change,
                            userName: viewModel.userName(for:),
                            activity: viewModel.activity(for:)
                        )
                    }
                }
            }
            
            Section("Timestamps") {
                DatePicker("Created", selection: $viewModel.timestamp, displayedComponents: [.date, .hourAndMinute])
                
                DatePicker("Expires", selection: $viewModel.expiresAt, displayedComponents: [.date, .hourAndMinute])
                
                if let activityEndAt = viewModel.activityEndAt {
                    LabeledContent("Activity Ends") {
                        Text(activityEndAt.mediumDate)
                            .foregroundStyle(.secondary)
                    }
                }
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
        .task {
            await viewModel.loadHistory()
            await viewModel.loadUsers()
        }
    }
}

struct TerritoryChangeRow: View {
    let change: TerritoryChange
    let userName: (String?) -> String
    let activity: (String?) -> ActivitySession?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(change.changeType.capitalized)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Text(change.changedAt.mediumDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Usuario")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Nuevo: \(userName(change.newUserId))")
                    .font(.caption)
                if change.previousUserId != nil {
                    Text("Anterior: \(userName(change.previousUserId))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Actividad")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                activityBlock(title: "Nueva", session: activity(change.newActivityId))
                if change.previousActivityId != nil {
                    activityBlock(title: "Anterior", session: activity(change.previousActivityId), isSecondary: true)
                }
            }
            
            if let ends = change.activityEndAt {
                Text("Activity ends: \(ends.mediumDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let exp = change.expiresAt {
                Text("Expires: \(exp.mediumDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func activityBlock(title: String, session: ActivitySession?, isSecondary: Bool = false) -> some View {
        if let session {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title): \(session.activityType.capitalized)")
                    .font(.caption)
                    .foregroundStyle(isSecondary ? .secondary : .primary)
                Text("Inicio: \(session.startDate.mediumDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Fin: \(session.endDate.mediumDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("\(title): ID \(shortId(change.newActivityId ?? change.previousActivityId))")
                .font(.caption)
                .foregroundStyle(isSecondary ? .secondary : .primary)
        }
    }
    
    private func shortId(_ id: String?) -> String {
        guard let id, !id.isEmpty else { return "N/A" }
        return id.count > 8 ? String(id.prefix(8)) + "…" : id
    }
}

struct TerritoryMapPreview: UIViewRepresentable {
    let boundary: [Coordinate]
    let center: CLLocationCoordinate2D
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.delegate = context.coordinator
        mapView.removeOverlays(mapView.overlays)
        
        if !boundary.isEmpty {
            let coords = boundary.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            let polygon = MKPolygon(coordinates: coords, count: coords.count)
            mapView.addOverlay(polygon)
            
            let rect = polygon.boundingMapRect
            if !rect.isNull {
                mapView.setVisibleMapRect(
                    rect,
                    edgePadding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),
                    animated: false
                )
            }
        } else {
            let region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: false)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polygon = overlay as? MKPolygon else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.25)
            renderer.strokeColor = UIColor.systemGreen
            renderer.lineWidth = 2
            return renderer
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
    @Published var activityEndAt: Date?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var history: [TerritoryChange] = []
    @Published var isLoadingHistory = false
    @Published var users: [User] = []
    @Published var isLoadingUsers = false
    private var usersMap: [String: User] = [:]
    private var activitiesMap: [String: ActivitySession] = [:]
    
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
        self.activityEndAt = territory.activityEndAt
    }
    
    func loadHistory() async {
        guard let territoryId = territory.id else { return }
        isLoadingHistory = true
        do {
            history = try await firebaseManager.fetchTerritoryHistory(territoryId: territoryId)
            await resolveMissingUsers()
            await resolveMissingActivities()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingHistory = false
    }
    
    func loadUsers() async {
        isLoadingUsers = true
        defer { isLoadingUsers = false }
        do {
            users = try await firebaseManager.fetchUsers()
            usersMap = Dictionary(uniqueKeysWithValues: users.compactMap { user in
                guard let id = user.id else { return nil }
                return (id, user)
            })
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func userName(for id: String?) -> String {
        guard let id, !id.isEmpty else { return "N/A" }
        if let cached = usersMap[id]?.displayName, !cached.isEmpty {
            return cached
        }
        let short = id.count > 6 ? String(id.prefix(6)) + "…" : id
        return "Desconocido (\(short))"
    }
    
    func activityLabel(for id: String?) -> String {
        guard let id, !id.isEmpty else { return "N/A" }
        if let activity = activitiesMap[id] {
            let date = activity.endDate.shortDate
            let type = activity.activityType.capitalized
            return "\(type) • \(date)"
        }
        let short = id.count > 8 ? String(id.prefix(8)) + "…" : id
        return "ID \(short)"
    }

    private func resolveMissingUsers() async {
        let ids = history.compactMap { [$0.newUserId, $0.previousUserId] }.flatMap { $0 }.compactMap { $0 }
        let uniqueIds = Set(ids).subtracting(usersMap.keys)
        for id in uniqueIds {
            if let user = try? await firebaseManager.fetchUser(id: id) {
                usersMap[id] = user
            }
        }
    }
    
    private func resolveMissingActivities() async {
        let ids = history.compactMap { [$0.newActivityId, $0.previousActivityId] }.flatMap { $0 }.compactMap { $0 }
        let uniqueIds = Set(ids).subtracting(activitiesMap.keys)
        for id in uniqueIds {
            if let activity = try? await firebaseManager.fetchActivity(id: id) {
                activitiesMap[id] = activity
            }
        }
    }
    
    func activity(for id: String?) -> ActivitySession? {
        guard let id else { return nil }
        return activitiesMap[id]
    }
    
    func saveTerritory() async {
        let updatedTerritory = RemoteTerritory(
            id: territory.id,
            boundary: territory.boundary, // Keep existing boundary
            centerLatitude: centerLatitude,
            centerLongitude: centerLongitude,
            expiresAt: expiresAt,
            timestamp: timestamp,
            activityEndAt: activityEndAt,
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

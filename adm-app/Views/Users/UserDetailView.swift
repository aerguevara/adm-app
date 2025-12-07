//
//  UserDetailView.swift
//  adm-app
//
//  Created by Anyelo Reyes on 1/12/25.
//

import SwiftUI
import MapKit

struct UserDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UserDetailViewModel
    @State private var showingDeleteAlert = false
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserDetailViewModel(user: user))
    }
    
    var body: some View {
        Form {
            Section("Territories") {
                if viewModel.isLoadingTerritories {
                    ProgressView("Loading territories...")
                } else if viewModel.territories.isEmpty {
                    ContentUnavailableView {
                        Label("No Territories", systemImage: "map")
                    } description: {
                        Text("This user has no territories")
                    }
                } else {
                    TerritoriesOverviewMapContainer(territories: viewModel.territories)
                        .frame(height: 280)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            }
            
            Section("Basic Information") {
                TextField("Display Name", text: $viewModel.displayName)
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            
            Section("Stats") {
                Stepper("Level: \(viewModel.level)", value: $viewModel.level, in: 1...100)
                
                HStack {
                    Text("XP")
                    Spacer()
                    TextField("XP", value: $viewModel.xp, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Stepper("Previous Rank: \(viewModel.previousRank)", value: $viewModel.previousRank, in: 0...9999)
            }
            
            Section("Timestamps") {
                LabeledContent("Joined At") {
                    Text(viewModel.joinedAt.mediumDate)
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Last Updated") {
                    Text(viewModel.lastUpdated?.mediumDate ?? "Never")
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
        .task {
            await viewModel.loadTerritories()
        }
    }
}

@MainActor
class UserDetailViewModel: ObservableObject {
    @Published var displayName: String
    @Published var email: String
    @Published var level: Int
    @Published var xp: Int
    @Published var previousRank: Int
    @Published var joinedAt: Date
    @Published var lastUpdated: Date?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var territories: [RemoteTerritory] = []
    @Published var isLoadingTerritories = false
    
    private let user: User
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !displayName.isEmpty && (email.isEmpty || email.isValidEmail)
    }
    
    init(user: User) {
        self.user = user
        self.displayName = user.displayName
        self.email = user.email ?? ""
        self.level = user.level
        self.xp = user.xp
        self.previousRank = user.previousRank ?? 0
        self.joinedAt = user.joinedAt
        self.lastUpdated = user.lastUpdated
    }
    
    func saveUser() async {
        let updatedUser = User(
            id: user.id,
            displayName: displayName,
            email: email.isEmpty ? nil : email,
            joinedAt: joinedAt,
            lastUpdated: Date(), // Update timestamp
            level: level,
            xp: xp,
            previousRank: previousRank == 0 ? nil : previousRank
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
    
    func loadTerritories() async {
        guard let userId = user.id else { return }
        
        isLoadingTerritories = true
        do {
            territories = try await firebaseManager.fetchTerritories(for: userId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingTerritories = false
    }
    
}

struct TerritoriesOverviewMapView: UIViewRepresentable {
    let territories: [RemoteTerritory]
    @ObservedObject var controller: TerritoryMapController
    let focusId: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        controller.mapView = mapView
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        controller.mapView = mapView
        mapView.delegate = context.coordinator
        mapView.removeOverlays(mapView.overlays)
        
        var overlayIds: Set<String> = []
        var rectById: [String: MKMapRect] = [:]
        
        let polygons = territories.compactMap { territory -> MKPolygon? in
            guard !territory.boundary.isEmpty else { return nil }
            let coords = territory.boundary.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            let polygon = MKPolygon(coordinates: coords, count: coords.count)
            if let id = territory.id {
                polygon.title = id
                overlayIds.insert(id)
                rectById[id] = polygon.boundingMapRect
            }
            return polygon
        }
        
        mapView.addOverlays(polygons)
        
        // Add rects for territories without boundary so navigation still works
        for territory in territories {
            guard let id = territory.id else { continue }
            if rectById[id] == nil {
                let point = MKMapPoint(CLLocationCoordinate2D(latitude: territory.centerLatitude, longitude: territory.centerLongitude))
                let size: Double = 1000
                let rect = MKMapRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
                rectById[id] = rect
            }
        }
        
        controller.rectById = rectById
        
        let targetRect = rectById.values.reduce(MKMapRect.null) { partialResult, rect in
            partialResult.union(rect)
        }
        
        controller.unionRect = targetRect.isNull ? nil : targetRect
        
        // Fit to all territories only when overlays change, to not fight manual navigation
        if overlayIds != controller.lastOverlayIds {
            controller.lastOverlayIds = overlayIds
            controller.fitAll(animated: false)
        }
        
        if let focusId, focusId != controller.lastFocusedId {
            controller.focus(on: focusId, animated: true)
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let controller: TerritoryMapController
        
        init(controller: TerritoryMapController) {
            self.controller = controller
        }
        
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

final class TerritoryMapController: ObservableObject {
    fileprivate weak var mapView: MKMapView?
    fileprivate var rectById: [String: MKMapRect] = [:]
    fileprivate var lastOverlayIds: Set<String> = []
    fileprivate var unionRect: MKMapRect?
    fileprivate var lastFocusedId: String?
    
    func zoomIn() {
        zoom(factor: 0.65)
    }
    
    func zoomOut() {
        zoom(factor: 1.35)
    }
    
    private func zoom(factor: Double) {
        guard let mapView else { return }
        var rect = mapView.visibleMapRect
        let newWidth = rect.size.width * factor
        let newHeight = rect.size.height * factor
        rect.origin.x += (rect.size.width - newWidth) / 2
        rect.origin.y += (rect.size.height - newHeight) / 2
        rect.size.width = newWidth
        rect.size.height = newHeight
        mapView.setVisibleMapRect(rect, animated: true)
    }
    
    func focus(on territoryId: String, animated: Bool = true) {
        guard let mapView, let rect = rectById[territoryId], !rect.isNull else { return }
        lastFocusedId = territoryId
        mapView.setVisibleMapRect(
            rect,
            edgePadding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),
            animated: animated
        )
    }
    
    func fitAll(animated: Bool = true) {
        guard let mapView, let rect = unionRect, !rect.isNull else { return }
        mapView.setVisibleMapRect(
            rect,
            edgePadding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),
            animated: animated
        )
    }
}

struct TerritoriesOverviewMapContainer: View {
    let territories: [RemoteTerritory]
    @StateObject private var controller = TerritoryMapController()
    
    var body: some View {
        ZStack {
            TerritoriesOverviewMapView(territories: territories, controller: controller, focusId: nil)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 12) {
                Button {
                    controller.zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                        .frame(width: 46, height: 46)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                
                Button {
                    controller.zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                        .frame(width: 46, height: 46)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .onChange(of: territories) { _, newValue in
            guard !newValue.isEmpty else {
                return
            }
            controller.fitAll(animated: false)
        }
        .onAppear {
            controller.fitAll(animated: false)
        }
    }
}

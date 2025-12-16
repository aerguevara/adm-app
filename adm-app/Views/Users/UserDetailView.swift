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
    @State private var showingMasterWipeAlert = false
    @State private var showingFollowSheet = false
    @State private var followSearchText = ""
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserDetailViewModel(user: user))
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    InfoChip(text: "Lv \(viewModel.level)", systemImage: "star.fill", tint: .yellow)
                    InfoChip(text: "\(viewModel.xp) XP", systemImage: "bolt.fill", tint: .orange, filled: false)
                    if let lastUpdated = viewModel.lastUpdated {
                        InfoChip(text: lastUpdated.shortDate, systemImage: "clock.arrow.circlepath", tint: .blue, filled: false)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("Perfil") {
                HStack(spacing: 16) {
                    AvatarView(urlString: viewModel.avatarURL, size: 64)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.displayName.isEmpty ? "Sin nombre" : viewModel.displayName)
                            .font(.headline)
                        Text(viewModel.email.isEmpty ? "Sin email" : viewModel.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Avatar URL", text: $viewModel.avatarURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
            }
            
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
                
                HStack {
                    Text("Force Logout Version")
                    Spacer()
                    TextField("Version", value: $viewModel.forceLogoutVersion, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
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
            
            Section("Followers (\(viewModel.followers.count))") {
                if viewModel.isLoadingFollowers {
                    ProgressView("Loading followers...")
                } else if viewModel.followers.isEmpty {
                    ContentUnavailableView {
                        Label("No Followers", systemImage: "person.2")
                    } description: {
                        Text("Este usuario no tiene seguidores")
                    }
                } else {
                    ForEach(viewModel.followers) { follower in
                        FollowRow(follow: follower) {
                            Task {
                                await viewModel.removeFollower(followerId: follower.id)
                            }
                        }
                    }
                }
            }
            
            Section("Following (\(viewModel.following.count))") {
                if viewModel.isLoadingFollowing {
                    ProgressView("Loading following...")
                } else {
                    Button {
                        showingFollowSheet = true
                    } label: {
                        Label("Seguir usuario", systemImage: "person.badge.plus")
                    }
                    
                    if viewModel.following.isEmpty {
                        ContentUnavailableView {
                            Label("No Following", systemImage: "person.2.fill")
                        } description: {
                            Text("Este usuario no sigue a nadie")
                        }
                    } else {
                        ForEach(viewModel.following) { relation in
                            FollowRow(follow: relation) {
                                Task {
                                    await viewModel.unfollow(followedUserId: relation.id)
                                }
                            }
                        }
                    }
                }
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
                
                Button(role: .destructive) {
                    showingMasterWipeAlert = true
                } label: {
                    Label("Borrado maestro", systemImage: "exclamationmark.triangle.fill")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .disabled(viewModel.isMasterWiping)
            }
        }
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
        .alert("Borrado maestro", isPresented: $showingMasterWipeAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Borrar todo", role: .destructive) {
                Task {
                    await viewModel.masterWipeData()
                }
            }
        } message: {
            Text("Esto eliminará actividades (y sus subcolecciones), feed y remote_territories de este usuario. No se eliminará la cuenta. ¿Continuar?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadTerritories()
            await viewModel.loadFollowers()
            await viewModel.loadFollowing()
            await viewModel.loadAllUsers()
        }
        .sheet(isPresented: $showingFollowSheet) {
            FollowPickerView(
                searchText: $followSearchText,
                candidates: viewModel.availableFollowTargets,
                onSelect: { user in
                    Task {
                        await viewModel.follow(userToFollow: user)
                        await viewModel.loadFollowing()
                    }
                }
            )
        }
    }
}

struct FollowRow: View {
    let follow: FollowRelationship
    var action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: follow.avatarURL, size: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(follow.displayName.isEmpty ? "Sin nombre" : follow.displayName)
                    .font(.subheadline)
                if let date = follow.followedAt {
                    Text("Desde \(date.shortDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(role: .destructive) {
                action()
            } label: {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct FollowPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    let candidates: [User]
    let onSelect: (User) -> Void
    
    var filteredCandidates: [User] {
        guard !searchText.isEmpty else { return candidates }
        return candidates.filter { user in
            user.displayName.localizedCaseInsensitiveContains(searchText) ||
            (user.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (user.id ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredCandidates) { user in
                Button {
                    onSelect(user)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(urlString: user.avatarURL, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName)
                                .font(.body)
                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Seguir usuario")
            .searchable(text: $searchText, prompt: "Buscar por nombre o email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

struct AvatarView: View {
    let urlString: String?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(Color.gray.opacity(0.1))
        .clipShape(Circle())
    }
    
    private var url: URL? {
        guard let urlString, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(.white)
            )
    }
}

@MainActor
class UserDetailViewModel: ObservableObject {
    @Published var displayName: String
    @Published var email: String
    @Published var avatarURL: String
    @Published var level: Int
    @Published var xp: Int
    @Published var previousRank: Int
    @Published var joinedAt: Date
    @Published var lastUpdated: Date?
    @Published var forceLogoutVersion: Int?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var territories: [RemoteTerritory] = []
    @Published var isLoadingTerritories = false
    @Published var followers: [FollowRelationship] = []
    @Published var following: [FollowRelationship] = []
    @Published var isLoadingFollowers = false
    @Published var isLoadingFollowing = false
    @Published var allUsers: [User] = []
    @Published var isLoadingAllUsers = false
    @Published var isMasterWiping = false
    
    private let user: User
    private let firebaseManager = FirebaseManager.shared
    
    var isValid: Bool {
        !displayName.isEmpty && (email.isEmpty || email.isValidEmail)
    }
    
    init(user: User) {
        self.user = user
        self.displayName = user.displayName
        self.email = user.email ?? ""
        self.avatarURL = user.avatarURL ?? ""
        self.level = user.level
        self.xp = user.xp
        self.previousRank = user.previousRank ?? 0
        self.joinedAt = user.joinedAt
        self.lastUpdated = user.lastUpdated
        self.forceLogoutVersion = user.forceLogoutVersion
    }
    
    func saveUser() async {
        let updatedUser = User(
            id: user.id,
            displayName: displayName,
            email: email.isEmpty ? nil : email,
            avatarURL: avatarURL.isEmpty ? nil : avatarURL,
            joinedAt: joinedAt,
            lastUpdated: Date(), // Update timestamp
            level: level,
            xp: xp,
            previousRank: previousRank == 0 ? nil : previousRank,
            forceLogoutVersion: forceLogoutVersion
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
    
    func loadFollowers() async {
        guard let userId = user.id else { return }
        isLoadingFollowers = true
        do {
            followers = try await firebaseManager.fetchFollowers(for: userId)
            followers.sort { ($0.followedAt ?? .distantPast) > ($1.followedAt ?? .distantPast) }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingFollowers = false
    }
    
    func loadFollowing() async {
        guard let userId = user.id else { return }
        isLoadingFollowing = true
        do {
            following = try await firebaseManager.fetchFollowing(for: userId)
            following.sort { ($0.followedAt ?? .distantPast) > ($1.followedAt ?? .distantPast) }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingFollowing = false
    }
    
    func loadAllUsers() async {
        isLoadingAllUsers = true
        do {
            allUsers = try await firebaseManager.fetchUsers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoadingAllUsers = false
    }
    
    var availableFollowTargets: [User] {
        guard let currentId = user.id else { return [] }
        let followingIds = Set(following.compactMap { $0.id })
        return allUsers.filter { candidate in
            guard let id = candidate.id else { return false }
            if id == currentId { return false }
            return !followingIds.contains(id)
        }
    }
    
    func follow(userToFollow: User) async {
        guard user.id != nil else { return }
        do {
            let currentUserSnapshot = User(
                id: user.id,
                displayName: displayName,
                email: email.isEmpty ? nil : email,
                avatarURL: avatarURL.isEmpty ? nil : avatarURL,
                joinedAt: joinedAt,
                lastUpdated: lastUpdated,
                level: level,
                xp: xp,
                previousRank: previousRank == 0 ? nil : previousRank
            )
            try await firebaseManager.follow(user: currentUserSnapshot, targetUser: userToFollow)
            await loadFollowing()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func unfollow(followedUserId: String?) async {
        guard let currentId = user.id, let followedUserId else { return }
        do {
            try await firebaseManager.unfollow(userId: currentId, targetUserId: followedUserId)
            await loadFollowing()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func removeFollower(followerId: String?) async {
        guard let currentId = user.id, let followerId else { return }
        do {
            try await firebaseManager.removeFollower(userId: currentId, followerUserId: followerId)
            await loadFollowers()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func masterWipeData() async {
        guard let userId = user.id else { return }
        isMasterWiping = true
        defer { isMasterWiping = false }
        do {
            // Feed
            let feedItems = try await firebaseManager.fetchFeedItems(for: userId)
            for item in feedItems {
                if let id = item.id {
                    try await firebaseManager.deleteFeedItem(id: id)
                }
            }
            
            // Activities + subcollections
            let activities = try await firebaseManager.fetchActivities(filterUserId: userId)
            for activity in activities {
                if let id = activity.id {
                    try await firebaseManager.deleteActivityWithChildren(id: id)
                }
            }
            
            // Territories + subcollections
            let territories = try await firebaseManager.fetchTerritories(for: userId)
            for territory in territories {
                if let id = territory.id {
                    try await firebaseManager.deleteTerritoryWithChildren(id: id)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
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

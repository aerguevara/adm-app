//
//  ActivityDetailView.swift
//  adm-app
//
//  Created by Codex on 3/12/25.
//

import SwiftUI
import MapKit

struct ActivityDetailView: View {
    let activity: ActivitySession
    @State private var showRoutePoints = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                header
                mapSection
                metricsSection
                xpSection
                territorySection
                missionsSection
                routeSection
            }
            .padding()
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activity.activityType.capitalized)
                .font(.title2)
                .fontWeight(.semibold)
            Text("\(activity.startDate.mediumDate) • \(durationString)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("Ends: \(activity.endDate.mediumDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var mapSection: some View {
        Group {
            if !activity.route.isEmpty {
                ActivityMapView(route: activity.route)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metrics")
                .font(.headline)
            HStack {
                metricCard(title: "Distance", value: distanceString, systemImage: "figure.walk")
                metricCard(title: "Duration", value: durationString, systemImage: "clock")
                metricCard(title: "Avg Pace", value: paceString, systemImage: "speedometer")
            }
        }
    }
    
    private func metricCard(title: String, value: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var xpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("XP Breakdown")
                .font(.headline)
            VStack(alignment: .leading, spacing: 6) {
                xpRow(label: "Base", value: activity.xpBreakdown.xpBase)
                xpRow(label: "Territory", value: activity.xpBreakdown.xpTerritory)
                xpRow(label: "Streak", value: activity.xpBreakdown.xpStreak)
                xpRow(label: "Weekly Record", value: activity.xpBreakdown.xpWeeklyRecord)
                xpRow(label: "Badges", value: activity.xpBreakdown.xpBadges)
                Divider()
                xpRow(label: "Total", value: computedXP, bold: true)
                if activity.xpBreakdown.total != 0 && activity.xpBreakdown.total != computedXP {
                    Text("Total reportado: +\(activity.xpBreakdown.total) XP")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func xpRow(label: String, value: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("+\(value) XP")
                .fontWeight(bold ? .semibold : .regular)
        }
        .font(.subheadline)
    }
    
    private var computedXP: Int {
        activity.xpBreakdown.xpBase +
        activity.xpBreakdown.xpTerritory +
        activity.xpBreakdown.xpStreak +
        activity.xpBreakdown.xpWeeklyRecord +
        activity.xpBreakdown.xpBadges
    }
    
    private var territorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Territory Impact")
                .font(.headline)
            HStack(spacing: 12) {
                territoryStat("\(activity.territoryStats.newCellsCount)", "New")
                territoryStat("\(activity.territoryStats.defendedCellsCount)", "Defended")
                territoryStat("\(activity.territoryStats.recapturedCellsCount)", "Recaptured")
            }
        }
    }
    
    private func territoryStat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var missionsSection: some View {
        Group {
            if !activity.missions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Missions")
                        .font(.headline)
                    ForEach(activity.missions) { mission in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(mission.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(mission.rarity.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(mission.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    private var routeSection: some View {
        Group {
            if !activity.route.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Route Points (\(activity.route.count))")
                            .font(.headline)
                        Spacer()
                        Button(showRoutePoints ? "Hide" : "Show") {
                            withAnimation {
                                showRoutePoints.toggle()
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    if showRoutePoints {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(activity.route.enumerated()), id: \.offset) { index, point in
                                HStack {
                                    Text("#\(index + 1)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.5f, %.5f", point.latitude, point.longitude))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var distanceString: String {
        let km = activity.distanceMeters / 1000
        return String(format: "%.2f km", km)
    }
    
    private var durationString: String {
        let totalSeconds = Int(activity.durationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else {
            return String(format: "%dm %ds", minutes, seconds)
        }
    }
    
    private var paceString: String {
        guard activity.distanceMeters > 0 else { return "0:00 /km" }
        let paceSeconds = activity.durationSeconds / (activity.distanceMeters / 1000)
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

struct ActivityMapView: UIViewRepresentable {
    let route: [ActivityRoutePoint]
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
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
        mapView.delegate = context.coordinator
        mapView.removeOverlays(mapView.overlays)
        
        let coords = route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        if coords.count > 1 {
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(polyline)
            mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32), animated: false)
        } else if let first = coords.first {
            let region = MKCoordinateRegion(center: first, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: false)
        }
    }
    
    static func dismantleUIView(_ uiView: MKMapView, coordinator: Coordinator) {
        uiView.delegate = nil
        uiView.removeOverlays(uiView.overlays)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 3
            return renderer
        }
    }
}

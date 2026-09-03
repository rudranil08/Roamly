import SwiftUI
import SwiftData

struct HomeDashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var homes: [HomeEntity]
    @Query private var visits: [VisitEntity]
    
    private var primaryHome: HomeEntity? {
        homes.first
    }
    
    private var totalPoints: Int {
        visits.reduce(0) { $0 + $1.calculatedScore }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Current State Card
                    statusOverviewCard
                    
                    // 2. Active Trip / Destination Candidate Card
                    if appState.currentState != .atHome {
                        activeJourneyCard
                    }
                    
                    // 3. Lifetime Stats Summary
                    statsOverviewRow
                    
                    // 4. Base Geofence Summary Card
                    homeGeofenceCard
                    
                    // 5. State Machine Simulation Testing Controls (Phase 1 & 2 Testing)
                    simulationTestingCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.groupedBackground)
            .navigationTitle("Roamly Base")
        }
    }
    
    // MARK: - Subviews
    
    private var statusOverviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRAVEL DETECTION ENGINE")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    
                    Text(appState.currentState.displayTitle)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                StatusPill(
                    title: appState.currentState.rawValue,
                    icon: stateIcon(for: appState.currentState),
                    color: stateColor(for: appState.currentState)
                )
            }
            
            Text(appState.currentState.statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    private var activeJourneyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ACTIVE JOURNEY", systemImage: "figure.walk.motion")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.transitBlue)
                
                Spacer()
                
                Text("\(String(format: "%.1f", appState.currentTripDistanceKm)) km from base")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            
            if let candidate = appState.candidatePlaceName {
                HStack(spacing: 12) {
                    Image(systemName: appState.candidateCategory.systemIcon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.transitBlue)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate)
                            .font(.headline)
                        Text(appState.candidateCategory.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.transitBlue.opacity(0.2), lineWidth: 1.5)
        )
    }
    
    private var statsOverviewRow: some View {
        HStack(spacing: 12) {
            statItem(
                title: "Total Points",
                value: "\(totalPoints)",
                icon: "sparkles",
                tint: AppTheme.amberAccent
            )
            
            statItem(
                title: "Verified Visits",
                value: "\(visits.count)",
                icon: "checkmark.seal.fill",
                tint: AppTheme.baseGreen
            )
            
            statItem(
                title: "Journeys",
                value: "\(max(1, visits.count / 2))",
                icon: "map.fill",
                tint: AppTheme.transitBlue
            )
        }
    }
    
    private func statItem(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(tint)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private var homeGeofenceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("HOME BASE GEOFENCE", systemImage: "house.fill")
                    .font(.caption2.bold())
                    .foregroundColor(AppTheme.baseGreen)
                Spacer()
                
                if let home = primaryHome {
                    Text("\(Int(home.radiusMeters))m radius")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            if let home = primaryHome {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(home.name)
                            .font(.headline)
                        Text(String(format: "%.4f, %.4f", home.latitude, home.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    StatusPill(title: "Hardware Monitored", icon: "antenna.radiowaves.left.and.right", color: AppTheme.baseGreen)
                }
            } else {
                Text("No Home Base configured yet. Tap below to establish your base geofence.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var simulationTestingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("PHASE 1 STATE SIMULATOR", systemImage: "slider.horizontal.3")
                    .font(.caption2.bold())
                    .foregroundColor(.purple)
                Spacer()
                Text("Test Transitions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text("Cycle through the travel state machine to preview reactive state transitions:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button(action: {
                        appState.transitionTo(state: .leftHome)
                        appState.currentTripDistanceKm = 1.2
                    }) {
                        Text("1. Exit Base")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: {
                        appState.transitionTo(state: .traveling)
                        appState.currentTripDistanceKm = 5.8
                    }) {
                        Text("2. Travel 5km")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        appState.candidatePlaceName = "Palace of Fine Arts"
                        appState.candidateCategory = .worldHeritage
                        appState.candidateLatitude = 37.8029
                        appState.candidateLongitude = -122.4484
                        appState.transitionTo(state: .potentialVisit)
                    }) {
                        Text("3. Dwell At POI")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: {
                        appState.resetTrip()
                    }) {
                        Text("4. Return Home")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(AppTheme.baseGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func stateIcon(for state: TravelDetectionState) -> String {
        switch state {
        case .atHome: return "house.fill"
        case .leftHome: return "figure.walk"
        case .traveling: return "car.fill"
        case .potentialVisit: return "mappin.and.ellipse"
        case .awaitingConfirmation: return "camera.fill"
        case .photoCapture: return "camera.metering.matrix"
        case .validating: return "checkmark.shield.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .scoring: return "sparkles"
        }
    }
    
    private func stateColor(for state: TravelDetectionState) -> Color {
        switch state {
        case .atHome: return AppTheme.baseGreen
        case .leftHome: return AppTheme.amberAccent
        case .traveling: return AppTheme.transitBlue
        case .potentialVisit, .awaitingConfirmation: return .orange
        case .photoCapture, .validating: return .purple
        case .confirmed, .scoring: return AppTheme.baseGreen
        }
    }
}

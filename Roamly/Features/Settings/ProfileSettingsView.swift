import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var homes: [HomeEntity]
    @Query private var visits: [VisitEntity]
    
    @State private var isShowingHomeSetup: Bool = false
    @State private var showResetConfirmation: Bool = false
    
    private var baseHome: HomeEntity? {
        homes.first
    }
    
    private var totalPoints: Int {
        GamificationEngine.shared.calculateTotalPoints(from: visits)
    }
    
    private var currentLevel: GamificationLevel {
        GamificationEngine.shared.calculateLevel(from: totalPoints)
    }
    
    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(AppTheme.charcoal)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.parchmentSurface)
                        )
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentLevel.title)
                            .font(AppTypography.destinationTitle(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                        
                        Text("\(totalPoints.formatted()) Total Exploration Points")
                            .font(.system(.subheadline, design: .default))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                HStack {
                    Text("Base Name")
                        .font(.system(.body, design: .default))
                        .foregroundColor(AppTheme.charcoal)
                    Spacer()
                    Text(baseHome?.name ?? "Base Camp")
                        .font(.system(.callout, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                HStack {
                    Text("Geofence Radius")
                        .font(.system(.body, design: .default))
                        .foregroundColor(AppTheme.charcoal)
                    Spacer()
                    Text("\(Int(baseHome?.radiusMeters ?? 150)) meters")
                        .font(.system(.callout, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                Button(action: { isShowingHomeSetup = true }) {
                    HStack {
                        Text("Configure Base Camp Location")
                            .font(.system(.body, design: .default, weight: .medium))
                            .foregroundColor(AppTheme.terracotta)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                }
            } header: {
                Text("BASE CAMP")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            } footer: {
                Text("Your Base Camp coordinates are stored exclusively on your device to detect when you depart on spontaneous journeys.")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Section {
                Button(role: .destructive, action: { showResetConfirmation = true }) {
                    Text("Reset First-Time Onboarding")
                        .font(.system(.body, design: .default))
                }
            } header: {
                Text("DIAGNOSTICS")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            } footer: {
                Text("Allows you to experience the first-launch introduction and permission prompts again without removing saved journeys.")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.parchment)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingHomeSetup) {
            HomeSetupView()
        }
        .confirmationDialog(
            "Reset Onboarding?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Onboarding", role: .destructive) {
                UserSettingsService.shared.resetOnboarding()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will bring back the Welcome and Setup screens on your next launch.")
        }
    }
}

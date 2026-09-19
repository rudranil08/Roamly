import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabAnimationNamespace
    private var celebrationManager = AchievementCelebrationManager.shared
    
    var body: some View {
        @Bindable var state = appState
        
        ZStack(alignment: .bottom) {
            if !state.settings.hasCompletedOnboarding {
                OnboardingCoordinatorView()
            } else {
                // Active Screen Display
                Group {
                    switch state.selectedTab {
                    case 0:
                        HomeDashboardView()
                    case 1:
                        ExploreMapView()
                    case 2:
                        LogbookView()
                    case 3:
                        LeaderboardView()
                    default:
                        HomeDashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Minimal Editorial Bottom Navigation Dock
                bottomNavigationDock(selectedTab: $state.selectedTab)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 2)
            }
            
            // Centralized Reusable Achievement & Badge Celebration Modal
            if let badge = celebrationManager.currentCelebration {
                AchievementCelebrationOverlay(
                    badge: badge,
                    onDismiss: {
                        celebrationManager.dismissCurrent()
                    }
                )
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(999)
            }
        }
        .preferredColorScheme(appState.settings.appearance.colorScheme)
        .animation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.3, dampingFraction: 0.82), value: appState.selectedTab)
        .animation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.35, dampingFraction: 0.85), value: celebrationManager.currentCelebration != nil)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await SyncEngine.shared.processQueue(modelContext: modelContext)
                }
            }
        }
    }
    
    // MARK: - Minimal Bottom Navigation Dock
    
    private func bottomNavigationDock(selectedTab: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            navItem(
                tag: 0,
                title: "Home",
                systemIcon: "safari",
                selectedIcon: "safari.fill",
                selectedTab: selectedTab
            )
            
            navItem(
                tag: 1,
                title: "Explore",
                systemIcon: "map",
                selectedIcon: "map.fill",
                selectedTab: selectedTab
            )
            
            navItem(
                tag: 2,
                title: "Trips",
                systemIcon: "clock.arrow.circlepath",
                selectedIcon: "clock.arrow.circlepath",
                selectedTab: selectedTab
            )
            
            navItem(
                tag: 3,
                title: "You",
                systemIcon: "person",
                selectedIcon: "person.fill",
                selectedTab: selectedTab
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.parchmentSurface.opacity(0.92))
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 4)
        .frame(maxWidth: 380)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main Navigation Dock")
    }
    
    private func navItem(tag: Int, title: String, systemIcon: String, selectedIcon: String, selectedTab: Binding<Int>) -> some View {
        let isSelected = selectedTab.wrappedValue == tag
        
        return Button(action: {
            if selectedTab.wrappedValue != tag {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if reduceMotion {
                    selectedTab.wrappedValue = tag
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        selectedTab.wrappedValue = tag
                    }
                }
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? selectedIcon : systemIcon)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.charcoal : AppTheme.mutedWarmGray)
                    .frame(height: 22)
                
                Text(title)
                    .font(.system(.caption2, design: .default, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.charcoal : AppTheme.mutedWarmGray)
                    .lineLimit(1)
                
                // Subtle terracotta accent dot for active state
                Circle()
                    .fill(isSelected ? AppTheme.terracotta : Color.clear)
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1.0 : 0.0)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityHint("Switches to the \(title) tab")
    }
}

#Preview {
    ContentView()
        .environment(AppState.shared)
        .modelContainer(DataContainer.preview)
}

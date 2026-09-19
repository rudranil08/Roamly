import SwiftUI
import SwiftData
import CoreLocation
import UserNotifications

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var homes: [HomeEntity]
    
    @State private var settings = UserSettingsService.shared
    @State private var isShowingCurrencyPicker: Bool = false
    @State private var isShowingCloudSync: Bool = false
    
    private var currentCurrency: CurrencyOption {
        settings.currentCurrency
    }
    
    var body: some View {
        NavigationStack {
            List {
                // ACCOUNT
                Section {
                    NavigationLink(destination: ProfileSettingsView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "person")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Profile")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                            
                            Spacer()
                            
                            if let home = homes.first {
                                Text(home.name)
                                    .font(.system(.callout, design: .default))
                                    .foregroundColor(AppTheme.mutedWarmGray)
                            }
                        }
                    }
                    .accessibilityLabel("Profile, Base Camp settings and traveler record")
                } header: {
                    Text("ACCOUNT")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // APP
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Appearance")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                            
                            Spacer()
                            
                            Text(settings.appearance.rawValue)
                                .font(.system(.callout, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                    }
                    .accessibilityLabel("Appearance, currently set to \(settings.appearance.rawValue)")
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Notifications")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                        }
                    }
                    .accessibilityLabel("Notifications, departure and milestone prompts")
                    
                    Button(action: { isShowingCurrencyPicker = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "banknote")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Currency")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                            
                            Spacer()
                            
                            Text("\(currentCurrency.code) (\(currentCurrency.symbol))")
                                .font(.system(.callout, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.mutedWarmGray)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Currency, currently \(currentCurrency.name), \(currentCurrency.code)")
                    .accessibilityHint("Double tap to choose spending currency")
                    
                    Button(action: { isShowingCloudSync = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "cloud")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Cloud Journal Sync")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                            
                            Spacer()
                            
                            if SyncEngine.shared.pendingSyncCount > 0 {
                                Text("\(SyncEngine.shared.pendingSyncCount) pending")
                                    .font(.system(.caption, design: .default, weight: .semibold))
                                    .foregroundColor(AppTheme.terracotta)
                            } else {
                                Text("Synchronized")
                                    .font(.system(.callout, design: .default))
                                    .foregroundColor(AppTheme.sageOlive)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.mutedWarmGray)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cloud Journal Sync, PostGIS cloud synchronization")
                } header: {
                    Text("APP")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // ACCESSIBILITY
                Section {
                    NavigationLink(destination: AccessibilitySettingsView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "accessibility")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("Accessibility")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                        }
                    }
                    .accessibilityLabel("Accessibility, Dynamic Type, Reduce Motion, and VoiceOver")
                } header: {
                    Text("ACCESSIBILITY")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                // ABOUT
                Section {
                    NavigationLink(destination: AboutRoamlyView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.charcoal)
                                .frame(width: 24)
                                .accessibilityHidden(true)
                            
                            Text("About Roamly")
                                .font(.system(.body, design: .default))
                                .foregroundColor(AppTheme.charcoal)
                            
                            Spacer()
                            
                            Text("v1.0")
                                .font(.system(.callout, design: .default))
                                .foregroundColor(AppTheme.mutedWarmGray)
                        }
                    }
                    .accessibilityLabel("About Roamly, version, architecture, and design principles")
                } header: {
                    Text("ABOUT")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.parchment)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .default, weight: .semibold))
                    .foregroundColor(AppTheme.terracotta)
                    .accessibilityLabel("Done, close settings")
                }
            }
            .sheet(isPresented: $isShowingCurrencyPicker) {
                CurrencyPickerView()
            }
            .sheet(isPresented: $isShowingCloudSync) {
                CloudSyncSettingsView()
            }
        }
    }
}

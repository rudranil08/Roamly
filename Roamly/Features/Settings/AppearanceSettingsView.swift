import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var settings = UserSettingsService.shared
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Appearance")
                        .font(AppTypography.destinationTitle(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                    Text("Choose how Roamly looks on your device.")
                        .font(AppTypography.editorialSubhead(size: 14))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                
                ForEach(AppAppearance.allCases) { option in
                    Button(action: {
                        selectAppearance(option)
                    }) {
                        HStack(spacing: 14) {
                            // Radio indicator
                            ZStack {
                                Circle()
                                    .stroke(isSelected(option) ? AppTheme.terracotta : AppTheme.subtleBorder, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                
                                if isSelected(option) {
                                    Circle()
                                        .fill(AppTheme.terracotta)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.rawValue)
                                    .font(.system(.body, design: .default, weight: .medium))
                                    .foregroundColor(AppTheme.charcoal)
                                
                                Text(subtitle(for: option))
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(AppTheme.mutedWarmGray)
                            }
                            
                            Spacer()
                            
                            // Visual appearance icon preview
                            appearanceIcon(for: option)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(option.rawValue), \(subtitle(for: option))")
                    .accessibilityAddTraits(isSelected(option) ? [.isButton, .isSelected] : [.isButton])
                    .accessibilityHint("Double tap to set appearance to \(option.rawValue)")
                }
            } footer: {
                Text("When System is selected, Roamly seamlessly transitions between warm parchment and deep charcoal as iOS changes appearance.")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
                    .padding(.top, 6)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.parchment)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helpers
    
    private func isSelected(_ option: AppAppearance) -> Bool {
        settings.appearance == option
    }
    
    private func selectAppearance(_ option: AppAppearance) {
        guard settings.appearance != option else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.easeInOut(duration: 0.25)) {
            settings.updateAppearance(to: option)
        }
    }
    
    private func subtitle(for option: AppAppearance) -> String {
        switch option {
        case .system:
            return "Follows your iPhone's appearance automatically."
        case .light:
            return "Warm off-white parchment aesthetic."
        case .dark:
            return "Deep charcoal and subdued night tones."
        }
    }
    
    @ViewBuilder
    private func appearanceIcon(for option: AppAppearance) -> some View {
        switch option {
        case .system:
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.mutedWarmGray)
        case .light:
            Image(systemName: "sun.max")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.mutedWarmGray)
        case .dark:
            Image(systemName: "moon")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.mutedWarmGray)
        }
    }
}

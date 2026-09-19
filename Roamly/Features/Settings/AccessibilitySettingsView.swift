import SwiftUI

struct AccessibilitySettingsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var settings = UserSettingsService.shared
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility")
                        .font(AppTypography.destinationTitle(size: 20, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                    Text("Roamly natively adapts to your iOS system preferences.")
                        .font(AppTypography.editorialSubhead(size: 14))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
            }
            
            Section {
                statusRow(
                    title: "Dynamic Type",
                    value: dynamicTypeDescription,
                    icon: "textformat.size"
                )
                
                statusRow(
                    title: "Reduce Motion",
                    value: reduceMotion ? "Enabled (Subtle transitions active)" : "System Default",
                    icon: "figure.walk.motion"
                )
                
                statusRow(
                    title: "VoiceOver",
                    value: voiceOverEnabled ? "Active" : "Off",
                    icon: "speaker.wave.2"
                )
            } header: {
                Text("SYSTEM PREFERENCES")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            } footer: {
                Text("Roamly automatically scales editorial typography with Dynamic Type and replaces celebratory animations with quiet transitions when Reduce Motion is turned on.")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Section {
                Button(action: openSystemAccessibilitySettings) {
                    HStack {
                        Text("Open iOS Accessibility Settings")
                            .font(.system(.body, design: .default))
                            .foregroundColor(AppTheme.charcoal)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityHint("Opens Apple Settings to customize VoiceOver, Text Size, and Motion")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.parchment)
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private func statusRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.charcoal)
                .frame(width: 24)
                .accessibilityHidden(true)
            
            Text(title)
                .font(.system(.body, design: .default))
                .foregroundColor(AppTheme.charcoal)
            
            Spacer()
            
            Text(value)
                .font(.system(.callout, design: .default))
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
    
    private var dynamicTypeDescription: String {
        if dynamicTypeSize.isAccessibilitySize {
            return "Accessibility Size"
        }
        return "Standard (\(dynamicTypeSize))"
    }
    
    private func openSystemAccessibilitySettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

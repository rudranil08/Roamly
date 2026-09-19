import SwiftUI

struct AboutRoamlyView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "safari")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(AppTheme.charcoal)
                    
                    Text("Roamly")
                        .font(AppTypography.editorialTitle(size: 28, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                    
                    Text("Version 1.0 (iOS 27)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text("A calm, photographic, spatial travel companion designed to record your spontaneous journeys with privacy and restraint.")
                        .font(AppTypography.editorialSubhead(size: 14))
                        .foregroundColor(AppTheme.mutedWarmGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
            }
            
            Section {
                infoRow(title: "Architecture", value: "SwiftData & PostGIS")
                infoRow(title: "Privacy Model", value: "100% On-Device Geofences")
                infoRow(title: "Spatial Framework", value: "MapKit Standard Elevation")
                infoRow(title: "Anti-Tamper", value: "Perceptual dHash Verification")
            } header: {
                Text("INTEGRITY & DESIGN")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Section {
                Text("Designed with Apple Design Award principles of clarity, restraint, strong hierarchy, and purposeful spatial typography.")
                    .font(.system(.footnote, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
                    .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.parchment)
        .navigationTitle("About Roamly")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .default))
                .foregroundColor(AppTheme.charcoal)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .default))
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

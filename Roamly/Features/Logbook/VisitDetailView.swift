import SwiftUI
import MapKit

struct VisitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let visit: VisitEntity
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: visit.latitude, longitude: visit.longitude)
    }
    
    private var proofImage: UIImage {
        if let img = PhotoStorageService.loadPhoto(for: visit.id, path: visit.localPhotoPath) {
            return img
        }
        return PhotoStorageService.generateProofPlaceholder(
            placeName: visit.placeName,
            category: visit.category,
            latitude: visit.latitude,
            longitude: visit.longitude,
            date: visit.capturedAt,
            hashPrefix: String(visit.photoHash.prefix(12))
        )
    }
    
    private var scoringBreakdown: ScoringBreakdown {
        ScoringEngine.shared.calculateScore(
            travelMode: visit.travelMode,
            category: visit.category,
            distanceKm: visit.distanceKm,
            lifetimeVisits: 0,
            fraudConfidence: visit.isVerified ? 1.0 : 0.5
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // 1. Photographic Proof & Map Spotlight
                    heroVisualSection
                    
                    // 2. Destination Title & Status Badges
                    headerTitleSection
                    
                    // 3. Open Journey Metrics Strip
                    journeyMetricsStrip
                    
                    // 4. Scoring Engine Audit Breakdown
                    scoringAuditSection
                    
                    // 5. Commercial Spend Entry (If logged)
                    if visit.spendingAmount > 0 {
                        spendingSection
                    }
                    
                    // 6. Security Telemetry & Cryptographic Verification Certificate
                    securityTelemetrySection
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.parchment)
            .navigationTitle("Expedition Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    ShareLink(
                        item: "I explored \(visit.placeName) with Roamly! Travel mode: \(visit.travelMode.displayName) • +\(visit.calculatedScore) pts earned.",
                        subject: Text("Roamly Journey: \(visit.placeName)")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AppTheme.charcoal)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.terracotta)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var heroVisualSection: some View {
        VStack(spacing: 12) {
            // Photo Proof
            Image(uiImage: proofImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.subtleBorder, lineWidth: 1)
                )
            
            // Map Location
            Map {
                Marker(visit.placeName, coordinate: coordinate)
                    .tint(AppTheme.terracotta)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
        }
    }
    
    private var headerTitleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(visit.placeName)
                        .font(AppTypography.destinationTitle(size: 24, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                    Text(visit.capturedAt.formatted(date: .complete, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                Spacer()
                
                ScoreBadgeView(score: visit.calculatedScore)
            }
            
            HStack(spacing: 8) {
                StatusPill(
                    title: visit.category.displayName,
                    icon: visit.category.systemIcon,
                    color: AppTheme.charcoal
                )
                
                StatusPill(
                    title: visit.isVerified ? "Sensor Verified" : "Review Flag",
                    icon: visit.isVerified ? "checkmark.seal" : "exclamationmark.triangle",
                    color: visit.isVerified ? AppTheme.sageOlive : AppTheme.terracotta
                )
            }
        }
    }
    
    private var journeyMetricsStrip: some View {
        HStack(spacing: 0) {
            metricItem(
                title: "Mode",
                value: visit.travelMode.displayName,
                icon: visit.travelMode.systemIcon
            )
            
            Divider()
                .frame(height: 28)
                .background(AppTheme.subtleBorder)
            
            metricItem(
                title: "Distance",
                value: String(format: "%.1f km", visit.distanceKm),
                icon: "location"
            )
            
            Divider()
                .frame(height: 28)
                .background(AppTheme.subtleBorder)
            
            metricItem(
                title: "Multiplier",
                value: String(format: "%.1fx", visit.travelMode.sustainabilityMultiplier),
                icon: "leaf"
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private func metricItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.charcoal)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.charcoal)
            }
            Text(title.uppercased())
                .font(AppTypography.uiTag(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var scoringAuditSection: some View {
        let score = scoringBreakdown
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("EXPEDITION SCORING AUDIT")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.mutedWarmGray)
                Spacer()
                Text("+\(visit.calculatedScore) pts")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(AppTheme.charcoal)
            }
            
            VStack(spacing: 6) {
                auditRow(label: "Base Points", value: "+\(score.basePoints)")
                auditRow(label: "Category Multiplier", value: String(format: "%.1fx", score.categoryMultiplier))
                auditRow(label: "Distance Bonus", value: "+\(score.distancePoints)")
                auditRow(label: "Sustainability Multiplier", value: String(format: "%.1fx", score.sustainabilityMultiplier))
            }
        }
        .padding(14)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private func auditRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.mutedWarmGray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.charcoal)
        }
    }
    
    private var spendingSection: some View {
        HStack {
            Image(systemName: "banknote")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.charcoal)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Local Commercial Support")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                Text("Logged in \(visit.spendingCurrency)")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Spacer()
            
            Text(CurrencyService.format(amount: visit.spendingAmount, currencyCode: visit.spendingCurrency))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.charcoal)
        }
        .padding(14)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var securityTelemetrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUTHENTICITY TELEMETRY")
                .font(AppTypography.uiTag(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundColor(AppTheme.mutedWarmGray)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Perceptual Hash (dHash)")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    Spacer()
                    Text(visit.photoHash.isEmpty ? "Synthetic Pass" : String(visit.photoHash.prefix(16)) + "...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(AppTheme.charcoal)
                }
                
                HStack {
                    Text("Cloud Sync Status")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    Spacer()
                    Text(visit.isSynced ? "PostGIS Synced" : "Pending Outbox")
                        .font(.system(size: 11))
                        .foregroundColor(visit.isSynced ? AppTheme.sageOlive : AppTheme.terracotta)
                }
            }
        }
        .padding(14)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
}

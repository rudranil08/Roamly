import SwiftUI
import SwiftData
import CoreLocation

struct VisitConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var existingVisits: [VisitEntity]
    
    let capturedImage: UIImage?
    var onVisitSaved: (() -> Void)? = nil
    
    @State private var placeName: String = ""
    @State private var selectedCategory: DestinationCategory = .foodMarket
    @State private var selectedTravelMode: TravelMode = .walking
    @State private var spendingText: String = ""
    @State private var spendingCurrency: String = "USD"
    @State private var isSubmitting: Bool = false
    @State private var antiCheatAlert: String? = nil
    
    private var distanceKm: Double {
        max(0.5, appState.currentTripDistanceKm)
    }
    
    private var priorVisitCount: Int {
        existingVisits.filter { $0.placeName.localizedCaseInsensitiveCompare(placeName) == .orderedSame }.count
    }
    
    private var fraudConfidence: Double {
        appState.pendingAntiCheatResult?.fraudConfidence ?? 1.0
    }
    
    private var currentScoreBreakdown: ScoringBreakdown {
        ScoringEngine.shared.calculateScore(
            travelMode: selectedTravelMode,
            category: selectedCategory,
            distanceKm: distanceKm,
            lifetimeVisits: priorVisitCount,
            fraudConfidence: fraudConfidence
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Photographic Proof & Telemetry Card
                    photoProofHeader
                    
                    // Destination Name & Category
                    destinationInfoSection
                    
                    // Mode of Travel Selection
                    travelModeSection
                    
                    // Local Spend Entry
                    spendingSection
                    
                    // Real-time Score Engine Breakdown
                    scoreCalculationCard
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.parchment)
            .navigationTitle("Record Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { dismiss() }
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
            .safeAreaInset(edge: .bottom) {
                commitButton
            }
            .onAppear(perform: initializeFields)
            .alert("Verification Notice", isPresented: Binding(
                get: { antiCheatAlert != nil },
                set: { if !$0 { antiCheatAlert = nil } }
            )) {
                Button("OK") {}
            } message: {
                Text(antiCheatAlert ?? "")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var photoProofHeader: some View {
        HStack(spacing: 16) {
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.parchment)
                    .frame(width: 84, height: 84)
                    .overlay(
                        Image(systemName: "camera")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppTheme.mutedWarmGray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                StatusPill(
                    title: fraudConfidence >= 0.85 ? "Sensor Verified" : "Review Flag",
                    icon: fraudConfidence >= 0.85 ? "checkmark.seal" : "exclamationmark.triangle",
                    color: fraudConfidence >= 0.85 ? AppTheme.sageOlive : AppTheme.terracotta
                )
                
                Text(String(format: "%.1f km from Base", distanceKm))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.charcoal)
                
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            Spacer()
        }
        .padding(14)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var destinationInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DESTINATION")
                .font(AppTypography.uiTag(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundColor(AppTheme.mutedWarmGray)
            
            TextField("Destination Name", text: $placeName)
                .font(AppTypography.destinationTitle(size: 18, weight: .medium))
                .foregroundColor(AppTheme.charcoal)
                .roamlyInputStyle()
            
            // Nearby candidate POIs discovered by MapKit
            if appState.nearbyCandidates.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(appState.nearbyCandidates) { candidate in
                            Button(action: {
                                placeName = candidate.name
                                selectedCategory = candidate.category
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: candidate.category.systemIcon)
                                        .font(.system(size: 10))
                                    Text(candidate.name)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(placeName == candidate.name ? AppTheme.charcoal : AppTheme.parchment)
                                .foregroundColor(placeName == candidate.name ? .white : AppTheme.charcoal)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.subtleBorder, lineWidth: placeName == candidate.name ? 0 : 1)
                                )
                            }
                        }
                    }
                }
            }
            
            // Category Selector Menu
            Menu {
                ForEach(DestinationCategory.allCases) { cat in
                    Button(action: { selectedCategory = cat }) {
                        Label(
                            "\(cat.displayName) (\(String(format: "%.1fx", cat.significanceMultiplier)))",
                            systemImage: cat.systemIcon
                        )
                    }
                }
            } label: {
                HStack {
                    Label(selectedCategory.displayName, systemImage: selectedCategory.systemIcon)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.charcoal)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                .roamlyInputStyle()
            }
        }
        .padding(16)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var travelModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MODE OF TRAVEL")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.mutedWarmGray)
                Spacer()
                Text("\(String(format: "%.1fx", selectedTravelMode.sustainabilityMultiplier)) Sustainability")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([TravelMode.walking, .cycling, .train, .bus, .carpool, .privateCar]) { mode in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                selectedTravelMode = mode
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mode.systemIcon)
                                    .font(.system(size: 18))
                                Text(mode.displayName)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .frame(width: 76, height: 68)
                            .background(selectedTravelMode == mode ? AppTheme.charcoal : AppTheme.parchment)
                            .foregroundColor(selectedTravelMode == mode ? .white : AppTheme.charcoal)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppTheme.subtleBorder, lineWidth: selectedTravelMode == mode ? 0 : 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMMERCE & SPENDING (OPTIONAL)")
                .font(AppTypography.uiTag(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundColor(AppTheme.mutedWarmGray)
            
            HStack(spacing: 8) {
                TextField("Amount (e.g. 14.50)", text: $spendingText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14))
                    .roamlyInputStyle()
                
                Menu {
                    ForEach(CurrencyOption.supportedCurrencies) { curr in
                        Button("\(curr.code) (\(curr.symbol))") {
                            spendingCurrency = curr.code
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(spendingCurrency)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(AppTheme.charcoal)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(AppTheme.parchment)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.inputCornerRadius, style: .continuous)
                            .stroke(AppTheme.subtleBorder, lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private var scoreCalculationCard: some View {
        let breakdown = currentScoreBreakdown
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ESTIMATED EXPEDITION POINTS")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(AppTheme.mutedWarmGray)
                Spacer()
                Text("+\(breakdown.finalScore)")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(AppTheme.charcoal)
            }
            
            VStack(spacing: 6) {
                breakdownLine(title: "Base Points", value: "+\(breakdown.basePoints)")
                breakdownLine(title: "Category (\(selectedCategory.displayName))", value: "\(String(format: "%.1fx", breakdown.categoryMultiplier))")
                breakdownLine(title: "Distance (\(String(format: "%.1f km", distanceKm)))", value: "+\(breakdown.distancePoints)")
                breakdownLine(title: "Sustainability (\(selectedTravelMode.displayName))", value: "\(String(format: "%.1fx", breakdown.sustainabilityMultiplier))")
            }
        }
        .padding(16)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private func breakdownLine(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.mutedWarmGray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.charcoal)
        }
    }
    
    private var commitButton: some View {
        Button(action: saveVisitRecord) {
            if isSubmitting {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Confirm & Record Journey")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .buttonStyle(RoamlyPrimaryButtonStyle(height: 50, backgroundColor: AppTheme.terracotta))
        .disabled(placeName.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.parchmentSurface.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(AppTheme.subtleBorder),
            alignment: .top
        )
    }
    
    // MARK: - Actions
    
    private func initializeFields() {
        placeName = appState.candidatePlaceName ?? "San Francisco Destination"
        selectedCategory = appState.candidateCategory
        selectedTravelMode = appState.pendingTravelMode
        spendingCurrency = UserSettingsService.shared.currencyCode
    }
    
    private func saveVisitRecord() {
        isSubmitting = true
        
        let spend = Double(spendingText.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let finalBreakdown = currentScoreBreakdown
        
        var photoPath: String? = nil
        var photoHashString: String = ""
        
        if let image = capturedImage {
            let photoId = UUID()
            photoPath = PhotoStorageService.savePhoto(image: image, for: photoId)
            photoHashString = PerceptualHashEngine.computeDHash(image: image)
        }
        
        let visitId = UUID()
        let visitEntity = VisitEntity(
            id: visitId,
            placeName: placeName.trimmingCharacters(in: .whitespaces),
            categoryRaw: selectedCategory.rawValue,
            latitude: appState.candidateLatitude,
            longitude: appState.candidateLongitude,
            capturedAt: Date(),
            travelModeRaw: selectedTravelMode.rawValue,
            spendingAmount: spend,
            spendingCurrency: spendingCurrency,
            localPhotoPath: photoPath,
            photoHash: photoHashString,
            calculatedScore: finalBreakdown.finalScore,
            distanceKm: distanceKm,
            isVerified: fraudConfidence >= 0.85,
            isSynced: false
        )
        
        modelContext.insert(visitEntity)
        try? modelContext.save()
        
        // Enqueue cloud sync
        SyncEngine.shared.enqueue(visit: visitEntity, in: modelContext)
        
        // Evaluate gamification celebrations
        let descriptor = FetchDescriptor<VisitEntity>()
        if let allVisits = try? modelContext.fetch(descriptor) {
            AchievementCelebrationManager.shared.evaluateAndCelebrate(visits: allVisits)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        appState.resetTrip()
        
        isSubmitting = false
        onVisitSaved?()
        dismiss()
    }
}

import SwiftUI
import SwiftData

struct LogbookView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \VisitEntity.capturedAt, order: .reverse) private var visits: [VisitEntity]
    
    @State private var selectedFilter: String = "ALL"
    @State private var searchText: String = ""
    @State private var selectedVisit: VisitEntity? = nil
    @State private var selectedSort: SortOption = .newest
    
    private let filterOptions = ["ALL", "Parks & Nature", "Heritage", "Low Impact", "Local Spend"]
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case highestScore = "Highest Score"
        case longestDistance = "Longest Distance"
        var id: String { rawValue }
    }
    
    private var totalPoints: Int {
        visits.reduce(0) { $0 + $1.calculatedScore }
    }
    
    private var totalDistanceKm: Double {
        visits.reduce(0.0) { $0 + $1.distanceKm }
    }
    
    private var streakStats: (current: Int, longest: Int) {
        GamificationEngine.shared.calculateStreak(from: visits)
    }
    
    private var filteredAndSortedVisits: [VisitEntity] {
        let filtered = visits.filter { visit in
            if !searchText.isEmpty {
                let matchesName = visit.placeName.localizedCaseInsensitiveContains(searchText)
                let matchesCat = visit.category.displayName.localizedCaseInsensitiveContains(searchText)
                if !matchesName && !matchesCat { return false }
            }
            
            switch selectedFilter {
            case "Parks & Nature":
                return visit.category == .nationalPark || visit.category == .publicPark || visit.category == .botanicalGarden
            case "Heritage":
                return visit.category == .worldHeritage || visit.category == .museum
            case "Low Impact":
                return visit.travelMode == .walking || visit.travelMode == .cycling || visit.travelMode == .running
            case "Local Spend":
                return visit.spendingAmount > 0
            default:
                return true
            }
        }
        
        return filtered.sorted { a, b in
            switch selectedSort {
            case .newest:
                return a.capturedAt > b.capturedAt
            case .oldest:
                return a.capturedAt < b.capturedAt
            case .highestScore:
                return a.calculatedScore > b.calculatedScore
            case .longestDistance:
                return a.distanceKm > b.distanceKm
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Editorial Header Stats Strip (Lightweight, unboxed)
                if !visits.isEmpty {
                    editorialStatsStrip
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, 12)
                }
                
                // Minimal Category Filter Capsules & Sort Picker
                if !visits.isEmpty {
                    filterAndSortBar
                        .padding(.bottom, 10)
                }
                
                // Lightweight Editorial Timeline (Avoids heavy boxes around every item)
                if filteredAndSortedVisits.isEmpty {
                    if visits.isEmpty {
                        emptyStateView
                    } else {
                        noFilterMatchesView
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(filteredAndSortedVisits.enumerated()), id: \.element.id) { index, visit in
                                editorialTimelineRow(
                                    visit,
                                    isFirst: index == 0,
                                    isLast: index == filteredAndSortedVisits.count - 1
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedVisit = visit
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 80) // Space for bottom navigation dock
                    }
                }
            }
            .background(AppTheme.parchment)
            .navigationTitle("Travel Journal")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search destinations, places...")
            .sheet(item: $selectedVisit) { visit in
                VisitDetailView(visit: visit)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var editorialStatsStrip: some View {
        HStack(spacing: 0) {
            statItem(value: "\(visits.count)", label: "Places")
            Divider().frame(height: 24).background(AppTheme.subtleBorder)
            statItem(value: String(format: "%.1f km", totalDistanceKm), label: "Traversed")
            Divider().frame(height: 24).background(AppTheme.subtleBorder)
            statItem(value: "\(streakStats.current) days", label: "Streak")
            Divider().frame(height: 24).background(AppTheme.subtleBorder)
            statItem(value: "\(totalPoints)", label: "Points")
        }
        .padding(.vertical, 10)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(AppTheme.charcoal)
            Text(label.uppercased())
                .font(AppTypography.uiTag(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundColor(AppTheme.mutedWarmGray)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
    
    private var filterAndSortBar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Button(action: {
                            if reduceMotion {
                                selectedFilter = filter
                            } else {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedFilter = filter
                                }
                            }
                        }) {
                            Text(filter)
                                .font(.system(.footnote, design: .default, weight: selectedFilter == filter ? .semibold : .regular))
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(selectedFilter == filter ? AppTheme.charcoal : AppTheme.parchmentSurface)
                                .foregroundColor(selectedFilter == filter ? AppTheme.parchmentSurface : AppTheme.charcoal)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(AppTheme.subtleBorder, lineWidth: selectedFilter == filter ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Filter: \(filter)")
                        .accessibilityAddTraits(selectedFilter == filter ? [.isButton, .isSelected] : [.isButton])
                    }
                }
                .padding(.leading, 20)
            }
            
            Menu {
                Picker("Sort", selection: $selectedSort) {
                    ForEach(SortOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.parchmentSurface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.subtleBorder, lineWidth: 1))
                    .padding(.trailing, 20)
            }
            .accessibilityLabel("Sort journeys, currently \(selectedSort.rawValue)")
            .accessibilityHint("Double tap to choose journey sorting order")
        }
    }
    
    // MARK: - Lightweight Editorial Timeline Row (No heavy boxes!)
    
    private func editorialTimelineRow(_ visit: VisitEntity, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timestamp column
            VStack(alignment: .trailing, spacing: 2) {
                Text(visit.capturedAt.formatted(.dateTime.hour().minute()))
                    .font(.system(.caption, design: .monospaced, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                Text(visit.capturedAt.formatted(.dateTime.month().day()))
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            .frame(width: 48, alignment: .trailing)
            
            // Continuous fine thread line with terracotta pin
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : AppTheme.subtleBorder)
                    .frame(width: 1.5, height: 12)
                
                Circle()
                    .fill(AppTheme.terracotta)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(AppTheme.parchment, lineWidth: 2))
                
                Rectangle()
                    .fill(isLast ? Color.clear : AppTheme.subtleBorder)
                    .frame(width: 1.5)
            }
            .accessibilityHidden(true)
            
            // Content Column (Unboxed, airy, graceful)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(visit.placeName)
                        .font(AppTypography.destinationTitle(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    Text("+\(visit.calculatedScore)")
                        .font(.system(.footnote, design: .monospaced, weight: .semibold))
                        .foregroundColor(AppTheme.terracotta)
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: visit.travelMode.systemIcon)
                            .font(.system(size: 11))
                        Text(visit.travelMode.displayName)
                            .font(.system(.caption, design: .default))
                    }
                    .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text("·")
                        .font(.caption2)
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text(String(format: "%.1f km", visit.distanceKm))
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    if visit.spendingAmount > 0 {
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(AppTheme.mutedWarmGray)
                        
                        Text(formatCurrency(amount: visit.spendingAmount, code: visit.spendingCurrency))
                            .font(.system(.caption, design: .default, weight: .medium))
                            .foregroundColor(AppTheme.charcoal)
                    }
                }
                
                Divider()
                    .background(AppTheme.subtleBorder)
                    .padding(.top, 10)
            }
            .padding(.bottom, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(visit.placeName), \(visit.category.displayName), \(visit.travelMode.displayName), \(visit.capturedAt.formatted(date: .abbreviated, time: .shortened)), \(visit.calculatedScore) points")
        .accessibilityHint("Double tap to view full trip details")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            
            Circle()
                .fill(AppTheme.parchmentSurface)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "safari")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(AppTheme.mutedWarmGray)
                )
                .overlay(Circle().stroke(AppTheme.subtleBorder, lineWidth: 1))
            
            VStack(spacing: 6) {
                Text("No journeys yet")
                    .font(AppTypography.destinationTitle(size: 20, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                
                Text("When you depart Base Camp and explore memorable places, your chronological travel log will appear here.")
                    .font(AppTypography.editorialSubhead(size: 14))
                    .foregroundColor(AppTheme.mutedWarmGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                appState.selectedTab = 0
            }) {
                Text("View Base Camp")
                    .font(.system(.callout, design: .default, weight: .semibold))
                    .foregroundColor(AppTheme.parchmentSurface)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 44)
                    .background(AppTheme.charcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityLabel("View Base Camp")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var noFilterMatchesView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            
            Text("No matching journeys")
                .font(AppTypography.destinationTitle(size: 18, weight: .medium))
                .foregroundColor(AppTheme.charcoal)
            
            Text("Try clearing search queries or switching the category filter.")
                .font(AppTypography.editorialSubhead(size: 14))
                .foregroundColor(AppTheme.mutedWarmGray)
            
            Button("Reset Filters") {
                selectedFilter = "ALL"
                searchText = ""
            }
            .font(.system(.callout, design: .default, weight: .semibold))
            .foregroundColor(AppTheme.terracotta)
            .frame(minHeight: 44)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatCurrency(amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(code) \(amount)"
    }
}

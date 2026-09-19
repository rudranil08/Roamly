import SwiftUI
import SwiftData

struct CommunityRankEntry: Identifiable {
    let rank: Int
    let name: String
    let points: Int
    var id: Int { rank }
}

struct LeaderboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var visits: [VisitEntity]
    
    private var totalPoints: Int {
        GamificationEngine.shared.calculateTotalPoints(from: visits)
    }
    
    private var totalDistanceKm: Double {
        visits.reduce(0.0) { $0 + $1.distanceKm }
    }
    
    private var explorerLevel: GamificationLevel {
        GamificationEngine.shared.calculateLevel(from: totalPoints)
    }
    
    private var ecoMetrics: (co2SavedKg: Double, ecoRatio: Double) {
        GamificationEngine.shared.calculateEcoImpact(from: visits)
    }
    
    private var streakStats: (current: Int, longest: Int) {
        GamificationEngine.shared.calculateStreak(from: visits)
    }
    
    private var badges: [AchievementBadge] {
        GamificationEngine.shared.evaluateBadges(from: visits)
    }
    
    private var communityRanks: [CommunityRankEntry] {
        let pts = totalPoints
        let elena = max(3420, pts + 850)
        let marcus = max(2890, pts + 320)
        let aria = max(1640, max(0, pts - 210))
        let kenji = max(1120, max(0, pts - 480))
        
        let rawItems: [(name: String, points: Int)] = [
            ("Elena Rostova", elena),
            ("Marcus Vance", marcus),
            ("You (Explorer)", pts),
            ("Aria Thorne", aria),
            ("Kenji Sato", kenji)
        ]
        
        let sorted = rawItems.sorted { $0.points > $1.points }
        var entries: [CommunityRankEntry] = []
        for (index, item) in sorted.enumerated() {
            entries.append(CommunityRankEntry(rank: index + 1, name: item.name, points: item.points))
        }
        return entries
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // 1. Explorer Profile & Level Card
                    explorerProfileCard
                    
                    // 2. Traversal & Eco Impact Strip
                    traversalAndEcoStrip
                    
                    // 3. Travel Milestone Seals (Achievements)
                    milestoneSealsSection
                    
                    // 4. Explorer Community Ledger
                    communityLedgerSection
                    
                    // Bottom clearance for floating navigation
                    Spacer()
                        .frame(height: 70)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(AppTheme.parchment)
            .navigationTitle("Explorer Record")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 1. Explorer Profile Card (Editorial passport styling)
    
    private var explorerProfileCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TRAVELER RANK · LEVEL \(explorerLevel.level)")
                        .font(AppTypography.uiTag(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(AppTheme.mutedWarmGray)
                    
                    Text(explorerLevel.title)
                        .font(AppTypography.destinationTitle(size: 26, weight: .medium))
                        .foregroundColor(AppTheme.charcoal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalPoints.formatted())")
                        .font(.system(.title2, design: .serif, weight: .semibold))
                        .foregroundColor(AppTheme.charcoal)
                    Text("points")
                        .font(AppTypography.uiTag(size: 9, weight: .regular))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
            
            // Subtle progress line to next milestone threshold
            VStack(alignment: .leading, spacing: 6) {
                let progress = explorerLevel.progressFraction(for: totalPoints)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppTheme.parchment)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(AppTheme.terracotta)
                            .frame(width: max(6, geo.size.width * CGFloat(progress)), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(totalPoints.formatted()) of \(explorerLevel.nextThreshold.formatted()) points")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                    Spacer()
                    Text("Next: \(explorerLevel.nextTierTitle)")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
        }
        .padding(18)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Explorer Profile: \(explorerLevel.title), Level \(explorerLevel.level), \(totalPoints.formatted()) points out of \(explorerLevel.nextThreshold.formatted()) needed for next tier: \(explorerLevel.nextTierTitle).")
    }
    
    // MARK: - 2. Traversal & Eco Impact Strip
    
    private var traversalAndEcoStrip: some View {
        HStack(spacing: 12) {
            // Traversal & Streak
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "flame")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.terracotta)
                        .accessibilityHidden(true)
                    Text("STREAK")
                        .font(AppTypography.uiTag(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                Text("\(streakStats.current) days")
                    .font(AppTypography.destinationTitle(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Best: \(streakStats.longest) days")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.parchmentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Streak: \(streakStats.current) days, personal best \(streakStats.longest) days")
            
            // Eco Impact
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "leaf")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.sageOlive)
                        .accessibilityHidden(true)
                    Text("FOOTPRINT")
                        .font(AppTypography.uiTag(size: 9, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
                
                Text(String(format: "%.1f kg", ecoMetrics.co2SavedKg))
                    .font(AppTypography.destinationTitle(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(Int(ecoMetrics.ecoRatio * 100))% sustainable")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.parchmentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Carbon Footprint: \(String(format: "%.1f kg", ecoMetrics.co2SavedKg)) CO2 avoided, \(Int(ecoMetrics.ecoRatio * 100))% sustainable travel ratio")
        }
    }
    
    // MARK: - 3. Travel Milestone Seals (Achievements / Medallions)
    
    private var milestoneSealsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("TRAVEL MILESTONES")
                    .font(AppTypography.uiTag(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(AppTheme.mutedWarmGray)
                
                Spacer()
                
                Text("\(badges.filter { $0.isUnlocked }.count) of \(badges.count) reached")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(badges) { badge in
                        milestoneSealCard(badge)
                    }
                }
            }
        }
    }
    
    private func milestoneSealCard(_ badge: AchievementBadge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? AppTheme.terracottaSubtle : AppTheme.parchment)
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: badge.isUnlocked ? badge.systemIcon : "lock")
                        .font(.system(size: 16, weight: badge.isUnlocked ? .medium : .regular))
                        .foregroundColor(badge.isUnlocked ? AppTheme.terracotta : AppTheme.mutedWarmGray)
                }
                .accessibilityHidden(true)
                
                Spacer()
                
                if badge.isUnlocked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.terracotta)
                        .accessibilityHidden(true)
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(badge.title)
                    .font(AppTypography.destinationTitle(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.charcoal)
                    .lineLimit(1)
                
                Text(badge.subtitle)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(AppTheme.mutedWarmGray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if badge.isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.terracotta)
                    Text("Unlocked")
                        .font(AppTypography.uiTag(size: 9, weight: .semibold))
                        .foregroundColor(AppTheme.terracotta)
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    ProgressView(value: badge.progressFraction)
                        .tint(AppTheme.charcoal)
                        .scaleEffect(x: 1, y: 0.7)
                    
                    Text("\(badge.currentProgress)/\(badge.requiredProgress)")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(AppTheme.mutedWarmGray)
                }
            }
        }
        .padding(14)
        .frame(minWidth: 156, maxWidth: 180, alignment: .leading)
        .background(AppTheme.parchmentSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.subtleBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.title), \(badge.subtitle). Status: \(badge.isUnlocked ? "Unlocked" : "In progress, \(badge.currentProgress) of \(badge.requiredProgress)")")
    }
    
    // MARK: - 4. Explorer Community Ledger
    
    private var communityLedgerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMMUNITY LEDGER")
                .font(AppTypography.uiTag(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(AppTheme.mutedWarmGray)
            
            VStack(spacing: 0) {
                ForEach(communityRanks) { item in
                    let isCurrentUser = item.name.contains("You")
                    
                    HStack(spacing: 14) {
                        // Rank with both shape indicator and number
                        HStack(spacing: 4) {
                            if item.rank == 1 {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.terracotta)
                            }
                            Text("\(item.rank)")
                                .font(.system(.subheadline, design: .serif, weight: .medium))
                                .foregroundColor(item.rank <= 3 ? AppTheme.terracotta : AppTheme.mutedWarmGray)
                        }
                        .frame(width: 32, alignment: .leading)
                        
                        Text(item.name)
                            .font(.system(.body, design: .default, weight: isCurrentUser ? .semibold : .regular))
                            .foregroundColor(AppTheme.charcoal)
                        
                        Spacer()
                        
                        Text("\(item.points.formatted()) pts")
                            .font(.system(.subheadline, design: .rounded, weight: isCurrentUser ? .semibold : .regular))
                            .foregroundColor(isCurrentUser ? AppTheme.charcoal : AppTheme.mutedWarmGray)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(isCurrentUser ? AppTheme.parchment : Color.clear)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Rank \(item.rank): \(item.name), \(item.points.formatted()) points\(isCurrentUser ? ", your ranking" : "")")
                    
                    if item.rank < communityRanks.count {
                        Divider()
                            .background(AppTheme.subtleBorder)
                            .padding(.leading, 56)
                    }
                }
            }
            .background(AppTheme.parchmentSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.subtleBorder, lineWidth: 1)
            )
        }
    }
}

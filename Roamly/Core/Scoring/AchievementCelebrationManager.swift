import Foundation
import SwiftUI

@MainActor
@Observable
public final class AchievementCelebrationManager {
    public static let shared = AchievementCelebrationManager()
    
    public private(set) var currentCelebration: AchievementBadge? = nil
    private var pendingQueue: [AchievementBadge] = []
    private var autoDismissTask: Task<Void, Never>? = nil
    
    private let storageKey = "roamly_unlocked_achievement_ids"
    private let initializedKey = "roamly_achievements_system_initialized"
    
    public private(set) var unlockedBadgeIds: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(unlockedBadgeIds), forKey: storageKey)
        }
    }
    
    public init() {
        let stored = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        self.unlockedBadgeIds = Set(stored)
    }
    
    /// Evaluates current visits against all achievement criteria.
    /// Newly unlocked badges that have not been celebrated previously are queued and displayed.
    /// Existing already-unlocked badges will NOT trigger duplicate popups.
    @discardableResult
    public func evaluateAndCelebrate(visits: [VisitEntity]) -> [AchievementBadge] {
        let allBadges = GamificationEngine.shared.evaluateBadges(from: visits)
        let unlockedBadges = allBadges.filter { $0.isUnlocked }
        
        let hasInitialized = UserDefaults.standard.bool(forKey: initializedKey)
        if !hasInitialized {
            // First time running with achievement celebration system:
            // Mark any already-unlocked achievements as pre-acknowledged so cold launch doesn't spam popups.
            UserDefaults.standard.set(true, forKey: initializedKey)
            for badge in unlockedBadges {
                unlockedBadgeIds.insert(badge.id)
            }
            return []
        }
        
        var newlyUnlocked: [AchievementBadge] = []
        for badge in unlockedBadges {
            if !unlockedBadgeIds.contains(badge.id) {
                unlockedBadgeIds.insert(badge.id)
                newlyUnlocked.append(badge)
            }
        }
        
        for badge in newlyUnlocked {
            enqueueCelebration(badge)
        }
        
        return newlyUnlocked
    }
    
    /// Triggers a celebration for a specific badge (e.g. testing or explicit events).
    /// Respects deduplication if force is false.
    public func triggerCelebration(badge: AchievementBadge, force: Bool = false) {
        if !force && unlockedBadgeIds.contains(badge.id) {
            return
        }
        unlockedBadgeIds.insert(badge.id)
        enqueueCelebration(badge)
    }
    
    private func enqueueCelebration(_ badge: AchievementBadge) {
        // Prevent duplicate queue entries for the same badge
        guard !pendingQueue.contains(where: { $0.id == badge.id }) && currentCelebration?.id != badge.id else {
            return
        }
        
        pendingQueue.append(badge)
        displayNextCelebrationIfNeeded()
    }
    
    private func displayNextCelebrationIfNeeded() {
        guard currentCelebration == nil, !pendingQueue.isEmpty else { return }
        
        let nextBadge = pendingQueue.removeFirst()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            self.currentCelebration = nextBadge
        }
        
        // Trigger haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Schedule auto-dismissal after 5.0 seconds
        autoDismissTask?.cancel()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.dismissCurrent()
        }
    }
    
    /// Dismisses the currently displayed celebration popup and advances the queue.
    public func dismissCurrent() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        
        withAnimation(.easeInOut(duration: 0.25)) {
            self.currentCelebration = nil
        }
        
        // Advance to next queued celebration after smooth dismissal transition
        if !pendingQueue.isEmpty {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                await self?.displayNextCelebrationIfNeeded()
            }
        }
    }
    
    /// Developer / testing helper to reset all unlocks
    public func resetAllUnlocks() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        currentCelebration = nil
        pendingQueue.removeAll()
        unlockedBadgeIds.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: initializedKey)
    }
}

import Foundation
import UserNotifications

public final class NotificationService: Sendable {
    public static let shared = NotificationService()
    
    public static let visitCategoryIdentifier = "ROAMLY_VISIT_ARRIVAL"
    
    private init() {
        registerCategories()
    }
    
    public func registerCategories() {
        let confirmAction = UNNotificationAction(
            identifier: "CONFIRM_VISIT_ACTION",
            title: "Confirm Visit",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Not Now",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: Self.visitCategoryIdentifier,
            actions: [confirmAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    /// Dispatches an actionable local notification when a user arrives at a candidate venue
    public func notifyArrival(at placeName: String, category: DestinationCategory) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Arrived at \(placeName)"
            content.body = "Roamly detected you are at \(placeName). Tap to confirm your visit and earn \(String(format: "%.1fx", category.significanceMultiplier)) points!"
            content.sound = .default
            content.categoryIdentifier = Self.visitCategoryIdentifier
            content.userInfo = [
                "placeName": placeName,
                "category": category.rawValue
            ]
            
            // Deliver in 1 second
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
            let request = UNNotificationRequest(
                identifier: "roamly.arrival.\(UUID().uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[NotificationService] Error delivering notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func clearAllPendingArrivalNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

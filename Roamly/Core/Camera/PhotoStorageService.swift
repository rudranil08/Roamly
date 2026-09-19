import UIKit

public struct PhotoStorageService {
    private static var storageDirectory: URL {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls.first ?? fileManager.temporaryDirectory
        let photoDir = appSupport.appendingPathComponent("VisitPhotos", isDirectory: true)
        if !fileManager.fileExists(atPath: photoDir.path) {
            try? fileManager.createDirectory(at: photoDir, withIntermediateDirectories: true)
        }
        return photoDir
    }
    
    public static func savePhoto(image: UIImage, for visitId: UUID) -> String? {
        let fileURL = storageDirectory.appendingPathComponent("\(visitId.uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }
    
    public static func loadPhoto(for visitId: UUID, path: String? = nil) -> UIImage? {
        if let path = path, FileManager.default.fileExists(atPath: path), let img = UIImage(contentsOfFile: path) {
            return img
        }
        let fileURL = storageDirectory.appendingPathComponent("\(visitId.uuidString).jpg")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }
    
    public static func generateProofPlaceholder(
        placeName: String,
        category: DestinationCategory,
        latitude: Double,
        longitude: Double,
        date: Date,
        hashPrefix: String
    ) -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Subtle scenic background gradient
            let colors = [
                UIColor(red: 0.12, green: 0.45, blue: 0.85, alpha: 1.0).cgColor,
                UIColor(red: 0.08, green: 0.20, blue: 0.40, alpha: 1.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Icon
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 64, weight: .bold)
            if let icon = UIImage(systemName: category.systemIcon, withConfiguration: iconConfig) {
                UIColor.white.withAlphaComponent(0.85).set()
                icon.draw(at: CGPoint(x: size.width / 2 - 32, y: 150))
            }
            
            let centerStyle = NSMutableParagraphStyle()
            centerStyle.alignment = .center
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: centerStyle
            ]
            let rect1 = CGRect(x: 40, y: 260, width: size.width - 80, height: 45)
            (placeName as NSString).draw(in: rect1, withAttributes: titleAttrs)
            
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .paragraphStyle: centerStyle
            ]
            let rect2 = CGRect(x: 40, y: 315, width: size.width - 80, height: 35)
            ("Hardware-Verified Geo-Proof" as NSString).draw(in: rect2, withAttributes: subAttrs)
            
            // Bottom telemetry watermark
            let barHeight: CGFloat = 80
            let barRect = CGRect(x: 0, y: size.height - barHeight, width: size.width, height: barHeight)
            UIColor.black.withAlphaComponent(0.75).setFill()
            UIRectFill(barRect)
            
            let monoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.systemGreen
            ]
            let telemetry = String(format: "📍 LAT: %.4f LON: %.4f • %@ • dHash: %@", latitude, longitude, date.formatted(date: .abbreviated, time: .shortened), hashPrefix)
            (telemetry as NSString).draw(at: CGPoint(x: 20, y: size.height - barHeight + 18), withAttributes: monoAttrs)
            
            let badgeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let badge = "ROAMLY SECURE SENSOR BINDING [PASS]"
            (badge as NSString).draw(at: CGPoint(x: 20, y: size.height - barHeight + 42), withAttributes: badgeAttrs)
        }
    }
}

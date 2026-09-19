import UIKit
import CoreGraphics

public struct PerceptualHashEngine {
    /// Computes a 64-bit Difference Hash (dHash) for an image.
    /// Resizes the image to 9x8, converts to grayscale, and compares adjacent horizontal pixels.
    public static func computeDHash(image: UIImage) -> String {
        let targetWidth = 9
        let targetHeight = 8
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var rawData = [UInt8](repeating: 0, count: targetWidth * targetHeight)
        
        guard let context = CGContext(
            data: &rawData,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let cgImage = image.cgImage else {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        var hashString = ""
        for row in 0..<targetHeight {
            for col in 0..<(targetWidth - 1) {
                let leftPixel = rawData[row * targetWidth + col]
                let rightPixel = rawData[row * targetWidth + col + 1]
                hashString += (leftPixel > rightPixel) ? "1" : "0"
            }
        }
        
        return hashString
    }
    
    /// Computes the Hamming distance between two 64-bit hash strings.
    /// Distance <= 10 usually indicates nearly identical / duplicate images.
    public static func hammingDistance(hash1: String, hash2: String) -> Int {
        guard hash1.count == hash2.count else { return 64 }
        var distance = 0
        for (c1, c2) in zip(hash1, hash2) {
            if c1 != c2 { distance += 1 }
        }
        return distance
    }
}

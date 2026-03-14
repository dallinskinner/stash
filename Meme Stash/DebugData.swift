#if DEBUG
import UIKit
import SwiftData

nonisolated enum DebugData {
    static func generateSampleMemes(in context: ModelContext, count: Int = 30) {
        let calendar = Calendar.current
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemTeal, .systemPink, .systemYellow, .systemIndigo, .systemMint]

        for i in 0..<count {
            let daysAgo = Int.random(in: 0...90)
            let hoursAgo = Int.random(in: 0...23)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.date(byAdding: .hour, value: -hoursAgo, to: .now)!)!

            let color = colors[i % colors.count]
            guard let imageData = generatePlaceholderImage(color: color, index: i) else { continue }

            let meme = Meme(imageData: imageData)
            meme.savedAt = date
            context.insert(meme)
        }
        try? context.save()
    }

    private static func generatePlaceholderImage(color: UIColor, index: Int) -> Data? {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let text = "Meme #\(index + 1)" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32),
                .foregroundColor: UIColor.white,
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif

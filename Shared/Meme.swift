import Foundation
import SwiftData

@Model
final class Meme {
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var savedAt: Date

    init(imageData: Data) {
        self.id = UUID()
        self.imageData = imageData
        self.savedAt = Date()
    }
}

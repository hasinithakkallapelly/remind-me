import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var text: String
    var isActive: Bool
    var createdAt: Date
    var place: Place?

    init(id: UUID = UUID(), text: String, isActive: Bool = true, place: Place? = nil) {
        self.id = id
        self.text = text
        self.isActive = isActive
        self.createdAt = Date()
        self.place = place
    }
}

import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCompleted: Bool
    /// When set, this reminder counts toward the "due by tomorrow" warning
    /// in the end-of-day summary once it's on or before tomorrow.
    var dueDate: Date?
    /// When this was marked done — used to count "finished today" in the
    /// end-of-day summary. Cleared if the reminder is un-checked.
    var completedAt: Date?
    var createdAt: Date
    var place: Place?

    init(id: UUID = UUID(), text: String, dueDate: Date? = nil, place: Place? = nil) {
        self.id = id
        self.text = text
        self.isCompleted = false
        self.dueDate = dueDate
        self.completedAt = nil
        self.createdAt = Date()
        self.place = place
    }
}

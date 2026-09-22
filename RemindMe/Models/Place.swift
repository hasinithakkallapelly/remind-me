import Foundation
import SwiftData

@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    /// Geofence radius in meters.
    var radius: Double
    var createdAt: Date

    /// IDs of other places whose reminders should also surface when this
    /// place's geofence is entered (e.g. CSE dept linked to the hospital
    /// next door). Kept as raw UUIDs rather than a SwiftData relationship
    /// so linking is symmetric-free and cheap to edit from either side.
    var linkedPlaceIDs: [UUID]

    @Relationship(deleteRule: .cascade, inverse: \Reminder.place)
    var reminders: [Reminder] = []

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 150,
        linkedPlaceIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.linkedPlaceIDs = linkedPlaceIDs
        self.createdAt = Date()
    }
}

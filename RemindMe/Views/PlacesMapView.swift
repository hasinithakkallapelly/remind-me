import SwiftUI
import MapKit
import CoreLocation

struct PlacesMapView: View {
    let places: [Place]

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if places.isEmpty {
                    ContentUnavailableView(
                        "No saved places yet",
                        systemImage: "map",
                        description: Text("Places you save will show up here as bubbles you can zoom out to see all at once.")
                    )
                } else {
                    Map(position: $cameraPosition) {
                        ForEach(places) { place in
                            Annotation(place.name, coordinate: coordinate(for: place)) {
                                NavigationLink(value: place) {
                                    PlaceBubble(place: place)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .navigationDestination(for: Place.self) { place in
                PlaceDetailView(place: place, allPlaces: places)
            }
            .onAppear { fitToPlaces() }
            .onChange(of: places) { _, _ in fitToPlaces() }
        }
    }

    private func coordinate(for place: Place) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
    }

    private func fitToPlaces() {
        guard !places.isEmpty else { return }
        let coordinates = places.map(coordinate(for:))
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        // Pad the span so edge bubbles aren't clipped, with a floor so a
        // single place (or two very close ones) doesn't zoom in absurdly far.
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.02),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.02)
        )
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

private struct PlaceBubble: View {
    let place: Place

    private var incompleteReminders: [Reminder] {
        place.reminders.filter { !$0.isCompleted }
    }

    private var color: Color {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        if incompleteReminders.contains(where: { ($0.dueDate ?? .distantFuture) < startOfToday }) {
            return .red
        }
        if incompleteReminders.contains(where: { reminder in
            guard let dueDate = reminder.dueDate else { return false }
            return calendar.isDateInToday(dueDate) || calendar.isDateInTomorrow(dueDate)
        }) {
            return .orange
        }
        return incompleteReminders.isEmpty ? .gray : .blue
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 34, height: 34)
                .shadow(radius: 2)
            Text("\(incompleteReminders.count)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

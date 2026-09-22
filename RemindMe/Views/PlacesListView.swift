import SwiftUI
import SwiftData

struct PlacesListView: View {
    @Environment(\.modelContext) private var modelContext
    let places: [Place]

    @State private var isPresentingAddPlace = false

    var body: some View {
        List {
            if places.isEmpty {
                ContentUnavailableView(
                    "No saved places yet",
                    systemImage: "mappin.slash",
                    description: Text("Add places you visit often, like your department or the hospital, and attach reminders to them.")
                )
            } else {
                ForEach(places) { place in
                    NavigationLink(value: place) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(place.name)
                                .font(.headline)
                            Text("\(place.reminders.count) reminder\(place.reminders.count == 1 ? "" : "s") · \(Int(place.radius))m radius")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deletePlaces)
            }
        }
        .navigationDestination(for: Place.self) { place in
            PlaceDetailView(place: place, allPlaces: places)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddPlace = true
                } label: {
                    Label("Add Place", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddPlace) {
            AddEditPlaceView()
        }
    }

    private func deletePlaces(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(places[index])
        }
    }
}

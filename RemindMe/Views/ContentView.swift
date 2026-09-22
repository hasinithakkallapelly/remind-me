import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Place.createdAt) private var places: [Place]
    @StateObject private var locationManager = LocationManager.shared

    var body: some View {
        NavigationStack {
            PlacesListView(places: places)
                .navigationTitle("Remind Me")
        }
        .environmentObject(locationManager)
        .onAppear {
            locationManager.configure(context: modelContext)
            NotificationManager.shared.requestAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.refreshMonitoredRegions(for: places)
        }
        .onChange(of: places) { _, updatedPlaces in
            locationManager.refreshMonitoredRegions(for: updatedPlaces)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Place.self, Reminder.self], inMemory: true)
}

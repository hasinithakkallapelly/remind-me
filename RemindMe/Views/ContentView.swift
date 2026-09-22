import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Place.createdAt) private var places: [Place]
    @StateObject private var locationManager = LocationManager.shared

    @AppStorage(DigestSettings.hourKey) private var digestHour = DigestSettings.defaultHour
    @AppStorage(DigestSettings.minuteKey) private var digestMinute = DigestSettings.defaultMinute

    @State private var isPresentingSettings = false

    var body: some View {
        NavigationStack {
            PlacesListView(places: places)
                .navigationTitle("Remind Me")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isPresentingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
        }
        .environmentObject(locationManager)
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
        .onAppear {
            locationManager.configure(context: modelContext)
            NotificationManager.shared.requestAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.refreshMonitoredRegions(for: places)
            refreshDigest()
        }
        .onChange(of: places) { _, updatedPlaces in
            locationManager.refreshMonitoredRegions(for: updatedPlaces)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshDigest()
            }
        }
    }

    private func refreshDigest() {
        DigestManager.refreshSchedule(context: modelContext, hour: digestHour, minute: digestMinute)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Place.self, Reminder.self], inMemory: true)
}

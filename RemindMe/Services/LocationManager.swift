import Foundation
import CoreLocation
import SwiftData

/// Wraps CLLocationManager region monitoring (geofencing). Owns no UI;
/// ContentView configures it with a ModelContext and keeps its monitored
/// regions in sync with the saved Places.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    /// iOS hard-caps simultaneously monitored regions per app.
    static let maxMonitoredRegions = 20

    private let manager = CLLocationManager()
    private var modelContext: ModelContext?

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastEnteredPlaceName: String?
    @Published var currentLocation: CLLocation?
    /// Bumped on every location update. CLLocation isn't Equatable, so
    /// views that need to react to new fixes (e.g. via .onChange) observe
    /// this instead of currentLocation directly.
    @Published var currentLocationUpdateID = UUID()

    private override init() {
        super.init()
        manager.delegate = self
        currentLocation = manager.location
    }

    func configure(context: ModelContext) {
        self.modelContext = context
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func requestOneTimeLocation() {
        manager.requestLocation()
    }

    /// Re-registers geofences for exactly the given places, dropping any
    /// regions for places that were deleted or edited since.
    func refreshMonitoredRegions(for places: [Place]) {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        for place in places.prefix(Self.maxMonitoredRegions) {
            let center = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
            let region = CLCircularRegion(center: center, radius: place.radius, identifier: place.id.uuidString)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        currentLocationUpdateID = UUID()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let context = modelContext, let placeID = UUID(uuidString: region.identifier) else { return }
        handleEntered(placeID: placeID, context: context)
    }

    private func handleEntered(placeID: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<Place>(predicate: #Predicate { $0.id == placeID })
        guard let place = try? context.fetch(descriptor).first else { return }

        lastEnteredPlaceName = place.name

        // Not-yet-completed reminders fire every time this geofence is
        // entered, and keep firing on future entries until marked done.
        var remindersToFire = place.reminders.filter { !$0.isCompleted }

        for linkedID in place.linkedPlaceIDs {
            let linkedDescriptor = FetchDescriptor<Place>(predicate: #Predicate { $0.id == linkedID })
            if let linkedPlace = try? context.fetch(linkedDescriptor).first {
                remindersToFire += linkedPlace.reminders.filter { !$0.isCompleted }
            }
        }

        for reminder in remindersToFire {
            NotificationManager.shared.sendNotification(
                title: "Near \(place.name)",
                body: reminder.text,
                identifier: reminder.id.uuidString
            )
        }

        if remindersToFire.isEmpty {
            NotificationManager.shared.sendNotification(
                title: "Near \(place.name)",
                body: "You're near a saved place.",
                identifier: "\(placeID.uuidString)-generic"
            )
        }

        DigestManager.refreshSchedule(
            context: context,
            hour: UserDefaults.standard.integer(forKey: DigestSettings.hourKey),
            minute: UserDefaults.standard.integer(forKey: DigestSettings.minuteKey)
        )
    }
}

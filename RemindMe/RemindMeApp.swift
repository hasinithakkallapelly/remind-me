import SwiftUI
import SwiftData

@main
struct RemindMeApp: App {
    init() {
        DigestSettings.registerDefaults()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Place.self, Reminder.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

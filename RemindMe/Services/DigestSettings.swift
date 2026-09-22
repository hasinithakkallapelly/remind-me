import Foundation

/// Shared UserDefaults keys for the daily summary time, so SwiftUI's
/// @AppStorage (in Settings) and plain UserDefaults reads (in services that
/// aren't views, like LocationManager) stay in sync.
enum DigestSettings {
    static let hourKey = "digestHour"
    static let minuteKey = "digestMinute"
    static let defaultHour = 21
    static let defaultMinute = 0

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            hourKey: defaultHour,
            minuteKey: defaultMinute
        ])
    }
}

import Foundation
import SwiftData

/// Computes the end-of-day summary ("N finished today, N due by tomorrow")
/// and (re)schedules the notification that delivers it.
///
/// A local notification's content is fixed at schedule time, not computed
/// fresh when it fires, so this has to be re-run whenever the numbers could
/// have changed — the app coming to the foreground, a reminder being
/// completed, or a geofence firing — to keep tonight's notification
/// accurate. If nothing triggers a refresh between now and the digest time,
/// the notification shows whatever counts were last computed.
enum DigestManager {
    static let notificationIdentifier = "daily-digest"

    static func refreshSchedule(context: ModelContext, hour: Int, minute: Int) {
        let allReminders = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        let calendar = Calendar.current
        let now = Date()

        let completedToday = allReminders.filter { reminder in
            guard reminder.isCompleted, let completedAt = reminder.completedAt else { return false }
            return calendar.isDateInToday(completedAt)
        }.count

        // "Due by tomorrow" = overdue, due today, or due tomorrow — anything
        // not done that can't wait past tomorrow.
        let dayAfterTomorrowStart = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now)) ?? now
        let dueByTomorrowCount = allReminders.filter { reminder in
            guard !reminder.isCompleted, let dueDate = reminder.dueDate else { return false }
            return dueDate < dayAfterTomorrowStart
        }.count

        var bodyParts = ["Finished today: \(completedToday)"]
        if dueByTomorrowCount > 0 {
            bodyParts.append("Due by tomorrow: \(dueByTomorrowCount) — must finish!")
        } else {
            bodyParts.append("Nothing urgent due tomorrow.")
        }

        NotificationManager.shared.scheduleOneShot(
            identifier: notificationIdentifier,
            title: "Daily Summary",
            body: bodyParts.joined(separator: ". "),
            fireDate: nextFireDate(hour: hour, minute: minute, now: now, calendar: calendar)
        )
    }

    private static func nextFireDate(hour: Int, minute: Int, now: Date, calendar: Calendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        let todayAtDigestTime = calendar.date(from: components) ?? now

        if todayAtDigestTime > now {
            return todayAtDigestTime
        }
        return calendar.date(byAdding: .day, value: 1, to: todayAtDigestTime) ?? todayAtDigestTime
    }
}

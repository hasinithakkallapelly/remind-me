import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage(DigestSettings.hourKey) private var digestHour = DigestSettings.defaultHour
    @AppStorage(DigestSettings.minuteKey) private var digestMinute = DigestSettings.defaultMinute

    @State private var digestTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Daily summary time", selection: $digestTime, displayedComponents: .hourAndMinute)
                } footer: {
                    Text("Each day at this time you'll get a notification with how many reminders you finished and how many are due by tomorrow.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                var components = DateComponents()
                components.hour = digestHour
                components.minute = digestMinute
                digestTime = Calendar.current.date(from: components) ?? Date()
            }
        }
    }

    private func save() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: digestTime)
        digestHour = components.hour ?? DigestSettings.defaultHour
        digestMinute = components.minute ?? DigestSettings.defaultMinute
        DigestManager.refreshSchedule(context: modelContext, hour: digestHour, minute: digestMinute)
    }
}

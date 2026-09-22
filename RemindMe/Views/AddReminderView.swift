import SwiftUI
import SwiftData

struct AddReminderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let place: Place

    @State private var text = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("e.g. Pick up prescription", text: $text)
                }

                Section {
                    Toggle("Set a due date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: .date)
                    }
                } footer: {
                    Text("If it isn't marked done by the day after this date, it counts toward the \"due by tomorrow\" warning in your end-of-day summary.")
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let reminder = Reminder(text: trimmed, dueDate: hasDueDate ? dueDate : nil, place: place)
        modelContext.insert(reminder)
        dismiss()
    }
}

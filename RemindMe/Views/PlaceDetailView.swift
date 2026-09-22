import SwiftUI
import SwiftData

struct PlaceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var place: Place
    let allPlaces: [Place]

    @State private var isPresentingAddReminder = false
    @State private var isPresentingEdit = false

    private var otherPlaces: [Place] {
        allPlaces.filter { $0.id != place.id }
    }

    var body: some View {
        Form {
            Section("Reminders here") {
                if place.reminders.isEmpty {
                    Text("No reminders yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(place.reminders.sorted(by: { $0.createdAt < $1.createdAt })) { reminder in
                    reminderRow(reminder)
                }
                .onDelete(perform: deleteReminders)

                Button {
                    isPresentingAddReminder = true
                } label: {
                    Label("Add Reminder", systemImage: "plus")
                }
            }

            Section {
                ForEach(otherPlaces) { other in
                    Toggle(other.name, isOn: Binding(
                        get: { place.linkedPlaceIDs.contains(other.id) },
                        set: { isLinked in
                            if isLinked {
                                if !place.linkedPlaceIDs.contains(other.id) {
                                    place.linkedPlaceIDs.append(other.id)
                                }
                            } else {
                                place.linkedPlaceIDs.removeAll { $0 == other.id }
                            }
                        }
                    ))
                }
                if otherPlaces.isEmpty {
                    Text("Add another place to link it here.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Also remind me about")
            } footer: {
                Text("When you're near \(place.name), you'll also get reminders from any places linked here — e.g. link the hospital to CSE dept if they're close together.")
            }

            Section("Location") {
                LabeledContent("Radius", value: "\(Int(place.radius)) m")
                LabeledContent("Coordinates", value: String(format: "%.5f, %.5f", place.latitude, place.longitude))
                Button("Edit Place") { isPresentingEdit = true }
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddReminder) {
            AddReminderView(place: place)
        }
        .sheet(isPresented: $isPresentingEdit) {
            AddEditPlaceView(placeToEdit: place)
        }
    }

    @ViewBuilder
    private func reminderRow(_ reminder: Reminder) -> some View {
        Button {
            toggleCompleted(reminder)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.text)
                        .strikethrough(reminder.isCompleted)
                        .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    if let dueDate = reminder.dueDate {
                        Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(dueDateColor(dueDate, isCompleted: reminder.isCompleted))
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func dueDateColor(_ dueDate: Date, isCompleted: Bool) -> Color {
        guard !isCompleted else { return .secondary }
        let calendar = Calendar.current
        if dueDate < calendar.startOfDay(for: Date()) {
            return .red
        } else if calendar.isDateInToday(dueDate) || calendar.isDateInTomorrow(dueDate) {
            return .orange
        }
        return .secondary
    }

    private func toggleCompleted(_ reminder: Reminder) {
        reminder.isCompleted.toggle()
        reminder.completedAt = reminder.isCompleted ? Date() : nil
        DigestManager.refreshSchedule(
            context: modelContext,
            hour: UserDefaults.standard.integer(forKey: DigestSettings.hourKey),
            minute: UserDefaults.standard.integer(forKey: DigestSettings.minuteKey)
        )
    }

    private func deleteReminders(at offsets: IndexSet) {
        let sorted = place.reminders.sorted(by: { $0.createdAt < $1.createdAt })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

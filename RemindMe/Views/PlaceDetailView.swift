import SwiftUI
import SwiftData

struct PlaceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var place: Place
    let allPlaces: [Place]

    @State private var newReminderText = ""
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
                    Toggle(isOn: Binding(
                        get: { reminder.isActive },
                        set: { reminder.isActive = $0 }
                    )) {
                        Text(reminder.text)
                            .strikethrough(!reminder.isActive)
                    }
                }
                .onDelete(perform: deleteReminders)

                HStack {
                    TextField("Add a reminder…", text: $newReminderText)
                    Button("Add") { addReminder() }
                        .disabled(newReminderText.trimmingCharacters(in: .whitespaces).isEmpty)
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
        .sheet(isPresented: $isPresentingEdit) {
            AddEditPlaceView(placeToEdit: place)
        }
    }

    private func addReminder() {
        let text = newReminderText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let reminder = Reminder(text: text, place: place)
        modelContext.insert(reminder)
        newReminderText = ""
    }

    private func deleteReminders(at offsets: IndexSet) {
        let sorted = place.reminders.sorted(by: { $0.createdAt < $1.createdAt })
        for index in offsets {
            modelContext.delete(sorted[index])
        }
    }
}

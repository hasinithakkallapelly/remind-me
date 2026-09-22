import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct AddEditPlaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: LocationManager

    var placeToEdit: Place?

    @State private var name: String = ""
    @State private var radius: Double = 150
    @State private var coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasSetInitialLocation = false
    @State private var isWaitingForCurrentLocation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. CSE Department", text: $name)
                }

                Section("Location") {
                    MapReader { proxy in
                        Map(position: $cameraPosition) {
                            Marker(name.isEmpty ? "Place" : name, coordinate: coordinate)
                        }
                        .frame(height: 260)
                        .onTapGesture { screenPoint in
                            if let tapped = proxy.convert(screenPoint, from: .local) {
                                coordinate = tapped
                            }
                        }
                    }
                    Text("Tap the map to set the location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        useCurrentLocation()
                    } label: {
                        Label("Use Current Location", systemImage: "location.fill")
                    }
                }

                Section("Trigger radius") {
                    HStack {
                        Slider(value: $radius, in: 50...1000, step: 25)
                        Text("\(Int(radius))m")
                            .frame(width: 60, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(placeToEdit == nil ? "New Place" : "Edit Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let place = placeToEdit {
                    name = place.name
                    radius = place.radius
                    coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                    cameraPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800))
                    hasSetInitialLocation = true
                } else if !hasSetInitialLocation, let current = locationManager.currentLocation {
                    coordinate = current.coordinate
                    cameraPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800))
                    hasSetInitialLocation = true
                }
            }
            .onChange(of: locationManager.currentLocationUpdateID) {
                guard placeToEdit == nil, isWaitingForCurrentLocation, let updated = locationManager.currentLocation else { return }
                coordinate = updated.coordinate
                cameraPosition = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800))
                isWaitingForCurrentLocation = false
            }
        }
    }

    private func useCurrentLocation() {
        isWaitingForCurrentLocation = true
        locationManager.requestOneTimeLocation()
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let place = placeToEdit {
            place.name = trimmedName
            place.radius = radius
            place.latitude = coordinate.latitude
            place.longitude = coordinate.longitude
        } else {
            let place = Place(
                name: trimmedName,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: radius
            )
            modelContext.insert(place)
        }
        dismiss()
    }
}

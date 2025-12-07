import SwiftUI
import UIKit

struct TripList: View {
    @Binding var addAction: () -> Void

    @State private var trips: [Trip] = []
    @State private var isLoading = false
    @State private var error: Error?
    @State private var tripFormMode: TripForm.Mode?
    @State private var isLogoutConfirmationDialogPresented = false
    @State private var isSelecting = false
    @State private var selectedTripIDs: Set<Trip.ID> = []

    @Environment(\.journalService) private var journalService

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trips")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: toolbar)
                .onAppear {
                    addAction = { tripFormMode = .add }
                }
                .navigationDestination(for: Trip.self) { trip in
                    TripDetails(trip: trip, addAction: $addAction) {
                        Task {
                            await fetchTrips()
                        }
                    }
                }
                .sheet(item: $tripFormMode) { mode in
                    TripForm(mode: mode) {
                        Task {
                            await fetchTrips()
                        }
                    }
                }
                .confirmationDialog(
                    "Log out?",
                    isPresented: $isLogoutConfirmationDialogPresented,
                    titleVisibility: .visible,
                    actions: {
                        Button("Log out", role: .destructive) {
                            journalService.logOut()
                        }
                    },
                    message: {
                        Text("You will need to log in to access your account again.")
                    }
                )
                .loadingOverlay(isLoading)
        }
        .task {
            await fetchTrips()
        }
    }

    // MARK: - Views

    @ToolbarContentBuilder
    private func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Log out", systemImage: "power", role: .destructive) {
                isLogoutConfirmationDialogPresented = true
            }
        }
        ToolbarItem(placement: .primaryAction) {
            if isSelecting {
                Button("Cancel") {
                    isSelecting = false
                    selectedTripIDs.removeAll()
                }
            } else {
                Button("Select") {
                    isSelecting = true
                }
            }
        }
        if isSelecting {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    shareSelectedTrips()
                    isSelecting = false
                    selectedTripIDs.removeAll()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(selectedTripIDs.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    Task {
                        for id in selectedTripIDs {
                            await deleteTrip(withId: id)
                        }
                        selectedTripIDs.removeAll()
                        isSelecting = false
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selectedTripIDs.isEmpty)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let error {
            errorView(for: error)
        } else if trips.isEmpty && !isLoading {
            emptyView
        } else {
            listView
        }
    }

    private func errorView(for error: Error) -> some View {
        ContentUnavailableView(
            label: {
                Label("Error", systemImage: "exclamationmark.triangle.fill")
            },
            description: {
                Text(error.localizedDescription)
            },
            actions: {
                Button("Try Again") {
                    Task {
                        await fetchTrips()
                    }
                }
            }
        )
    }

    private var emptyView: some View {
        ContentUnavailableView(
            label: {
                Label("Nothing here yet!", systemImage: "face.dashed")
                    .labelStyle(.titleOnly)
            },
            description: {
                Text("Add a trip to start your trip journal.")
            }
        )
    }

    private var listView: some View {
        List(selection: $selectedTripIDs) {
            ForEach(trips) { trip in
                    TripCell(
                        trip: trip,
                        edit: {
                            tripFormMode = .edit(trip)
                        },
                        share: {
                            Task {
                                shareSelected(trip: trip)
                            }
                        },
                        delete: {
                            Task {
                                await deleteTrip(withId: trip.id)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                
                .simultaneousGesture(TapGesture().onEnded {
                    // Если включён режим выбора — перехватываем тап и не пускаем в навигацию
                    if isSelecting {
                        if selectedTripIDs.contains(trip.id) {
                            selectedTripIDs.remove(trip.id)
                        } else {
                            selectedTripIDs.insert(trip.id)
                        }
                    }
                })
                .onTapGesture {
                    if isSelecting {
                        if selectedTripIDs.contains(trip.id) {
                            selectedTripIDs.remove(trip.id)
                        } else {
                            selectedTripIDs.insert(trip.id)
                        }
                    }
                }
            }
        }
        .environment(\.editMode, .constant(isSelecting ? EditMode.active : EditMode.inactive))
        .refreshable {
            await fetchTrips()
        }
    }

    // MARK: - Networking

    private func fetchTrips() async {
        if trips.isEmpty {
            isLoading = true
        }
        error = nil
        do {
            trips = try await journalService.getTrips()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func deleteTrip(withId id: Trip.ID) async {
        isLoading = true
        do {
            try await journalService.deleteTrip(withId: id)
            await fetchTrips()
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    // MARK: - Sharing
    
    private func shareSelectedTrips() {
        let selectedTrips = trips.filter { selectedTripIDs.contains($0.id) }
        guard !selectedTrips.isEmpty else { return }

        let summary = selectedTrips
            .map { String(describing: $0) }
            .joined(separator: "\n\n")

        let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)

        // Present from the top-most view controller
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let root = window.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            presenter.present(activityVC, animated: true)
        }
    }
    
    private func shareSelected(trip: Trip) {
        let summary = String(describing: trip)
        let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)

        // Present from the top-most view controller
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let root = window.rootViewController {
            var presenter = root
            while let presented = presenter.presentedViewController { presenter = presented }
            presenter.present(activityVC, animated: true)
        }
    }
}

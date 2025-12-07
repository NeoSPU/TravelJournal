import SwiftUI

struct TripCell: View {
    let trip: Trip
    let edit: () -> Void
    let share: () -> Void
    let delete: () -> Void

    // MARK: - Body

    var body: some View {
        NavigationLink(value: trip) {
            VStack(alignment: .leading) {
                nameLabel
                dateLabel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("Edit", systemImage: "pencil", action: edit)
                .tint(.accent)
            Button("Share", systemImage: "square.and.arrow.up", action: share)
                .tint(.accent)
        }
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", action: delete)
                .tint(.red)
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil", action: edit)
            Button("Share", systemImage: "square.and.arrow.up", action: share)
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        }
    }

    // MARK: - Views

    private var dateLabel: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(trip.startDate, style: .date)
            Text("-")
            Text(trip.endDate, style: .date)
        }
        .font(.footnote)
    }

    private var nameLabel: some View {
        Text(trip.name)
            .font(.headline)
    }
}

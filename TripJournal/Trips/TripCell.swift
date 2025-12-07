import SwiftUI

struct TripCell: View {
    let trip: Trip
    let edit: () -> Void
    let share: () -> Void
    let delete: () -> Void

    // MARK: - Body

    var body: some View {
            VStack(alignment: .leading) {
                nameLabel
                dateLabel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

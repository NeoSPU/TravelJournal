import Foundation
import SwiftUI

final class DeepLinkRouter: ObservableObject {
    // When set, RootView can react by navigating to the appropriate screen
    @Published var tripToOpen: Trip? = nil

    func handle(trip: Trip) {
        tripToOpen = trip
    }

    func clear() {
        tripToOpen = nil
    }
}

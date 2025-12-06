import SwiftUI

@main
struct TripJournalApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(service: JournalServiceLive(delay: 0.25))
        }
    }
}

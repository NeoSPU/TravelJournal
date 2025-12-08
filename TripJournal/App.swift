import SwiftUI

@main
struct TripJournalApp: App {
    
    @State var incomingTrip: Trip?
    @State private var incomingTripPrefill: (name: String, startDate: Date, endDate: Date)?
    @State private var addAction: () -> Void = {}
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView(service: JournalServiceLive(delay: 0.25))
                .environmentObject(deepLinkRouter)
                .onOpenURL { url in
                    Task { await handleIncomingURL(url) }
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) async {
        guard url.scheme == "tripjournal",
              url.host == "trip",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let payload = components.queryItems?.first(where: { $0.name == "payload" })?.value
        else { return }

        // Decoding payload (Base64) to Trip
        if let data = Data(base64Encoded: payload) {
            do {
                let trip = try JSONDecoder().decode(Trip.self, from: data)
                await MainActor.run {
                    deepLinkRouter.handle(trip: trip)
                }
            } catch {
                print("Failed to decode trip: \(error)")
            }
        }
    }
}

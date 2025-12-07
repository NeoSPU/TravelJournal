// ShareTripButton.swift
// TripJournal
//
// Created by Alex Rublov on 07/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import SwiftUI

struct ShareTripButton: View {
    let trip: Trip
    
    var body: some View {
        if let url = makeTripShareURL(trip: trip) {
            ShareLink(item: url) {
                Label("Share Trip", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private func makeTripShareURL(trip: Trip) -> URL? {
        guard let encoded = try? trip.encodedForURL() else { return nil }
        return URL(string: "tripjournal://trip?payload=\(encoded)")
    }
    
}

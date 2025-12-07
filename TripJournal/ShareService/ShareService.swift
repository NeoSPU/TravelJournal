// ShareService.swift
// TripJournal
//
// Created by Alex Rublov on 07/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import Foundation

struct ShareService {
    
    func makeTripShareURL(trip: Trip) -> URL? {
        guard let encoded = try? trip.encodedForURL() else { return nil }
        return URL(string: "tripjournal://trip?payload=\(encoded)")
    }
    
}

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

            guard let encodedPayload = try? trip.encodedForURL() else { return nil }

            var components = URLComponents()
            components.scheme = "tripjournal"
            components.host = "open"
            components.path = "/trip"
            components.queryItems = [
                URLQueryItem(name: "v", value: "1"),
                URLQueryItem(name: "payload", value: encodedPayload)
            ]

            return components.url
        }
    
}

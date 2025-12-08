// Trip.swift
// TripJournal
//
// Created by Alex Rublov on 07/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import Foundation
import MapKit
import UniformTypeIdentifiers
import SwiftUI


/// Represents a trip.
struct Trip: Identifiable, Sendable, Hashable, Codable {
    var id: Int
    var name: String
    var startDate: Date
    var endDate: Date
    var events: [Event]
}

// MARK: - Extentions

extension Trip: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        // Provide JSON representation for sharing/export
        CodableRepresentation(contentType: .tripJSON)
        
        // Also provide a plain text summary as a convenience
        ProxyRepresentation(exporting: { trip in
            var lines: [String] = []
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            lines.append("Trip: \(trip.name)")
            lines.append("From: \(formatter.string(from: trip.startDate))")
            lines.append("To:   \(formatter.string(from: trip.endDate))")
            if !trip.events.isEmpty {
                lines.append("Events: \(trip.events.count)")
            }
            return lines.joined(separator: "\n")
        })
    }
}

extension Trip {
        
    func encodedForURL() throws -> String {
        let data = try JSONEncoder().encode(self)
        return data.base64EncodedString()
    }

    static func decodeFromURL(_ base64: String) throws -> Trip {
        guard let data = Data(base64Encoded: base64) else {
            throw URLError(.badURL)
        }
        return try JSONDecoder().decode(Trip.self, from: data)
    }
}


// A wrapper to share multiple trips as a single JSON file
struct TripsPackage: Transferable {
    let trips: [Trip]
    let fileName: String

    init(trips: [Trip]) {
        self.trips = trips
        // Build a meaningful filename from first/last trip names and count
        if let first = trips.first?.name, let last = trips.last?.name {
            self.fileName = "Trips_\(first)_to_\(last)_\(trips.count).json"
        } else {
            self.fileName = "Trips_\(trips.count).json"
        }
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { package in
            try JSONEncoder().encode(package.trips)
        }
        .suggestedFileName({ package in
            package.fileName
        })
    }
}

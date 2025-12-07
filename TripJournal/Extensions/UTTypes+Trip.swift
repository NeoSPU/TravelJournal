// UTTypes+Trip.swift
// TripJournal
//
// Created by Alex Rublov on 07/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import UniformTypeIdentifiers

extension UTType {
    static var tripJSON: UTType {
        UTType(importedAs: "com.rick.tripjournal.json",
               conformingTo: .json)
    }
}

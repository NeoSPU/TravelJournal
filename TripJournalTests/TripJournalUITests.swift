// TripJournalTests.swift
// TripJournal
//
// Created by Alex Rublov on 04/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import XCTest

final class TripJournalUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["UITESTS"] = "1"
        // Provide default test credentials to the app if it supports them.
        app.launchEnvironment["TEST_USERNAME"] = "test"
        app.launchEnvironment["TEST_PASSWORD"] = "123456789"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helpers
    
    func loginIfNeeded(username: String = "test", password: String = "123456789") {
        // Try to detect login screen by common identifiers
        let loginTitle = app.staticTexts["Login"]
        let usernameField = app.textFields["usernameField"].firstMatch
        let passwordField = app.secureTextFields["passwordField"].firstMatch
        let loginButton = app.buttons["loginButton"].firstMatch
        
        if loginTitle.exists || usernameField.exists || passwordField.exists || loginButton.exists {
            if usernameField.exists { usernameField.tap(); usernameField.typeText(username) }
            else if app.textFields.element(boundBy: 0).exists { let tf = app.textFields.element(boundBy: 0); tf.tap(); tf.typeText(username) }
            
            if passwordField.exists { passwordField.tap(); passwordField.typeText(password) }
            else if app.secureTextFields.element(boundBy: 0).exists { let sf = app.secureTextFields.element(boundBy: 0); sf.tap(); sf.typeText(password) }
            
            if loginButton.exists { loginButton.tap() }
            else if app.buttons["Login"].exists { app.buttons["Login"].tap() }
            else { app.keyboards.buttons["return"].tap() }
        }
        
        // Wait for trips screen to appear
        let tripsTitle = app.staticTexts["Trips"].firstMatch
        _ = tripsTitle.waitForExistence(timeout: 10)
    }
    
    func logoutIfPossible() {
        let logoutButton = app.buttons["logoutButton"].firstMatch
        if logoutButton.exists { logoutButton.tap() }
        else if app.buttons["Log out"].exists { app.buttons["Log out"].tap() }
    }
    
    func pullToRefresh(on element: XCUIElement) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let finish = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: finish)
    }
    
    // MARK: - Tests
    
    func test_01_login_and_logout_flow() {
        loginIfNeeded()
        // Verify we are on trips screen
        XCTAssertTrue(app.staticTexts["Trips"].waitForExistence(timeout: 5))
        // Open menu/profile and logout if available
        logoutIfPossible()
        // Expect to be back on login screen
        XCTAssertTrue(app.staticTexts["Login"].waitForExistence(timeout: 5))
        // Login again to continue other tests in same run
        loginIfNeeded()
    }
    
    func test_02_trips_list_interactions_add_edit_delete() {
        loginIfNeeded()
        
        let tripsList = app.tables.firstMatch
        if tripsList.waitForExistence(timeout: 5) {
            // Pull to refresh
            pullToRefresh(on: tripsList)
        }
        
        // Add new trip via plus button
        let addTripButton = app.buttons["addTripButton"].firstMatch
        if addTripButton.exists { addTripButton.tap() }
        else if app.buttons["+"] .exists { app.buttons["+"].tap() }
        else if app.navigationBars.buttons["Add"].exists { app.navigationBars.buttons["Add"].tap() }
        
        // Fill trip form
        let tripNameField = app.textFields["tripNameField"].firstMatch
        if tripNameField.waitForExistence(timeout: 3) { tripNameField.tap(); tripNameField.typeText("Amsterdam Adventure") }
        else if app.textFields.element(boundBy: 0).exists { let tf = app.textFields.element(boundBy: 0); tf.tap(); tf.typeText("Amsterdam Adventure") }
        
        // Optional: set dates if date pickers exist
        if app.datePickers.element(boundBy: 0).exists {
            // Leave default dates; UI date wheel interaction can be flaky; skip heavy manipulation
        }
        
        // Save trip
        if app.buttons["saveTripButton"].exists { app.buttons["saveTripButton"].tap() }
        else if app.buttons["Save"].exists { app.buttons["Save"].tap() }
        else if app.navigationBars.buttons["Done"].exists { app.navigationBars.buttons["Done"].tap() }
        
        // Verify new trip appears
        let newTripCell = app.cells.containing(.staticText, identifier: "Amsterdam Adventure").firstMatch
        XCTAssertTrue(newTripCell.waitForExistence(timeout: 5))
        
        // Swipe left to reveal Edit and Delete
        if newTripCell.exists {
            newTripCell.swipeLeft()
            if app.buttons["Edit"].exists { app.buttons["Edit"].tap() }
        }
        
        // Edit trip name
        if tripNameField.waitForExistence(timeout: 3) {
            tripNameField.tap()
            tripNameField.clearText()
            tripNameField.typeText("Amsterdam Adventure Updated")
        }
        
        if app.buttons["saveTripButton"].exists { app.buttons["saveTripButton"].tap() }
        else if app.buttons["Save"].exists { app.buttons["Save"].tap() }
        
        let updatedCell = app.cells.containing(.staticText, identifier: "Amsterdam Adventure Updated").firstMatch
        XCTAssertTrue(updatedCell.waitForExistence(timeout: 5))
        
        // Context menu (tap and hold)
        updatedCell.press(forDuration: 1.0)
        if app.buttons["Delete"].exists {
            // Do not delete yet; close menu if needed
            app.tap()
        }
        
        // Swipe to delete
        updatedCell.swipeLeft()
        if app.buttons["Delete"].exists { app.buttons["Delete"].tap() }
        else if app.buttons["Delete Trip"].exists { app.buttons["Delete Trip"].tap() }
        
        // Verify removed
        XCTAssertFalse(updatedCell.waitForExistence(timeout: 3))
    }
    
    func test_03_trip_timeline_events_flow() {
        loginIfNeeded()
        
        // Precondition: ensure at least one trip exists
        var anyTripCell = app.cells.firstMatch
        if !anyTripCell.waitForExistence(timeout: 3) {
            // Create one quickly
            if app.buttons["addTripButton"].exists { app.buttons["addTripButton"].tap() }
            else if app.buttons["+"].exists { app.buttons["+"].tap() }
            let tf = app.textFields.element(boundBy: 0)
            if tf.waitForExistence(timeout: 2) { tf.tap(); tf.typeText("Sample Trip") }
            if app.buttons["Save"].exists { app.buttons["Save"].tap() } else if app.navigationBars.buttons["Done"].exists { app.navigationBars.buttons["Done"].tap() }
            anyTripCell = app.cells.containing(.staticText, identifier: "Sample Trip").firstMatch
        }
        
        XCTAssertTrue(anyTripCell.waitForExistence(timeout: 5))
        anyTripCell.tap()
        
        // Timeline screen assertions
        let timelineTitle = app.staticTexts["Timeline"].firstMatch
        _ = timelineTitle.waitForExistence(timeout: 3)
        
        // Add new event
        if app.buttons["addEventButton"].exists { app.buttons["addEventButton"].tap() }
        else if app.buttons["+"] .exists { app.buttons["+"].tap() }
        
        // Fill event form: title, date, transport
        let eventTitleField = app.textFields["eventTitleField"].firstMatch
        if eventTitleField.waitForExistence(timeout: 3) {
            eventTitleField.tap(); eventTitleField.typeText("Arrived in Amsterdam")
        }
        
        // Optional: enter note
        if app.textViews.element(boundBy: 0).exists {
            let note = app.textViews.element(boundBy: 0)
            note.tap(); note.typeText("Long flight")
        }
        
        // Optional: choose transport if segmented control exists
        if app.segmentedControls.element(boundBy: 0).exists {
            let seg = app.segmentedControls.element(boundBy: 0)
            if seg.buttons["Airplane"].exists { seg.buttons["Airplane"].tap() }
        }
        
        // Location search
        if app.searchFields.firstMatch.exists {
            let search = app.searchFields.firstMatch
            search.tap(); search.typeText("Schiphol Airport Amsterdam")
            app.keyboards.buttons["search"].tap()
            // Select first result if exists
            let firstResult = app.cells.firstMatch
            if firstResult.waitForExistence(timeout: 5) { firstResult.tap() }
        }
        
        // Save event
        if app.buttons["saveEventButton"].exists { app.buttons["saveEventButton"].tap() }
        else if app.buttons["Save"].exists { app.buttons["Save"].tap() }
        
        // Verify event in timeline
        let eventCell = app.cells.containing(.staticText, identifier: "Arrived in Amsterdam").firstMatch
        XCTAssertTrue(eventCell.waitForExistence(timeout: 5))
        
        // Add image flow (placeholder)
        if app.buttons["addImageButton"].exists { app.buttons["addImageButton"].tap(); app.sheets.buttons.firstMatch.tap() }
        
        // Edit event via swipe or context menu
        eventCell.swipeLeft()
        if app.buttons["Edit"].exists { app.buttons["Edit"].tap() }
        if eventTitleField.waitForExistence(timeout: 3) {
            eventTitleField.tap(); eventTitleField.clearText(); eventTitleField.typeText("Canal tour")
        }
        if app.buttons["Save"].exists { app.buttons["Save"].tap() }
        
        let updatedEventCell = app.cells.containing(.staticText, identifier: "Canal tour").firstMatch
        XCTAssertTrue(updatedEventCell.waitForExistence(timeout: 5))
        
        // Delete event
        updatedEventCell.swipeLeft()
        if app.buttons["Delete"].exists { app.buttons["Delete"].tap() }
        XCTAssertFalse(updatedEventCell.waitForExistence(timeout: 3))
        
        // If no events remain, verify placeholder
        let placeholder = app.staticTexts["No events yet"].firstMatch
        _ = placeholder.exists // non-fatal check
    }
}

// MARK: - XCUIElement helpers
private extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        // Select all and delete
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
    
}

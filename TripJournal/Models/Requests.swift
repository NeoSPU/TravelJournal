import Foundation

/// An object that can be used to create a new trip.
struct TripCreate: Encodable {
    let name: String
    let startDate: Date
    let endDate: Date

    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

/// An object that can be used to update an existing trip.
struct TripUpdate: Encodable {
    let name: String
    let startDate: Date
    let endDate: Date

    enum CodingKeys: String, CodingKey {
        case name
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

/// An object that can be used to create a media.
struct MediaCreate: Encodable {
    let eventId: Event.ID
    // If the backend expects base64 string, store as String; if raw Data is acceptable and encoder handles it, keep Data.
    // We'll encode as base64 string explicitly to be safe.
    let base64Data: String

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case base64Data = "base64_data"
    }
}

/// An object that can be used to create a new event.
struct EventCreate: Encodable {
    let tripId: Trip.ID
    let name: String
    let note: String?
    let date: Date
    let location: Location?
    let transitionFromPrevious: String?

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case name
        case note
        case date
        case location
        case transitionFromPrevious = "transition_from_previous"
    }
}

/// An object that can be used to update an existing event.
struct EventUpdate: Encodable {
    var name: String
    var note: String?
    var date: Date
    var location: Location?
    var transitionFromPrevious: String?

    enum CodingKeys: String, CodingKey {
        case name
        case note
        case date
        case location
        case transitionFromPrevious = "transition_from_previous"
    }
}

///// An object that can be used to create a new trip.
//struct TripCreate: Encodable {
//    let name: String
//    let startDate: Date
//    let endDate: Date
//
//    enum CodingKeys: String, CodingKey {
//        case name
//        case startDate = "start_date"
//        case endDate = "end_date"
//    }
//}
//
///// An object that can be used to update an existing trip.
//struct TripUpdate {
//    let name: String
//    let startDate: Date
//    let endDate: Date
//}
//
///// An object that can be used to create a media.
//struct MediaCreate {
//    let eventId: Event.ID
//    let base64Data: Data
//}
//
///// An object that can be used to create a new event.
//struct EventCreate {
//    let tripId: Trip.ID
//    let name: String
//    let note: String?
//    let date: Date
//    let location: Location?
//    let transitionFromPrevious: String?
//}
//
///// An object that can be used to update an existing event.
//struct EventUpdate {
//    var name: String
//    var note: String?
//    var date: Date
//    var location: Location?
//    var transitionFromPrevious: String?
//}

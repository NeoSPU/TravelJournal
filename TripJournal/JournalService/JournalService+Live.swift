// JournalService+Live.swift
// TripJournal
//
// Created by Alex Rublov on 04/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import Combine
import Foundation

private extension JSONEncoder.DateEncodingStrategy {
    static var iso8601WithFractionalSeconds: JSONEncoder.DateEncodingStrategy {
        return .custom { (date, encoder) in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let string = formatter.string(from: date)
            try container.encode(string)
        }
    }
}

enum HTTPMethods: String {
    case POST
}

enum MIMEType: String {
    case JSON = "application/json"
    case form = "application/x-www-form-urlencoded"
}

enum HTTPHeaders: String {
    case accept
    case contentType = "Content-Type"
    case authorization = "Authorization"
}

enum NetworkError: Error {
    case badUrl
    case badResponse
    case failedToDecodeResponse
    case failedGetTrip
    case failedUpdateTrip
    case failedCreateEvent
    case failedUpdateEvent
    case failedDeleteEvent
    case failedCreateMedia
    case failedDeleteMedia
}

enum EndPoints {
    static let base = "http://localhost:8000/"
    
    case register
    case login
    case trips
    case events
    case media
    
    private var stringValue: String {
        switch self {
        case .register:
            return EndPoints.base + "register"
        case .login:
            return EndPoints.base + "token"
        case .trips:
            return EndPoints.base + "trips"
        case .events:
            return EndPoints.base + "events"
        case .media:
            return EndPoints.base + "media"
        }
    }
    
    var url: URL? {
        return URL(string: stringValue)
    }
}

class JournalServiceLive: JournalService {
    
    //    private struct MockError: Error {}
    
    init(delay: TimeInterval = 0) {
        self.delay = delay
    }
    
    private let delay: TimeInterval
    //    private var trips = Trip.sample
    
    @Published private var token: Token?
    
    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    /// Create a new account.
    /// - Parameters:
    ///   - username: Username.
    ///   - password: Password.
    /// - Returns: A token that can be used to interact with the API.
    @discardableResult
    func register(username: String, password: String) async throws -> Token {
        guard let url = EndPoints.register.url else {
            throw NetworkError.badUrl
        }
        
        let registerRequest = LoginRequest(username: username, password: password)
        
        var request = URLRequest(url: url)
        
        request.httpMethod = HTTPMethods.POST.rawValue
        
        // Add necessary HTTP headers
        request.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        request.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        
        do {
            request.httpBody = try JSONEncoder().encode(registerRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Throw NetworkError badResponse
                throw NetworkError.badResponse
            }
            
            do {
                // Decode token from response data and asint to token property
                let token = try JSONDecoder().decode(Token.self, from: data)
                self.token = token
                return token
            } catch {
                // Throw failedToDecodeResponse NetworkError
                throw NetworkError.failedToDecodeResponse
            }
        } catch {
            // Throw badResponse NetworkError
            throw NetworkError.badResponse
        }
    }
    
    /// Login to an existing account.
    /// - Parameters:
    ///   - username: Username.
    ///   - password: Password.
    /// - Returns: A token that can be used to interact with the API.
    @discardableResult
    func logIn(username: String, password: String) async throws -> Token {
        guard let url = EndPoints.login.url else {
            throw NetworkError.badUrl
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = HTTPMethods.POST.rawValue
        
        // Add necessary HTTP headers
        request.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        request.addValue(MIMEType.form.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        
        let loginData = "grant_type=&username=\(username)&password=\(password)"
        request.httpBody = loginData.data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Throw NetworkError badResponse
                throw NetworkError.badResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                // Throw badResponse NetworkError
                throw NetworkError.badResponse
            }
            
            do {
                // Decode token from response data and asignt to token variable and return token
                let token = try JSONDecoder().decode(Token.self, from: data)
                self.token = token
                return token
            } catch {
                // Throw failedToDecodeResponse NetworkError
                throw NetworkError.failedToDecodeResponse
            }
        } catch {
            // Throw badResponse NetworkError
            throw NetworkError.badResponse
        }
    }
    
    /// Log-outs the user, by deleting the token and updating the isAuthenticated publisher.
    func logOut() {
        token = nil
    }
    
    /// Creates a new trip.
    /// - Parameter request: Trip creation request.
    /// - Returns: Created trip.
    @discardableResult
    func createTrip(with request: TripCreate) async throws -> Trip {
        
        guard let url = EndPoints.trips.url else {
            throw NetworkError.badUrl
        }
        
        guard let accessToken = token?.accessToken else {
            throw NetworkError.badResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethods.POST.rawValue
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: HTTPHeaders.authorization.rawValue)
        
        let encoder = JSONEncoder()
        if #available(iOS 15.0, macOS 12.0, *) {
            encoder.dateEncodingStrategy = .iso8601WithFractionalSeconds
        } else {
            // Fallback: standard ISO8601 (may omit fractional seconds)
            encoder.dateEncodingStrategy = .iso8601
        }
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.badResponse
            }
            do {
                let trip = try JSONDecoder().decode(Trip.self, from: data)
                return trip
            } catch {
                throw NetworkError.failedToDecodeResponse
            }
        } catch {
            throw NetworkError.badResponse
        }
    }
    
    /// Get all trips.
    /// - Returns: All trips.
    @discardableResult
    func getTrips() async throws -> [Trip] {
        //        try await Task.sleep(for: .seconds(delay))
        //        return trips
        throw NetworkError.failedUpdateEvent
        
    }
    
    /// Get a trip with a given id.
    /// - Parameter tripId: Trip id.
    /// - Returns: Trip.
    @discardableResult
    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        //        try await Task.sleep(for: .seconds(delay))
        //        guard let trip = trips.first(where: { $0.id == tripId }) else {
        //            throw NetworkError.failedGetTrip
        //        }
        //        return trip
        throw NetworkError.failedUpdateEvent
        
    }
    
    /// Updates a trip.
    /// - Parameter request: Trip update request.
    /// - Returns: Updated trip.
    @discardableResult
    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        //        try await Task.sleep(for: .seconds(delay))
        //        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else {
        //            throw NetworkError.failedUpdateTrip
        //        }
        //        trips[tripIndex].update(from: request)
        //        trips.sort()
        //        return trips[tripIndex]
        throw NetworkError.failedUpdateEvent
        
    }
    
    /// Delete a trip with a given id.
    /// - Parameter tripId: Trip id.
    func deleteTrip(withId tripId: Trip.ID) async throws {
        //        try await Task.sleep(for: .seconds(delay))
        //        trips.removeAll(where: { $0.id == tripId })
        throw NetworkError.failedUpdateEvent
        
    }
    
    /// Create an event.
    /// - Parameter request: Event creation request.
    /// - Returns: Created event.
    @discardableResult
    func createEvent(with request: EventCreate) async throws -> Event {
        //        try await Task.sleep(for: .seconds(delay))
        //        guard let tripIndex = trips.firstIndex(where: { $0.id == request.tripId }) else {
        //            throw NetworkError.failedCreateEvent
        //        }
        //        var events = trips[tripIndex].events
        //        let newEvent = Event(from: request)
        //        events.append(newEvent)
        //        trips[tripIndex].events = events
        //        trips[tripIndex].events.sort()
        //        return newEvent
        throw NetworkError.failedUpdateEvent
        
    }
    
    /// Updates an event.
    /// - Parameter request: Event update request.
    /// - Returns: Updated event.
    @discardableResult
    func updateEvent(withId eventId: Event.ID, and request: EventUpdate) async throws -> Event {
        //        try await Task.sleep(for: .seconds(delay))
        //        for tripIndex in trips.indices {
        //            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId {
        //                trips[tripIndex].events[eventIndex].update(from: request)
        //                trips[tripIndex].events.sort()
        //                return trips[tripIndex].events[eventIndex]
        //            }
        //        }
        throw NetworkError.failedUpdateEvent
    }
    
    /// Delete an event with a given id.
    /// - Parameter eventId: Event id.
    func deleteEvent(withId eventId: Event.ID) async throws {
        //        try await Task.sleep(for: .seconds(delay))
        //        for tripIndex in trips.indices {
        //            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == eventId {
        //                trips[tripIndex].events.remove(at: eventIndex)
        //                return
        //            }
        //        }
        throw NetworkError.failedDeleteEvent
    }
    
    /// Create a media.
    /// - Parameter request: Media creation request.
    /// - Returns: Created media.
    @discardableResult
    func createMedia(with request: MediaCreate) async throws -> Media {
        //        try await Task.sleep(for: .seconds(delay))
        //        for tripIndex in trips.indices {
        //            for (eventIndex, event) in trips[tripIndex].events.enumerated() where event.id == request.eventId {
        //                let newMedia = Media(from: request)
        //                trips[tripIndex].events[eventIndex].medias.append(newMedia)
        //                return newMedia
        //            }
        //        }
        throw NetworkError.failedCreateMedia
    }
    
    /// Delete a media with a given id.
    /// - Parameter mediaId: Media id.
    func deleteMedia(withId mediaId: Media.ID) async throws {
        //        try await Task.sleep(for: .seconds(delay))
        //        for tripIndex in trips.indices {
        //            for eventIndex in trips[tripIndex].events.indices {
        //                for (mediaIndex, media) in trips[tripIndex].events[eventIndex].medias.enumerated() where media.id == mediaId {
        //                    trips[tripIndex].events[eventIndex].medias.remove(at: mediaIndex)
        //                    return
        //                }
        //            }
        //        }
        throw NetworkError.failedDeleteMedia
    }
}
//
//extension Event {
//    init(from create: EventCreate) {
//        id = Int.random(in: 0 ... 1000)
//        name = create.name
//        note = create.note
//        date = create.date
//        location = create.location
//        medias = []
//        transitionFromPrevious = create.transitionFromPrevious
//    }
//
//    mutating func update(from update: EventUpdate) {
//        name = update.name
//        note = update.note
//        date = update.date
//        location = update.location
//        transitionFromPrevious = update.transitionFromPrevious
//    }
//
//    static let amsterdam: [Self] = [
//        .init(
//            id: 1,
//            name: "Canal Tour",
//            note: nil,
//            date: Date(day: 1, month: 6, year: 2024),
//            location: .init(latitude: 52.3676, longitude: 4.9041, address: "Amsterdam"),
//            medias: [
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Walk from Hotel"
//        ),
//        .init(
//            id: 2,
//            name: "Visit to the Van Gogh Museum",
//            note: "A vivid, unforgettable art experience...",
//            date: Date(day: 2, month: 6, year: 2024),
//            location: .init(latitude: 52.3584, longitude: 4.8811, address: "Museumplein, Amsterdam"),
//            medias: [
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Tram ride from hotel"
//        ),
//        .init(
//            id: 3,
//            name: "Lunch",
//            note: "The best pizza ever!",
//            date: Date(day: 3, month: 6, year: 2024),
//            location: nil,
//            medias: [],
//            transitionFromPrevious: nil
//        ),
//        .init(
//            id: 4,
//            name: "Evening at Dam Square",
//            note: nil,
//            date: Date(day: 4, month: 6, year: 2024),
//            location: .init(latitude: 52.3731, longitude: 4.8936, address: "Dam Square, Amsterdam"),
//            medias: [
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Walk from the Jordaan neighborhood"
//        ),
//    ]
//
//    static let rome: [Self] = [
//        .init(
//            id: 3,
//            name: "Colosseum Tour",
//            note: nil,
//            date: Date(day: 10, month: 7, year: 2024),
//            location: .init(latitude: 41.8902, longitude: 12.4922, address: "Rome"),
//            medias: [
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Arrival in Rome"
//        ),
//        .init(
//            id: 4,
//            name: "Vatican Visit",
//            note: nil,
//            date: Date(day: 12, month: 7, year: 2024),
//            location: .init(latitude: 41.9029, longitude: 12.4534, address: "Vatican City"),
//            medias: [
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Metro from Rome"
//        ),
//    ]
//
//    static let tokyo: [Self] = [
//        .init(
//            id: 5,
//            name: "Shinjuku Exploration",
//            note: nil,
//            date: Date(day: 20, month: 8, year: 2024),
//            location: .init(latitude: 35.6895, longitude: 139.6917, address: "Tokyo"),
//            medias: [.init(id: 5, url: URL(string: "https://picsum.photos/id/1/640/360"))],
//            transitionFromPrevious: "Arrival at Haneda Airport"
//        ),
//        .init(
//            id: 6,
//            name: "Sushi Tasting",
//            note: nil,
//            date: Date(day: 22, month: 8, year: 2024),
//            location: .init(latitude: 35.6895, longitude: 139.6917, address: "Tokyo"),
//            medias: [
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Walk through Tsukiji"
//        ),
//    ]
//
//    static let paris: [Self] = [
//        .init(
//            id: 7,
//            name: "Eiffel Tower Visit",
//            note: nil,
//            date: Date(day: 5, month: 9, year: 2024),
//            location: .init(latitude: 48.8584, longitude: 2.2945, address: "Paris"),
//            medias: [
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//                .randomPlaceholder(),
//            ],
//            transitionFromPrevious: "Arrival at Charles de Gaulle"
//        ),
//        .init(
//            id: 8,
//            name: "Louvre Museum Tour",
//            note: nil,
//            date: Date(day: 7, month: 9, year: 2024),
//            location: nil,
//            medias: [],
//            transitionFromPrevious: "Metro ride from hotel"
//        ),
//    ]
//}
//
//extension Media {
//    static func randomPlaceholder() -> Self {
//        let id = Int.random(in: 0 ... 1000)
//        return Self(id: id, url: URL(string: "https://picsum.photos/id/\(id)/640/360"))
//    }
//}
//
//extension Trip {
//    init(from create: TripCreate) {
//        id = Int.random(in: 0 ... 1000)
//        name = create.name
//        startDate = create.startDate
//        endDate = create.endDate
//        events = []
//    }
//
//    mutating func update(from update: TripUpdate) {
//        name = update.name
//        startDate = update.startDate
//        endDate = update.endDate
//    }
//
//    static let sample: [Self] = {
//        let amsterdamAdventure = Trip(
//            id: 1,
//            name: "Amsterdam Adventure",
//            startDate: Date(day: 1, month: 6, year: 2024),
//            endDate: Date(day: 5, month: 6, year: 2024),
//            events: Event.amsterdam
//        )
//
//        let romeRetreat = Trip(
//            id: 2,
//            name: "Rome Retreat",
//            startDate: Date(day: 10, month: 7, year: 2024),
//            endDate: Date(day: 15, month: 7, year: 2024),
//            events: Event.rome
//        )
//
//        let tokyoTour = Trip(
//            id: 3,
//            name: "Tokyo Tour",
//            startDate: Date(day: 20, month: 8, year: 2024),
//            endDate: Date(day: 25, month: 8, year: 2024),
//            events: Event.tokyo
//        )
//
//        let parisPilgrimage = Trip(
//            id: 4,
//            name: "Paris Pilgrimage",
//            startDate: Date(day: 5, month: 9, year: 2024),
//            endDate: Date(day: 10, month: 9, year: 2024),
//            events: Event.paris
//        )
//
//        return [amsterdamAdventure, romeRetreat, tokyoTour, parisPilgrimage]
//    }()
//}
//
//extension Media {
//    init(from _: MediaCreate) {
//        self = .randomPlaceholder()
//    }
//}

extension Trip: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.startDate < rhs.startDate
    }
}

extension Event: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.date < rhs.date
    }
}

private extension Date {
    init(day: Int, month: Int, year: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        
        guard let date = Calendar.current.date(from: dateComponents) else {
            fatalError("Invalid date components: \(year)-\(month)-\(day)")
        }
        self = date
    }
}


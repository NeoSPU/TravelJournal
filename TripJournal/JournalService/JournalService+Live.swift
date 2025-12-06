// JournalService+Live.swift
// TripJournal
//
// Created by Alex Rublov on 04/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import Combine
import Foundation

class JournalServiceLive: JournalService {
    private let session: URLSession
    private let delay: TimeInterval
    @Published private var token: Token?

    var isAuthenticated: AnyPublisher<Bool, Never> {
        $token
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    init(delay: TimeInterval = 0, session: URLSession = .shared) {
        self.delay = delay
        self.session = session
    }
    
    //=================================================================================
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
            
            let (data, response) = try await session.data(for: request)
            
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
    
    //=================================================================================
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
            let (data, response) = try await session.data(for: request)
            
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
    
    //=================================================================================
    /// Log-outs the user, by deleting the token and updating the isAuthenticated publisher.
    func logOut() {
        token = nil
    }
    
    //=================================================================================
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
            let (data, response) = try await session.data(for: urlRequest)
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
    
    //=================================================================================
    /// Get all trips.
    /// - Returns: All trips.
    @discardableResult
    func getTrips() async throws -> [Trip] {
        guard let url = EndPoints.trips.url else {
            throw NetworkError.badUrl
        }
        
        guard let accessToken = token?.accessToken else {
            throw NetworkError.badAccessToken
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethods.GET.rawValue
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: HTTPHeaders.authorization.rawValue)
        
        do {
            let (data, responce) = try await session.data(for: urlRequest)
            guard let httpResponce = responce as? HTTPURLResponse, (200...299).contains(httpResponce.statusCode) else {
                throw NetworkError.badResponse
            }
            do {
                let trips = try NetworkCoding.decoder.decode([Trip].self, from: data)
                return trips
            } catch {
                throw NetworkError.failedToDecodeResponse
            }
        } catch {
            throw NetworkError.failedGetTrip
        }
        
    }
    
    //=================================================================================
    /// Get a trip with a given id.
    /// - Parameter tripId: Trip id.
    /// - Returns: Trip.
    @discardableResult
    func getTrip(withId tripId: Trip.ID) async throws -> Trip {
        guard let url = EndPoints.trip(id: tripId) else {
            throw NetworkError.badUrl
        }
        
        guard let accessToken = token?.accessToken else {
            throw NetworkError.badAccessToken
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethods.GET.rawValue
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: HTTPHeaders.authorization.rawValue)
        
        do {
            let (data, responce) = try await session.data(for: urlRequest)
            guard let httpResponce = responce as? HTTPURLResponse, (200...299).contains(httpResponce.statusCode) else {
                throw NetworkError.badResponse
            }
            do {
                let trip = try NetworkCoding.decoder.decode(Trip.self, from: data)
                return trip
            } catch {
                throw NetworkError.failedToDecodeResponse
            }
            
        } catch {
            throw NetworkError.failedGetTrip
        }
    }
    
    //=================================================================================
    /// Updates a trip.
    /// - Parameter request: Trip update request.
    /// - Returns: Updated trip.
    @discardableResult
    func updateTrip(withId tripId: Trip.ID, and request: TripUpdate) async throws -> Trip {
        guard let url = EndPoints.trip(id: tripId) else {
            throw NetworkError.badUrl
        }
        
        guard let accessToken = token?.accessToken else {
            throw NetworkError.badAccessToken
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethods.PUT.rawValue
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        urlRequest.addValue(MIMEType.JSON.rawValue, forHTTPHeaderField: HTTPHeaders.contentType.rawValue)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: HTTPHeaders.authorization.rawValue)
        
        urlRequest.httpBody = try NetworkCoding.encoder.encode(request)
        
        do {
            let (data, responce) = try await session.data(for: urlRequest)
            guard let httpResponce = responce as? HTTPURLResponse, (200...299).contains(httpResponce.statusCode) else {
                throw NetworkError.badResponse
            }
            do {
                let trip = try NetworkCoding.decoder.decode(Trip.self, from: data)
                return trip
            } catch {
                throw NetworkError.failedToDecodeResponse
            }
        } catch {
            throw NetworkError.failedUpdateTrip
        }
        
    }
    
    //=================================================================================
    /// Delete a trip with a given id.
    /// - Parameter tripId: Trip id.
    func deleteTrip(withId tripId: Trip.ID) async throws {
        guard let url = EndPoints.trip(id: tripId) else {
            throw NetworkError.badUrl
        }
        
        guard let accessToken = token?.accessToken else {
            throw NetworkError.badAccessToken
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethods.DELETE.rawValue
        urlRequest.addValue("*/*", forHTTPHeaderField: HTTPHeaders.accept.rawValue)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: HTTPHeaders.authorization.rawValue)
                
        do {
            let (_, responce) = try await session.data(for: urlRequest)
            guard let httpResponce = responce as? HTTPURLResponse, (200...299).contains(httpResponce.statusCode) else {
                throw NetworkError.badResponse
            }
        } catch {
            throw NetworkError.failedDeleteTrip
        }
        
    }
    
    //=================================================================================
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
    
    //=================================================================================
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
    
    //=================================================================================
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
    
    //=================================================================================
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
    
    //=================================================================================
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
//=================================================================================
// MARK: - Networking
//=================================================================================

enum HTTPMethods: String {
    case POST
    case GET
    case PUT
    case DELETE
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
    case badAccessToken
    case failedToDecodeResponse
    case failedGetTrip
    case failedUpdateTrip
    case failedDeleteTrip
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
    
    static func trip(id: Int) -> URL? { URL(string: EndPoints.base + "trips/\(id)") }
    static func event(id: Int) -> URL? { URL(string: EndPoints.base + "events/\(id)") }
    static func media(id: Int) -> URL? { URL(string: EndPoints.base + "media/\(id)") }
}

enum NetworkCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        if #available(iOS 15.0, macOS 12.0, *) {
            encoder.dateEncodingStrategy = .iso8601WithFractionalSeconds
        } else {
            // Fallback: standard ISO8601 (may omit fractional seconds)
            encoder.dateEncodingStrategy = .iso8601
        }
        // encoder.keyEncodingStrategy = .convertToSnakeCase // if API in snake_case
        return encoder
    }()
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // or a server-agreed strategy
        // decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

//=================================================================================
// MARK: - Private Extensions
//=================================================================================

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


//
//  WeatherAPIClient.swift
//  TCASampleSearch
//
//  Created by Masahito Mori on 2024/06/01.
//

import Foundation
import ComposableArchitecture

struct GeocodingSearch: Decodable, Equatable, Sendable {
    var results: [Result]
    
    struct Result: Decodable, Equatable, Identifiable, Sendable {
        var country: String
        var latitude: Double
        var longitude: Double
        var id: Int
        var name: String
        var admin1: String?
    }
}

struct Forecast: Decodable, Equatable, Sendable {
    var daily: Daily
    var dailyUnits: DailyUnits
    
    struct Daily: Decodable, Equatable, Sendable {
        var temperatureMax: [Double]
        var temperatureMin: [Double]
        var time: [Date]
    }
    
    struct DailyUnits: Decodable, Equatable, Sendable {
        var temperatureMax: String
        var temperatureMin: String
    }
}

@DependencyClient
struct WeatherAPIClient {
    var forecast: @Sendable (_ location: GeocodingSearch.Result) async throws -> Forecast
    var search: @Sendable (_ query: String) async throws -> GeocodingSearch
}

extension WeatherAPIClient: TestDependencyKey {
    static let previewValue = Self(
        forecast: { _ in .mock },
        search: { _ in .mock }
    )
    
    static let testValue = Self()
}

extension DependencyValues {
    var weatherAPIClient: WeatherAPIClient {
        get { self[WeatherAPIClient.self] }
        set { self[WeatherAPIClient.self] = newValue }
    }
}

extension WeatherAPIClient: DependencyKey {
    static var liveValue = Self(
        forecast: { result in
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                URLQueryItem(name: "latitude", value: "\(result.latitude)"),
                URLQueryItem(name: "longitude", value: "\(result.longitude)"),
                URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
                URLQueryItem(name: "timezone", value: "Asia/Tokyo"),
            ]
            
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try jsonDecoder.decode(Forecast.self, from: data)
        },
        search: { query in
            var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
            components.queryItems = [URLQueryItem(name: "name", value: query)]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            return try jsonDecoder.decode(GeocodingSearch.self, from: data)
        }
    )
}



private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
}()


extension Forecast {
  private enum CodingKeys: String, CodingKey {
    case daily
    case dailyUnits = "daily_units"
  }
}

extension Forecast.Daily {
  private enum CodingKeys: String, CodingKey {
    case temperatureMax = "temperature_2m_max"
    case temperatureMin = "temperature_2m_min"
    case time
  }
}

extension Forecast.DailyUnits {
  private enum CodingKeys: String, CodingKey {
    case temperatureMax = "temperature_2m_max"
    case temperatureMin = "temperature_2m_min"
  }
}

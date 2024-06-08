//
//  GeocodingSearch.swift
//  TCASampleSearch
//
//  Created by Masahito Mori on 2024/06/01.
//

extension GeocodingSearch {
  static let mock = Self(
    results: [
      GeocodingSearch.Result(
        country: "United States",
        latitude: 40.6782,
        longitude: -73.9442,
        id: 1,
        name: "Brooklyn",
        admin1: nil
      ),
      GeocodingSearch.Result(
        country: "United States",
        latitude: 34.0522,
        longitude: -118.2437,
        id: 2,
        name: "Los Angeles",
        admin1: nil
      ),
      GeocodingSearch.Result(
        country: "United States",
        latitude: 37.7749,
        longitude: -122.4194,
        id: 3,
        name: "San Francisco",
        admin1: nil
      ),
    ]
  )
}

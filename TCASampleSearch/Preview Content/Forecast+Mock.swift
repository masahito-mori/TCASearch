//
//  Forecast+Mock.swift
//  TCASampleSearch
//
//  Created by Masahito Mori on 2024/06/01.
//
import Foundation

extension Forecast {
  static let mock = Self(
    daily: Daily(
      temperatureMax: [90, 70, 100],
      temperatureMin: [70, 50, 80],
      time: [0, 86_400, 172_800].map(Date.init(timeIntervalSince1970:))
    ),
    dailyUnits: DailyUnits(temperatureMax: "°F", temperatureMin: "°F")
  )
}

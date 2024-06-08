//
//  SearchView.swift
//  TCASampleSearch
//
//  Created by Masahito Mori on 2024/06/01.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct SearchFeature {
    @ObservableState
    struct State: Equatable {
        var results: [GeocodingSearch.Result] = []
        var searchQuery = ""
        var resultForecastRequestInFlight: GeocodingSearch.Result?
        var weather: Weather?
        struct Weather: Equatable {
            var id: GeocodingSearch.Result.ID
            var days: [Day]
            
            struct Day: Equatable {
                var date: Date
                var temperatureMax: Double
                var temperatureMaxUnit: String
                var temperatureMin: Double
                var temperatureMinUnit: String
            }
        }
    }
    
    enum Action {
        case searchQueryChanged(String)
        case searchQueryChangeDebounced
        case searchResponse(Result<GeocodingSearch, Error>)
        case searchResultTapped(GeocodingSearch.Result)
        case forecastResponse(GeocodingSearch.Result.ID, Result<Forecast, Error>)
    }
    
    @Dependency(\.weatherAPIClient) var weatherAPIClient
    private enum CancelID { case location, weather }
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .searchQueryChanged(query):
                state.searchQuery = query
                guard !state.searchQuery.isEmpty else {
                    state.results = []
                    state.weather = nil
                    return .none
                }
                return .none
            case .searchQueryChangeDebounced:
                guard !state.searchQuery.isEmpty else { return .none }
                return .run { [query = state.searchQuery] send in
                    await send(.searchResponse(Result { try await self.weatherAPIClient.search(query: query) }))
                }
                .cancellable(id: CancelID.location)
            case let .searchResponse(.success(response)):
                state.results = response.results
                return .none
            case .searchResponse(.failure):
                state.results = []
                return .none
            case let .searchResultTapped(location):
                state.resultForecastRequestInFlight = location
                return .run { send in
                    await send(
                        .forecastResponse(
                            location.id,
                            Result { try await self.weatherAPIClient.forecast(location: location) }
                        )
                    )
                }
                .cancellable(id: CancelID.weather, cancelInFlight: true)
            case let .forecastResponse(id, .success(forecast)):
                state.weather = State.Weather(
                    id: id,
                    days: forecast.daily.time.indices.map {
                        State.Weather.Day(
                            date: forecast.daily.time[$0],
                            temperatureMax: forecast.daily.temperatureMax[$0],
                            temperatureMaxUnit: forecast.dailyUnits.temperatureMax,
                            temperatureMin: forecast.daily.temperatureMin[$0],
                            temperatureMinUnit: forecast.dailyUnits.temperatureMin
                        )
                    }
                )
                state.resultForecastRequestInFlight = nil
                return .none
            case .forecastResponse(_, .failure):
                state.resultForecastRequestInFlight = nil
                return .none
            }
        }
    }
}

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("tokyo", text: $store.searchQuery.sending(\.searchQueryChanged))
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 16)
                
                List {
                    ForEach(store.results) { location in
                        VStack(alignment: .leading) {
                            Button {
                                store.send(.searchResultTapped(location))
                            } label: {
                                Text(location.name)
                            }
                            
                            if store.resultForecastRequestInFlight?.id == location.id {
                                ProgressView()
                            }
                            
                            if location.id == store.weather?.id {
                                weatherView(locationWeather: store.weather)
                            }
                        }
                    }
                }
                Button("Weather API provided by Open-Meteo") {
                    UIApplication.shared.open(URL(string: "https://open-meteo.com/en")!)
                }
                .foregroundColor(.gray)
                .padding(.all, 16)
            }
            .navigationTitle("Search")
        }
        .task(id: store.searchQuery) {
            do {
                try await Task.sleep(for: .milliseconds(300))
                await store.send(.searchQueryChangeDebounced).finish()
            } catch {}
        }
    }
    
    @ViewBuilder
    func weatherView(locationWeather: SearchFeature.State.Weather?) -> some View {
        if let locationWeather {
            let days = locationWeather.days
                .enumerated()
                .map{ idx, weather in formattedWeather(day: weather, isToday: idx == 0) }
            VStack(alignment: .leading) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                }
            }
            .padding(.leading, 16)
        }
    }
    
    private func formattedWeather(day: SearchFeature.State.Weather.Day, isToday: Bool) -> String {
        let date = isToday ? "Today" : dateFormatter.string(from: day.date).capitalized
        let min = "\(day.temperatureMin)\(day.temperatureMaxUnit)"
        let max = "\(day.temperatureMin)\(day.temperatureMaxUnit)"
        
        return "\(date), \(min) - \(max)"
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}


#Preview {
    SearchView(store: Store(initialState: SearchFeature.State()) {
        
    }
    )
}

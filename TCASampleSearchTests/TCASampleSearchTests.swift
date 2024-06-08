//
//  TCASampleSearchTests.swift
//  TCASampleSearchTests
//
//  Created by Masahito Mori on 2024/06/08.
//

import ComposableArchitecture
import XCTest

@testable import TCASampleSearch

final class TCASampleSearchTests: XCTestCase {
    @MainActor
    func testSearchAndClearQuery() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.weatherAPIClient.search = { @Sendable _ in .mock}
        }
        
        await store.send(.searchQueryChanged("S")) {
            $0.searchQuery = "S"
        }
        
        await store.send(.searchQueryChangeDebounced)
        await store.receive(\.searchResponse.success) {
            $0.results = GeocodingSearch.mock.results
        }
        
        await store.send(.searchQueryChanged("")) {
            $0.results = []
            $0.searchQuery = ""
        }
    }
    
    @MainActor
    func testSearchFailure() async {
        let store = TestStore(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.weatherAPIClient.search = { @Sendable _ in
                struct SomethingWentWrong: Error {}
                throw SomethingWentWrong()
            }
        }
        
        await store.send(.searchQueryChanged("S")) {
            $0.searchQuery = "S"
        }
        
        await store.send(.searchQueryChangeDebounced)
        await store.receive(\.searchResponse.failure)
    }
}

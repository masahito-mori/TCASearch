//
//  TCASampleSearchApp.swift
//  TCASampleSearch
//
//  Created by Masahito Mori on 2024/06/01.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCASampleSearchApp: App {
    static let store = Store(initialState: SearchFeature.State()) {
        SearchFeature()
          ._printChanges()
      }
    
    var body: some Scene {
        WindowGroup {
            SearchView(store: Self.store)
        }
    }
}

//
//  AVExperimentsApp.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import SwiftUI
import ComposableArchitecture

@main
struct AVExperimentsApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(
        store: Store(
          initialState: RootState(),
          reducer: rootReducer,
          environment: .live()))
    }
  }
}

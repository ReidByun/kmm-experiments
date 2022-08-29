//
//  RootView.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import SwiftUI
import ComposableArchitecture

struct RootView: View {
  let store: Store<RootState, RootAction>
  
  var body: some View {
    WithViewStore(self.store.stateless) { _ in
      ScrubbingPlayerView (
        store: store.scope(
          state: \.scrubbingPlayerState,
          action: RootAction.scrubbingPlayerAction))
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static var previews: some View {
    let rootView = RootView(
      store: Store(
        initialState: RootState(),
        reducer: rootReducer,
        environment: .dev()))
    return rootView
  }
}

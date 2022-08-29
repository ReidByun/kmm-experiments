//
//  AudioPlayerClient.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import ComposableArchitecture
import Foundation

struct AudioPlayerClient {
  var setSession: ()->()
  var openUrl: (URL) -> Effect<ScrubbingPlayerModel, APIError>
  var play: () -> Effect<Action, Failure>
  //    var play: () -> Effect<Never, Never>
  var pause: () -> Effect<Never, Never>
  
  enum Action: Equatable {
    case didFinishPlaying(successfully: Bool)
  }
  
  enum Failure: Equatable, Error {
    case couldntCreateAudioPlayer
    case decodeErrorDidOccur
  }
}


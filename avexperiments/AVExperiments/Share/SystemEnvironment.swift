//
//  SystemEnvironment.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import ComposableArchitecture
import Dispatch

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
  var environment: Environment
  
  subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }
  
  var mainQueue: () -> AnySchedulerOf<DispatchQueue>
  var audioPlayer: AudioEngineClient
  var genScrubbingSourceNode: GenScrubbingSourceNode
  
  static func live(environment: Environment) -> Self {
    //print("SystemEnvironment init live without player ttt")
    return Self(environment: environment, mainQueue: { .main }, audioPlayer: .livePlayerClient, genScrubbingSourceNode: .live())
  }
  
  static func live(environment: Environment, audioPlayer: AudioEngineClient) -> Self {
    //print("SystemEnvironment init live ttt")
    return Self(environment: environment, mainQueue: { .main }, audioPlayer: audioPlayer, genScrubbingSourceNode: .live())
  }
  
  static func dev(environment: Environment, audioPlayer: AudioEngineClient) -> Self {
    Self(environment: environment, mainQueue: { .main }, audioPlayer: audioPlayer, genScrubbingSourceNode: .live())
  }
}

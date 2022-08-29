//
//  ScrubbingPlayerFeature.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import Foundation

import Combine
import ComposableArchitecture
import AVFoundation
import SwiftUI

struct ScrubbingPlayerState: Equatable {
  var playerInfo: ScrubbingPlayerModel = ScrubbingPlayerModel()
  var isTimearActive = false
  
  var isScrubbingNow = false;
  var scrubbingFrame = 0;
  //var currentPlayingFrame = 0;
  var scrubbingVelocity: Double = 0.0
  
  // relates to view
  var progressViewOffset: CGPoint = .zero
  var progressViewWidth: Double = 0
  var musicAssetListState = MusicAssetListState()
  var artwork: NSData? = nil
}

enum ScrubbingPlayerAction: Equatable {
  case onAppear
  case onDisappear
  case audioLoaded(Result<ScrubbingPlayerModel, APIError>)
  case playPauseTapped(ScrubbingPlayerModel)
  case skipTapped(forward: Bool)
  case playingAudio(Result<AudioEngineClient.Action, AudioEngineClient.Failure>)
  case activeTimer(on: Bool)
  case updateDisplay
  case seek(time: Double, relative: Bool)
  case seekDone(Result<Bool, AudioEngineClient.Failure>)
  case setScrubbing(on: Bool)
  case setScrubbingProperties(frame: Int, velocity: Double)
  case setScrubbingPropertiesWithView(offset: Double, velocity: Double)
  case startFileRecording(fileName: String)
  case stopFileRecording
  case setAutoScrubbing(on: Bool)
  
  // relates to View
  case setProgressViewOffset(offset: CGPoint)
  case setProgressViewWidth(width: Double)
  case musicAssetListAction(MusicAssetListAction)
}

struct ScrubbingPlayerEnvironment {
  var audioPlayer: AudioEngineClient
  var scrubbingSourceNode: GenScrubbingSourceNode
  var calcSeekFrameRelative: (Double, AVAudioFramePosition, AVAudioFramePosition, Double)-> AVAudioFramePosition
  var calcSeekFrameAbsolute: (Double, AVAudioFramePosition, Double)-> AVAudioFramePosition
  var mainScheduler: AnySchedulerOf<DispatchQueue>
  var progressToOffset: (Double, Double)-> Double = { progress, width in progress / 100.0 * width }
  var offsetToProgress: (Double, Double)-> Double = { offset, width in return offset / width * 100.0 }
  var progressToTime: (Double, Double)-> Double = { progress, totalTime in return progress / 100.0 * totalTime }
  var progressToFrame: (Double, Int)-> Int = { progress, totalFrame in return Int(progress * Double(totalFrame) / 100.0) }
  var musicAssetListEnvironment: MusicAssetListEnvironment
  var audioEffectNode: AudioEffectNode
}

extension ScrubbingPlayerEnvironment {
  static func live(scheduler: AnySchedulerOf<DispatchQueue>)-> Self {
    .init(
      audioPlayer: .livePlayerClient,
      scrubbingSourceNode: .live(),
      calcSeekFrameRelative: calcSeekFramePosition(fromTimeOffset:currentPos:audioSamples:sampleRate:),
      calcSeekFrameAbsolute: calcSeekFramePosition(fromAbsTime:audioSamples:sampleRate:),
      mainScheduler: scheduler,
      musicAssetListEnvironment: .live(scheduler: scheduler),
      audioEffectNode: .live()
    )
  }
}

let scrubbingPlayerReducer = Reducer<
  ScrubbingPlayerState,
  ScrubbingPlayerAction,
  ScrubbingPlayerEnvironment
>.combine(
  musicAssetListReducer.pullback(
    state: \.musicAssetListState,
    action: /ScrubbingPlayerAction.musicAssetListAction,
    environment: \.musicAssetListEnvironment),
  .init { state, action, environment in
    enum TimerId {}
    
    switch action {
    case .onAppear:
      do {
        state.musicAssetListState.musicAssets = try environment.musicAssetListEnvironment.bundleAudioLoader()
      }
      catch {
        print("failed to load bundle audio files \(error)")
      }
      
      environment.audioPlayer.setSession()
      //
      let fileURL: URL? = {
        if let asset = state.musicAssetListState.musicAssets.first {
          state.artwork = asset.artworkData
          return asset.url
        }
        else {
          guard let url = Bundle.main.url(forResource: "IU-5s", withExtension: "mp3") else {
            return nil
          }
          return url
        }
      }()
      
      guard let fileURL = fileURL else {
        return .none
      }
      
      return environment.audioPlayer.openUrl(fileURL)
        .receive(on: environment.mainScheduler)
        .catchToEffect()
        .map(ScrubbingPlayerAction.audioLoaded)
      
    case .onDisappear:
      return Effect(value: .activeTimer(on: false))
        .eraseToEffect()
      
    case .skipTapped(let forward):
      return .none
      
    case .playPauseTapped(let playerInfo):
      if state.playerInfo.isPlaying {
        state.playerInfo.isPlaying = false
        return environment.audioPlayer.pause().fireAndForget()
      }
      else {
        state.playerInfo.isPlaying = true
        return environment.audioPlayer
          .play(state.playerInfo)
          .receive(on: environment.mainScheduler)
          .catchToEffect(ScrubbingPlayerAction.playingAudio)
      }
      
    case .audioLoaded(let result):
      switch result {
      case .success(let info):
        state.playerInfo = info
        if let file = state.playerInfo.audioFile {
          environment.scrubbingSourceNode.updateSource(file: file, pcmBuffer: state.playerInfo.buffer)
          environment.audioEffectNode.updateSource(file: file, channel: Int(info.audioChannelCount), samplingRate: Float(info.audioSampleRate), pcmFormat: 32, interleaved: false)
          
          guard let srcNode = environment.scrubbingSourceNode.getSourceNode(renew: true) else {
            break
          }
          
          guard let audioEffect = environment.audioEffectNode.getAudioEffectNode(renew: true) else {
            break;
          }
          
          _ = environment.audioPlayer.connectSrcNodeToMixer(state.playerInfo, srcNode)
          _ = environment.audioPlayer.connectSrcNodeToMixer(state.playerInfo, audioEffect)
          
        }
      case .failure(let error):
        break
      }
      return Effect(value: .activeTimer(on: true))
        .eraseToEffect()
      
    case .playingAudio(.success(.didFinishPlaying)), .playingAudio(.failure):
      state.playerInfo.isPlaying = false
      return environment.audioPlayer.stop().fireAndForget()
      //      case let .playingAudio(.success(.didFinishPlaying(successfuly))):
      //        state.playerInfo.isPlaying = false
      //        return environment.audioPlayer.stop().fireAndForget()]
      //      case .playingAudio(.failure(let failMessage)):
      //        state.playerInfo.isPlaying = false
      //        return environment.audioPlayer.stop().fireAndForget()]
      //      case .playingAudio(let result):
      //        switch result {
      //          case let .success(.didFinishPlaying(successfully)):
      //            print(successfully)
      //          case .failure(let error):
      //            switch error {
      //              case .couldntCreateAudioPlayer: break
      //              case .decodeErrorDidOccur: break
      //            }
      //        }
      //        return .none
      
    case .updateDisplay:
      if state.playerInfo.isPlaying || state.playerInfo.isAutoScrubbing {
        let currentPosition: AVAudioFramePosition = {
          if state.playerInfo.isPlaying {
            return environment.audioPlayer.playbackPosition() + state.playerInfo.seekFrame
          }
          else {
            return AVAudioFramePosition(environment.scrubbingSourceNode.lastScrubbingStartFrame)
          }}()
        
        if !(0...state.playerInfo.audioLengthSamples ~= currentPosition) {
          state.playerInfo.currentFramePosition = max(currentPosition, 0)
          state.playerInfo.currentFramePosition = min(currentPosition, state.playerInfo.audioLengthSamples)
          
          if state.playerInfo.currentFramePosition >= state.playerInfo.audioLengthSamples {
            
            state.playerInfo.seekFrame = 0
            state.playerInfo.currentFramePosition = 0
            
            state.playerInfo.isPlaying = false
            return environment.audioPlayer.stop().fireAndForget()
          }
          else {
            return .none
          }
          
        }
        else {
          state.playerInfo.currentFramePosition = currentPosition
          let progress = Double(state.playerInfo.currentFramePosition) / Double(state.playerInfo.audioLengthSamples) * 100.0
          
          //print("player frame \(frame)")
          if state.playerInfo.playerProgress != progress {
            //print("\(state.playerInfo.playerProgress) -> \(frame) / \(progress)")
            state.playerInfo.prevProgress = state.playerInfo.playerProgress
            state.playerInfo.playerProgress = progress
          }
          
          let time = Double(state.playerInfo.currentFramePosition) / Double(state.playerInfo.audioSampleRate)
          state.playerInfo.playerTime = PlayerTime(
            elapsedTime: time,
            remainingTime: state.playerInfo.audioLengthSeconds - time)
        }
        
        environment.scrubbingSourceNode.setCurrentPlayingFrame(frame: state.playerInfo.currentFramePosition)
        state.progressViewOffset = CGPoint(x: environment.progressToOffset(state.playerInfo.playerProgress, state.progressViewWidth), y: 0)
      }
      
      return .none
      
    case .activeTimer(let on):
      if on && !state.isTimearActive {
        state.isTimearActive = true
        return Effect.timer(
          id: TimerId.self,
          every: 0.02,
          on: environment.mainScheduler)
        .map { _ in .updateDisplay }
      }
      else {
        state.isTimearActive = false
        return !on ? .cancel(id: TimerId.self) : .none
      }
      
    case .seek(let time, let relative):
      if relative {
        let currentFrame = environment.audioPlayer.playbackPosition()
        state.playerInfo.seekFrame = environment.calcSeekFrameRelative(
          time,
          state.playerInfo.currentFramePosition,
          state.playerInfo.audioLengthSamples,
          state.playerInfo.audioSampleRate)
      }
      else {
        state.playerInfo.seekFrame = environment.calcSeekFrameAbsolute(
          time,
          state.playerInfo.audioLengthSamples,
          state.playerInfo.audioSampleRate)
      }
      
      state.playerInfo.currentFramePosition = state.playerInfo.seekFrame
      print("seek-> \(state.playerInfo.seekFrame)")
      
      return environment.audioPlayer.seek(state.playerInfo.seekFrame, state.playerInfo)
        .receive(on: environment.mainScheduler)
        .catchToEffect(ScrubbingPlayerAction.seekDone)
      
    case .seekDone(let result):
      switch result {
      case .success(true):
        print("seek done true")
      case .success(false), .failure:
        print("seek failed")
      }
      return .none
      
    case .setScrubbing(on: let on):
      let doSeek = state.isScrubbingNow && !on
      state.isScrubbingNow = on
      environment.scrubbingSourceNode.setIsScrubbing(on: state.isScrubbingNow)
      
      if doSeek {
        let seekTime = environment.progressToTime(state.playerInfo.playerProgress, state.playerInfo.audioLengthSeconds)
        return Effect(value: .seek(time: seekTime, relative: false))
      }
      else {
        return .none
      }
      
    case .setScrubbingProperties(frame: let frame, velocity: let velocity):
      if frame != state.scrubbingFrame {
        state.scrubbingFrame = frame
        state.scrubbingVelocity = velocity
        
        environment.scrubbingSourceNode.setScrubbingInfo(frame: AVAudioFramePosition(state.scrubbingFrame), velocity: state.scrubbingVelocity)
      }
      //print("\(frame) - \(velocity)")
      return .none
      
    case .setScrubbingPropertiesWithView(offset: let offset, velocity: let velocity):
      if offset != state.progressViewOffset.x {
        let progress = environment.offsetToProgress(offset, state.progressViewWidth)
        state.playerInfo.playerProgress = progress
        let frame = environment.progressToFrame(progress, Int(state.playerInfo.audioLengthSamples))
        
        return Effect(value: .setScrubbingProperties(frame: frame, velocity: velocity))
      }
      return .none
      
    case .startFileRecording(let fileName):
      environment.audioPlayer.startFileRecording(state.playerInfo, fileName)
      return .none
      
    case .stopFileRecording:
      environment.audioPlayer.stopFileRecording()
      return .none
      
    case .setProgressViewOffset(let offset):
      state.progressViewOffset = offset
      return .none
      
    case .setProgressViewWidth(let width):
      state.progressViewWidth = width
      return .none
      
    case .setAutoScrubbing(let on):
      state.playerInfo.isAutoScrubbing = on
      environment.scrubbingSourceNode.setAutoScrubbing(on: on)
      return .none
      
    case .musicAssetListAction(.selecet(let id)):
      guard let asset = state.musicAssetListState.musicAssets.first(where: { $0.id == id }) else {
        return .none
      }
      if let scrubbingNode = environment.scrubbingSourceNode.getSourceNode() {
        _ = environment.audioPlayer.disconnectSrcNode(scrubbingNode)
      }
      if let audioEffectNode = environment.audioEffectNode.getAudioEffectNode() {
        _ = environment.audioPlayer.disconnectSrcNode(audioEffectNode)
      }
      state.artwork = asset.artworkData
      return environment.audioPlayer.openUrl(asset.url)
        .receive(on: environment.mainScheduler)
        .catchToEffect()
        .map(ScrubbingPlayerAction.audioLoaded)
      
    case .musicAssetListAction:
      return .none
    }
  })

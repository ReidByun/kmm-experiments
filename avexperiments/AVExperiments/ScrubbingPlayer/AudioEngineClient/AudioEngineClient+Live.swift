//
//  AudioEngineClient+Live.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/25.
//

import AVFoundation
import ComposableArchitecture
import StoreKit

extension AudioEngineClient {
  static var livePlayerClient: Self {
    var delegate: AudioEngineClientWrapper?
    print("init AudioPlayeClient Live ttt")
    return Self(
      setSession: {
        do {
          try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
          NSLog("Playback OK")
          //try AVAudioSession.sharedInstance().setPreferredSampleRate(48000.0)
          //sampleRateHz  = 48000.0
          let duration = 1.00 * (960/48000.0)
          //let duration = 1.00 * (44100/48000.0)
          try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(duration)
          try AVAudioSession.sharedInstance().setActive(true)
        } catch {
          NSLog("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
        }
      },
      openUrl: { url in
          .future { callback in // 구독을 시작하면 클로저가 호출됨.
            delegate?.pause()
            delegate = nil
            do {
              let file = try AVAudioFile(forReading: url)
              delegate = try AudioEngineClientWrapper(avAudioFile: file)
              
              guard let audioInfo = delegate?.setupAudioEngineClient() else {
                callback(.failure(.failedToOpenFile))
                return
              }
              
              callback(.success(audioInfo))
            } catch {
              callback(.failure(.failedToOpenFile))
            }
          }
      },
      play: { audioInfo in
        .future { callback in
          guard let playerDelegate = delegate else {
            callback(.failure(.couldntCreateAudioPlayer))
            return
          }
          //if playerDelegate.didFinishPlaying == nil {
          playerDelegate.didFinishPlaying = { flag in
            print("finish playing audio.")
            delegate?.pause()
            callback(.success(.didFinishPlaying(successfully: flag)))
          }
          //}
          //if playerDelegate.decodeErrorDidOccur == nil {
          playerDelegate.decodeErrorDidOccur = { _ in
            callback(.failure(.decodeErrorDidOccur))
          }
          //}
          
          playerDelegate.play(audioInfo: audioInfo)
        }
      },
      pause: {
        .fireAndForget {
          delegate?.pause()
          //delegate?.player.stop()
        }
      },
      stop: {
        .fireAndForget {
          delegate?.stop()
          //delegate?.player.stop()
        }
      },
      currentFrame: {
        .future {callback in
          guard let delegate = delegate else {
            callback(.success(0))
            return
          }
          
          callback(.success(delegate.currentFrame))
          
        }
      },
      playbackPosition: {
        guard let delegate = delegate else {
          return 0
        }
        
        return delegate.currentFrame
      },
      seek: { seekFrame, audioInfo in
          .future { callback in
            guard let playerDelegate = delegate else {
              callback(.failure(.couldntCreateAudioPlayer))
              return
            }
            
            playerDelegate.seek(to: seekFrame, audioInfo: audioInfo) { success in
              if success {
                callback(.success(true))
              }
              else {
                callback(.failure(.decodeErrorDidOccur))
              }
              
            }
          }
      },
      connectSrcNodeToMixer: { audioInfo, srcNode in
        guard let playerDelegate = delegate else {
          return false
        }
        
        return playerDelegate.connectNodeToMixer(audioInfo: audioInfo, srcNode: srcNode)
      },
      disconnectSrcNode: { srcNode in
        guard let playerDelegate = delegate else {
          return false
        }
        
        return playerDelegate.disconnectNode(srcNode: srcNode)
      },
      startFileRecording: { audioInfo, fileName in
        guard let playerDelegate = delegate else {
          return
        }
        
        playerDelegate.startFileRecording(audioInfo: audioInfo, fileName: fileName)
      },
      stopFileRecording: {
        guard let playerDelegate = delegate else {
          return
        }
        
        playerDelegate.stopFileRecording()
      }
    )
  }
}

private class AudioEngineClientWrapper: NSObject {
  var didFinishPlaying: ((Bool) -> Void)? = nil
  var decodeErrorDidOccur: ((Error?) -> Void)? = nil
  
  let engine: AVAudioEngine
  let player: AVAudioPlayerNode
  //private(set) var audioInfo: ScrubbingPlayerModel
  private(set) var needsFileScheduled = true
  //private(set) var url: URL?
  private(set) var avAudioFile: AVAudioFile
  
  private var isSeekingNow = false
  
  var currentFrame: AVAudioFramePosition {
    guard
      let lastRenderTime = player.lastRenderTime,
      let playerTime = player.playerTime(forNodeTime: lastRenderTime)
    else {
      return 0
    }
    //print("last Render(\(lastRenderTime)), playerTime(\(playerTime))")
    return playerTime.sampleTime
  }
  
//  private var autoScrubbingTimer: Timer? = nil
//  private var filteredOutputURL: URL!
//  private var newAudio: AVAudioFile = AVAudioFile()
  
  init(
    avAudioFile: AVAudioFile
  ) throws {
    //self.url = url
    self.avAudioFile = avAudioFile
    self.engine = AVAudioEngine()
    //self.audioInfo = ScrubbingPlayerModel()
    self.player = AVAudioPlayerNode()
    super.init()
    
    //setupAudioEngineClient()
  }
  
  func setupAudioEngineClient()-> ScrubbingPlayerModel? {
//    guard let fileURL = self.url else {
//      return
//    }
    
    do {
      var audioInfo = ScrubbingPlayerModel()
      //let file = try AVAudioFile(forReading: fileURL)
      let file = self.avAudioFile
      audioInfo.buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
      try file.read(into: audioInfo.buffer)
      let format = file.processingFormat
      
      audioInfo.audioLengthSamples = file.length
      audioInfo.audioSampleRate = format.sampleRate
      audioInfo.audioChannelCount = format.channelCount
      audioInfo.audioLengthSeconds = Double(audioInfo.audioLengthSamples) / audioInfo.audioSampleRate
      audioInfo.seekFrame = 0
      
      audioInfo.audioFile = file
      
      //sampleRateHz = buffer.format.sampleRate
      //FxScrubbingAudioUnit.getBufferList(from: buffer)
      
      configureEngineWithBuffer(with: audioInfo.buffer)
      
      return audioInfo
      
    } catch {
      print("Error reading the audio file: \(error.localizedDescription)")
    }
    
    return nil
  }
  
  private func configureEngineWithBuffer(with buffer: AVAudioPCMBuffer) {
    engine.attach(player)
    engine.connect(
      player,
      to: engine.mainMixerNode,
      format: buffer.format)
    
    //writeAudioToFile()
    
    engine.prepare()
    
    do {
      try engine.start()
      
      scheduleAudioBuffer(with: buffer)
      //audioInfo.isPlayerReady = true
    } catch {
      print("Error starting the player: \(error.localizedDescription)")
    }
  }
  
  private func scheduleAudioBuffer(with buffer: AVAudioPCMBuffer) {
    guard needsFileScheduled else {
      return
    }
    
    needsFileScheduled = false
    
    player.scheduleBuffer(buffer, at: nil, options: [.interruptsAtLoop]) {
      //player.scheduleBuffer(self.buffer) {
      print("play done.!!!")
      
      if !self.isSeekingNow {
        self.needsFileScheduled = true
        self.didFinishPlaying?(true)
      }
    }
  }
  
  func play(audioInfo: ScrubbingPlayerModel) {
    if player.isPlaying == true {
      player.pause()
    }

    if needsFileScheduled {
      scheduleAudioBuffer(with: audioInfo.buffer)
    }
    player.play()
  }
  
  func pause() {
    player.pause()
  }
  
  func stop() {
    player.stop()
  }
  
  func seek(to seekFramePosition: AVAudioFramePosition, audioInfo: ScrubbingPlayerModel, completion: @escaping (Bool)->Void ) {
//    guard let audioFile = audioInfo.audioFile else {
//      completion(false)
//      return
//    }
    let audioFile = self.avAudioFile
    
    if seekFramePosition < audioInfo.audioLengthSamples {
      isSeekingNow = true
      
      let wasPlaying = player.isPlaying
      player.stop()
      
      needsFileScheduled = false
      
      let frameCount = AVAudioFrameCount(audioInfo.audioLengthSamples - seekFramePosition)
      //print("\(audioInfo.audioLengthSamples), <- \(frameCount) + \(seekFramePosition)")
      
      player.scheduleSegment(
        audioFile,
        startingFrame: seekFramePosition,
        frameCount: frameCount,
        at: nil
      ) {
        print("playing done after seeking audio")
        self.needsFileScheduled = true
      }
      
      if wasPlaying {
        print("seek play again")
        self.player.play()
      }
      
      print("seek call completion")
      isSeekingNow = false
      completion(true)
    }
    else {
      completion(true)
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if !isSeekingNow {
      self.didFinishPlaying?(flag)
    }
  }
  
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    self.decodeErrorDidOccur?(error)
  }
  
  func connectNodeToMixer(audioInfo: ScrubbingPlayerModel, srcNode: AVAudioSourceNode)-> Bool {
    engine.attach(srcNode)
    engine.connect(
      srcNode,
      to: engine.mainMixerNode,
      format: audioInfo.buffer.format)
    
    return true
  }
  
  func disconnectNode(srcNode: AVAudioSourceNode)-> Bool {
    engine.detach(srcNode)
    
    return true
  }
  
  func startFileRecording(audioInfo: ScrubbingPlayerModel, fileName: String) {
    // File to write
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    //let audioURL = documentsDirectory.appendingPathComponent("share.m4a")
    //let audioURL = documentsDirectory.appendingPathComponent("sine.m4a")
    let audioURL = documentsDirectory.appendingPathComponent(fileName)
    
    // Audio File settings
    let settings = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      //AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: Int(audioInfo.audioSampleRate),
      AVNumberOfChannelsKey: Int(audioInfo.audioChannelCount),
      AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
    ]
    
    // Audio File
    var audioFile = AVAudioFile()
    do {
      audioFile = try AVAudioFile(forWriting: audioURL, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    }
    catch {
      print ("Failed to open Audio File For Writing: \(error.localizedDescription)")
    }
    
    // Install Tap on mainMixer
    engine.mainMixerNode.installTap(onBus: 0, bufferSize: 8192, format: nil, block: { (pcmBuffer, when) in
      do {
        try audioFile.write(from: pcmBuffer)
      }
      catch {
        print("Failed to write Audio File: \(error.localizedDescription)")
      }
    })
  }
  
  func stopFileRecording() {
    engine.mainMixerNode.removeTap(onBus: 0)
  }
  
}


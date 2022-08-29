//
//  LiveAudioPlayerClient.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/06.
//

import AVFoundation
import ComposableArchitecture
import StoreKit

extension AudioPlayerClient {
  static var livePlayerClient: Self {
    var test = 2
    var delegate: AudioPlayerClientDelegate?
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
          NSLog("Session is Active v=\(test)")
          test = test + 1
        } catch {
          NSLog("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
        }
      },
      openUrl: { url in
          .future { callback in // 구독을 시작하면 클로저가 호출됨.
            delegate?.player.stop()
            delegate = nil
            do {
              delegate = try AudioPlayerClientDelegate(
                url: url
              )
              
              print("open url-\(url) v=\(test)")
              test = test + 1
              
              callback(.success(ScrubbingPlayerModel()))
            } catch {
              callback(.failure(.failedToOpenFile))
            }
          }
      },
      play: {
        .future { callback in
          guard let playerDelegate = delegate else {
            callback(.failure(.couldntCreateAudioPlayer))
            return
          }
          //if playerDelegate.didFinishPlaying == nil {
          playerDelegate.didFinishPlaying = { flag in
            print("finish playing audio.")
            callback(.success(.didFinishPlaying(successfully: flag)))
          }
          //}
          //if playerDelegate.decodeErrorDidOccur == nil {
          playerDelegate.decodeErrorDidOccur = { _ in
            callback(.failure(.decodeErrorDidOccur))
          }
          //}
          
          playerDelegate.player.play()
        }
      },
      pause: {
        .fireAndForget {
          print("stop fire v=\(test)")
          test = test + 1
          delegate?.player.pause()
          //delegate?.player.stop()
        }
      }
    )
  }
}

private class AudioPlayerClientDelegate: NSObject, AVAudioPlayerDelegate {
  var didFinishPlaying: ((Bool) -> Void)? = nil
  var decodeErrorDidOccur: ((Error?) -> Void)? = nil
  let player: AVAudioPlayer
  
  init(
    url: URL
  ) throws {
    self.player = try AVAudioPlayer(contentsOf: url)
    super.init()
    self.player.delegate = self
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    self.didFinishPlaying?(flag)
  }
  
  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    self.decodeErrorDidOccur?(error)
  }
}


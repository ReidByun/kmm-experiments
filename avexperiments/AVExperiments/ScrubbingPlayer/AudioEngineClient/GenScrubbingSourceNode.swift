//
//  GenScrubbingSourceNode.swift
//  AudioExperiments
//
//  Created by Reid Byun on 2022/06/15.
//

import Foundation
import AVFoundation

class GenScrubbingSourceNode: Equatable {
  
  private var sourceNode: AVAudioSourceNode? = nil
  private var audioFile: AVAudioFile? = nil
  private var buffer: AVAudioPCMBuffer? = nil
  
  private var isScrubbing = false
  private var velocity = 100.0
  private(set) var lastScrubbingStartFrame = 0
  
  private var scrubbingFrame = 0
  private var prevScrubbingFrame = 0
  private var scrubbingStoppedFrame = 0
  private var isForwardScrubbing = true
  
  private var autoScrubbingTimer: Timer? = nil
  
  
  init() {}
  
  convenience init(file: AVAudioFile, pcmBuffer: AVAudioPCMBuffer) {
    self.init()
    audioFile = file
    buffer = pcmBuffer
    initParam()
  }
  
  func initParam() {
    isScrubbing = false
    velocity = 100.0
    lastScrubbingStartFrame = 0
    
    scrubbingFrame = 0
    prevScrubbingFrame = 0
    scrubbingStoppedFrame = 0
    isForwardScrubbing = true
    if autoScrubbingTimer != nil {
      autoScrubbingTimer?.invalidate()
      autoScrubbingTimer = nil
    }
  }
  
  func getSourceNode(renew: Bool = false)-> AVAudioSourceNode? {
    if renew {
      sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        self.processScrubbing(ablPointer: ablPointer, frameCount: Int(frameCount))
        return noErr
      }
    }
    
    return sourceNode
  }
  
  func processScrubbing(ablPointer: UnsafeMutableAudioBufferListPointer, frameCount: Int) {
    if let buffer = self.buffer, self.isScrubbing {
      guard self.scrubbingFrame >= 0 else {
        return
      }
      var targetFrame = self.scrubbingFrame
      let currentScrubbingFrame = targetFrame
      
      if prevScrubbingFrame != currentScrubbingFrame {
        scrubbingStoppedFrame = 0
        if prevScrubbingFrame - currentScrubbingFrame < 0 {
          isForwardScrubbing = true
        }
        else {
          isForwardScrubbing = false
        }
      }
      
      let maximumFrameCount = Int(buffer.frameLength)
      if targetFrame == lastScrubbingStartFrame || prevScrubbingFrame == currentScrubbingFrame {
        scrubbingStoppedFrame += frameCount
        if Double(scrubbingStoppedFrame) < (buffer.format.sampleRate / 5.0) { // 200ms
          // using velocity.
          let velocity = self.velocity / 100.0
          if isForwardScrubbing {
            targetFrame = lastScrubbingStartFrame + Int(Double(frameCount) * velocity)
            
            if targetFrame >= maximumFrameCount {
              targetFrame = maximumFrameCount - 1
            }
          }
          else {
            targetFrame = lastScrubbingStartFrame - Int(Double(frameCount) * velocity)
            if (targetFrame < 0) {
              targetFrame = 0
            }
          }
        }
        else {
          // or mute.
          targetFrame = lastScrubbingStartFrame
        }
      }
      else {
        scrubbingStoppedFrame = 0
      }
      
      prevScrubbingFrame = currentScrubbingFrame
      let diff = Double(targetFrame) - Double(lastScrubbingStartFrame)
      var lastOutFrame = 0
      
      if targetFrame != lastScrubbingStartFrame {
        for frameIndex in 0..<Int(frameCount) {
          var inputFrameOffset = Int(Double(lastScrubbingStartFrame) + Double(frameIndex) * diff / Double(frameCount-1))
          //Int inputFrameOffset = floor(lastScrubbingStartFrame + Double(frameIndex * diff) / Double(frameCount-1))
          var inputFrameNextOffset = Int(ceil(Double(lastScrubbingStartFrame) + Double(frameIndex) * diff / Double(frameCount-1)))
          if (inputFrameOffset >= maximumFrameCount) {
            inputFrameOffset = maximumFrameCount
          }
          if inputFrameNextOffset >= maximumFrameCount {
            inputFrameNextOffset = inputFrameOffset
          }
          
          var channel = 0
          for bufferBlock in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
            if (diff > 0 && inputFrameOffset <= targetFrame) ||  (diff < 0 && inputFrameOffset >= targetFrame) {
              // MARK: Sample Processing
              buf[frameIndex] = buffer.floatChannelData?[channel][inputFrameOffset] ?? 0
              lastOutFrame = inputFrameOffset
            }
            else {
              buf[frameIndex] = 0
            }
            
            channel = channel + 1
          }
        }
        
        if lastOutFrame != 0 && lastOutFrame != targetFrame {
          lastScrubbingStartFrame = lastOutFrame
        }
        else {
          lastScrubbingStartFrame = targetFrame
        }
      }
      else {
        for bufferBlock in ablPointer {
          let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
          _ = (0..<frameCount).map { buf[$0] = 0 }
          //buf.initializeFrom(Repeat(count: frameCount, repeatedValue: 0))
        }
        lastScrubbingStartFrame = targetFrame
      }
      
    }
  }
  
  func updateSource(file: AVAudioFile, pcmBuffer: AVAudioPCMBuffer) {
    initParam()
    audioFile = file
    buffer = pcmBuffer
  }
  
  func setIsScrubbing(on: Bool) {
    self.isScrubbing = on
  }
  
  func setCurrentPlayingFrame(frame: AVAudioFramePosition) {
    self.lastScrubbingStartFrame = Int(frame)
  }
  
  func setScrubbingInfo(frame: AVAudioFramePosition, velocity: Double) {
    self.scrubbingFrame = Int(frame)
    self.velocity = velocity
  }
  
  func setAutoScrubbing(on: Bool) {
    let maximumFrameCount = Int(buffer!.frameLength)
    
    if on {
      self.scrubbingFrame = self.lastScrubbingStartFrame
      
      if autoScrubbingTimer != nil { // timer is working
        autoScrubbingTimer?.invalidate()
        autoScrubbingTimer = nil
      }
      
      self.isScrubbing = true
      autoScrubbingTimer = Timer.scheduledTimer(withTimeInterval: 0.00011, repeats: true, block: { timer in
        
        var targetFrame = self.scrubbingFrame + 5
        if targetFrame > maximumFrameCount {
          targetFrame = maximumFrameCount
        }
        self.setScrubbingInfo(frame: AVAudioFramePosition(targetFrame), velocity: 100.0)
            
//        self.playerProgress = self.playerProgress + 0.09
//        if self.playerProgress > 100.0 {
//          timer.invalidate()
//          self.engine.pause()
//          self.isScrubbing = false
//          self.playerProgress = 0
//          self.engine.mainMixerNode.removeTap(onBus: 0)
//          try? self.engine.start()
//          self.autoScrubbingTimer = nil
//        }
      })
    }
    else {
      autoScrubbingTimer?.invalidate()
      autoScrubbingTimer = nil
      self.isScrubbing = false
    }
  }
  
  static func == (lhs: GenScrubbingSourceNode, rhs: GenScrubbingSourceNode) -> Bool {
    return lhs.audioFile == rhs.audioFile
  }
}

extension GenScrubbingSourceNode {
  static func live() -> GenScrubbingSourceNode {
    return .init()
  }
}

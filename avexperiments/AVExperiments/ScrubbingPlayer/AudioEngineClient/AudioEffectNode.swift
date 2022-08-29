//
//  AudioEffectNode.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/08/30.
//

import Foundation
import AVFoundation
import shared

class AudioEffectNode: Equatable {
  private var channel: Int = 2
  private var samplingRate: Float = 48000
  private var pcmFormat: Int = 32
  private var interleaved: Bool = false
  
  private var audioEffectNode: AVAudioSourceNode? = nil
  private var preprocessingUnit: AudioPreprocessor? = nil
  private var postProcessorUnit: AudioPostprocessor? = nil
  private var amplifierUnit: AudioAmplifier? = nil
  
  private var audioFile: AVAudioFile? = nil
//  private var buffer: AVAudioPCMBuffer? = nil
//
//  private var isScrubbing = false
//  private var velocity = 0.0
//  private var lastScrubbingStartFrame = 0
//
//  private var scrubbingFrame = 0
//  private var prevScrubbingFrame = 0
//  private var scrubbingStoppedFrame = 0
//  private var isForwardScrubbing = true
  
  
  init() {}
  
  convenience init(
    audioFile: AVAudioFile,
    channel: Int,
    samplingRate: Float,
    pcmFormat: Int,
    interleaved: Bool
  ) {
    self.init()
    self.audioFile = audioFile
    self.channel = channel
    self.samplingRate = samplingRate
    self.pcmFormat = pcmFormat
    self.interleaved = interleaved
  }
  
  func getAudioEffectNode(renew: Bool = false)-> AVAudioSourceNode? {
    if renew {
      self.preprocessingUnit = AudioPreprocessor(samplingRate: self.samplingRate, channel: Int32(self.channel), pcmFormat: Int32(self.pcmFormat), interleaved: self.interleaved)
      self.postProcessorUnit = AudioPostprocessor(samplingRate: self.samplingRate, channel: Int32(self.channel), pcmFormat: Int32(self.pcmFormat), interleaved: self.interleaved)
      self.amplifierUnit = AudioAmplifier(samplingRate: self.samplingRate, channel: Int32(self.channel), pcmFormat: Int32(self.pcmFormat), interleaved: self.interleaved)
      
      audioEffectNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
       
        self.audioProcessing(ablPointer: ablPointer, frameCount: Int(frameCount))
        return noErr
      }
    }
    
    return audioEffectNode
  }
  
  func audioProcessing(ablPointer: UnsafeMutableAudioBufferListPointer, frameCount: Int) {
    guard let preprocessingUnit = preprocessingUnit,
          let postProcessorUnit = postProcessorUnit,
          let amplifierUnit = amplifierUnit else {
      return
    }
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    DispatchQueue.main.async {
      var bufferArray: [UnsafeMutableBufferPointer<Float>] = []
      for bufferBlock in ablPointer {
        let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
        bufferArray.append(buf)
      }
      //amplifierUnit.test()
      preprocessingUnit.process(buffer: bufferArray as Any, frameCount: Int32(frameCount))
      amplifierUnit.process(buffer: bufferArray as Any, frameCount: Int32(frameCount))
      postProcessorUnit.process(buffer: bufferArray as Any, frameCount: Int32(frameCount))
      dispatchGroup.leave()
    }
    dispatchGroup.wait()
    
  }
  
  func updateSource(
    file: AVAudioFile,
    channel: Int,
    samplingRate: Float,
    pcmFormat: Int,
    interleaved: Bool
  ) {
    self.audioFile = file
    self.channel = channel
    self.samplingRate = samplingRate
    self.pcmFormat = pcmFormat
    self.interleaved = interleaved
  }
  
  static func == (lhs: AudioEffectNode, rhs: AudioEffectNode) -> Bool {
    return lhs.audioFile == rhs.audioFile
  }
}

extension AudioEffectNode {
  static func live() -> AudioEffectNode {
    return .init()
  }
}

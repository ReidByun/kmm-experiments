//
//  ScrubbingPlayerCalculation.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/05.
//

import Foundation
import AVFoundation

func calcSeekFramePosition(fromTimeOffset timeOffset: Double,
                           currentPos: AVAudioFramePosition,
                           audioSamples: AVAudioFramePosition,
                           sampleRate: Double) -> AVAudioFramePosition {
  let offset = AVAudioFramePosition(timeOffset * sampleRate)
  var posToseek = currentPos + offset
  posToseek = max(posToseek, 0)
  posToseek = min(posToseek, audioSamples)
  
  return posToseek
}

func calcSeekFramePosition(fromAbsTime time: Double,
                           audioSamples: AVAudioFramePosition,
                           sampleRate: Double) -> AVAudioFramePosition {
  let timeToSeek = AVAudioFramePosition(time * sampleRate)
  var posToseek = timeToSeek
  posToseek = max(posToseek, 0)
  posToseek = min(posToseek, audioSamples)
  
  return posToseek
}

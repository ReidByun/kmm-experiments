package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

actual class AudioMultiPlatformTest actual constructor(
 samplingRate: Float,
 channel: Int,
 pcmFormat: Int,
 interleaved: Boolean
): AudioEffect {
 actual override val samplingRate: Float
 actual override val channel: Int
 actual override val pcmFormat: Int
 actual override val interleaved: Boolean

 init {
  this.channel = channel
  this.samplingRate = samplingRate
  this.pcmFormat = pcmFormat
  this.interleaved = interleaved
 }

 actual override fun process(buffer: Any, frameCount: Int) {
  println("Android effect")
 }
}
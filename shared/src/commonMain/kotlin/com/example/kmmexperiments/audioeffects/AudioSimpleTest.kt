package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

class AudioSimpleTest (
 val samplingRate: Float,
 val channel: Int,
 val pcmFormat: Int,
 val interleaved: Boolean
) {

 fun process(buffer: Any, frameCount: Int) {
  print("KMM Audio Simple - Common")

 }

 fun test() {
  print("test audio simple")
 }
}
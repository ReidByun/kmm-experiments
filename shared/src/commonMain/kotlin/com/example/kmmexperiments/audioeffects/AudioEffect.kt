package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/29.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

interface AudioEffect {
    val samplingRate: Float
    val channel: Int
    val pcmFormat: Int
    val interleaved: Boolean

    fun process(buffer: Any, frameCount: Int)
}
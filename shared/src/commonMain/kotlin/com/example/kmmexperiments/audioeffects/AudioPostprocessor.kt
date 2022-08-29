package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

expect class AudioPostprocessor (
    samplingRate: Float,
    channel: Int,
    pcmFormat: Int,
    interleaved: Boolean
): AudioEffect {
    override val channel: Int
    override val samplingRate: Float
    override val pcmFormat: Int
    override val interleaved: Boolean
    override fun process(buffer: Any, frameCount: Int)
}
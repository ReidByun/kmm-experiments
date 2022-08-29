package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/29.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

expect class AudioPreprocessor(
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
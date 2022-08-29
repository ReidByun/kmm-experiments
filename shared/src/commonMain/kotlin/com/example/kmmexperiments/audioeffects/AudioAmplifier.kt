package com.example.kmmexperiments.audioeffects

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

class AudioAmplifier (
    override val samplingRate: Float,
    override val channel: Int,
    override val pcmFormat: Int,
    override val interleaved: Boolean
): AudioEffect {

    override fun process(buffer: Any, frameCount: Int) {
    }
}
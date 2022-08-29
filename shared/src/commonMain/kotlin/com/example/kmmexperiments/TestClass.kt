package com.example.kmmexperiments

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

expect class TestClass(
 testValue: Int
) : TestInterface {
 fun test()
 override val testValue: Int
 override fun testFunc()
}
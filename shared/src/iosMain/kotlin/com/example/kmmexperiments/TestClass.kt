package com.example.kmmexperiments

/**
 * Created by Reid Byun on 2022/08/30.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

actual class TestClass actual constructor(
 testValue: Int
) : TestInterface{
 actual fun test() {
  print("abc")
 }

 actual override val testValue: Int
//  get() = 10

 actual override fun testFunc() {
  print("ios test func")
 }

 init {
  this.testValue = testValue
 }
}

//actual class TestClass actual constructor() : TestInterface{
// actual fun test() {
//  print("abc")
// }
//
// actual override val testValue: Int
//  get() = 10
//
// actual override fun testFunc() {
//  print("test")
// }
//}
package com.example.kmmexperiments

class Greeting {
    fun greeting(): String {
        return "Hello, ${Platform().platform}!"
    }
}
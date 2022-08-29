package com.example.kmmexperiments

/**
 * Created by Reid Byun on 2022/08/29.
 * Copyright (c) 2022 Alight Creative. All rights reserved.
 */

import kotlinx.datetime.*

fun daysUntilNewYear(): Int {
    val today = Clock.System.todayAt(TimeZone.currentSystemDefault())
    val closestNewYear = LocalDate(today.year + 1, 1, 1)
    return today.daysUntil(closestNewYear)
}
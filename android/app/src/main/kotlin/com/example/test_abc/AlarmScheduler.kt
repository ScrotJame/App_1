package com.example.test_abc

interface AlarmScheduler {
    fun schedule(item: AlarmItem)

    /** Sets the single review reminder, replacing the one set before. */
    fun scheduleReview(triggerAtMillis: Long, message: String)

    fun cancelReview()
}
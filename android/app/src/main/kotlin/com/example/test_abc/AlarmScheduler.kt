package com.example.test_abc

interface AlarmScheduler {
    fun schedule(item: AlarmItem)

    /** Replaces the whole review plan: one alarm per reminder. */
    fun scheduleReviewPlan(reminders: List<ReviewReminder>)

    /** Removes every review alarm and the stored plan. */
    fun cancelReview()

    /** Sets again the stored reminders that are still after [nowMillis]. */
    fun rearmFromStore(nowMillis: Long)

    /** True when a non-empty review plan is stored. */
    fun hasReviewPlan(): Boolean

    /** Removes only the single review alarm older versions set. */
    fun cancelLegacyReviewAlarm()
}

package com.example.test_abc

import android.content.Context
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

data class ReviewReminder(val atMillis: Long, val title: String, val body: String)

/** Keeps the last review plan so it can be set again after a reboot. */
class ReviewPlanStore(context: Context) {

    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun save(reminders: List<ReviewReminder>) {
        val array = JSONArray()
        reminders.forEach {
            array.put(
                JSONObject()
                    .put("at", it.atMillis)
                    .put("title", it.title)
                    .put("body", it.body)
            )
        }
        prefs.edit().putString(KEY_PLAN, array.toString()).apply()
    }

    fun load(): List<ReviewReminder> {
        val raw = prefs.getString(KEY_PLAN, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val item = array.getJSONObject(i)
                ReviewReminder(
                    item.getLong("at"),
                    item.getString("title"),
                    item.getString("body")
                )
            }
        } catch (e: JSONException) {
            emptyList()
        }
    }

    fun hasPlan(): Boolean = load().isNotEmpty()

    fun clear() {
        prefs.edit().remove(KEY_PLAN).apply()
    }

    companion object {
        private const val PREFS = "review_reminders"
        private const val KEY_PLAN = "plan"
    }
}

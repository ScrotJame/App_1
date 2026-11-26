# Nhắc ôn tập: nhắc lại khi bị bỏ qua, tăng dần theo số ngày

Ngày: 2026-11-26. Code được đọc ở nhánh `feature/scan-vocab-review` (210a33a).

## 1. Vấn đề

Nhiều người dùng vuốt bỏ thông báo hoặc bấm "xóa tất cả", nên họ không quay lại ôn từ. Code hiện tại làm vấn đề nặng hơn:

1. **Chỉ có một alarm, báo xong là hết.** `AlarmService.syncReviewReminder` đặt một alarm duy nhất (request code `1001`) vào lúc từ sớm nhất đến hạn (`nextReviewReminderTime`). Alarm chỉ được đặt lại khi người dùng mở app và ôn hoặc học. Thông báo đã bị bỏ qua thì không có lần nhắc nào nữa.
2. **Khởi động lại máy là mất nhắc.** Android xóa alarm khi reboot. `AlarmReceiver` có nhận `BOOT_COMPLETED`, nhưng intent khi khởi động không có `"Extra"` nên `onReceive` return luôn.
3. **Có thể không đặt được alarm nào.** `setExactAndAllowWhileIdle` ném `SecurityException` trên Android 12+ khi người dùng không cấp quyền alarm chính xác. Lỗi bị nuốt ở `_invoke`, nên không có nhắc.
4. **Nội dung luôn giống nhau.** Câu nhắc là `review_reminder_message`, tiêu đề "Đã đến giờ học lại!" viết cứng trong Kotlin. Không có số từ, không đổi giọng.

## 2. Mục tiêu và phạm vi

**Trong phạm vi**

- Lịch nhắc nhiều lần, tính trước cho 14 ngày. Người dùng bỏ qua càng nhiều ngày thì nhắc càng dày, có trần 5 lần/ngày, không nhắc trong 22:00–07:00.
- Mỗi mức có bộ câu nhắc riêng, có số từ đến hạn, có bản tiếng Việt và tiếng Anh.
- Đặt lại lịch sau khi máy khởi động lại hoặc app được cập nhật.
- Chuyển sang alarm không chính xác khi không có quyền alarm chính xác.
- Tiêu đề thông báo được dịch. Mỗi thông báo ôn mới thay thông báo ôn cũ chứ không chồng thêm.

**Ngoài phạm vi**

- Bấm thông báo để mở thẳng màn ôn. Hiện Dart chưa xử lý `onNotificationClicked`.
- Cài đặt cho người dùng tự chọn giờ nhắc hoặc tắt nhắc trong app.
- iOS. `AlarmService` đã chỉ chạy trên Android, giữ nguyên.
- Đặt lại lịch khi đổi múi giờ hoặc đổi giờ hệ thống. Lần `sync` kế tiếp sẽ sửa.
- `AlarmService.schedule` / `scheduleAlarm` (dùng ở `study_page.dart`) và tên kênh thông báo. Giữ nguyên.
- Đổi schema Drift. Không cần cột mới.

## 3. Quy tắc lịch nhắc

### 3.1 Reset

Lịch được tính lại từ đầu mỗi lần gọi `syncReviewReminder`. Hàm này đã được gọi ở mọi chỗ làm đổi level hoặc xóa từ (feed, test, daily review, list word, list unit), nên "người dùng học hoặc ôn thì reset" có sẵn. Mở app mà không học thì không reset.

### 3.2 Mốc bắt đầu (anchor)

- Lấy `SetTimeHelper.reminderTime(level, lastReviewed)` của mọi từ có `lastReviewed`. Không có từ nào thì hủy lịch, giống hiện tại.
- `anchor` là thời điểm sớm nhất trong số đó. Nếu thời điểm đó không muộn hơn `now` (đã có từ quá hạn), `anchor = now + 1 giờ`, để không nhắc ngay khi người dùng vừa rời app.
- Nếu `anchor` rơi vào giờ ngủ thì dời: giờ từ 22:00 trở đi dời sang 07:00 hôm sau, giờ trước 07:00 dời sang 07:00 cùng ngày.

### 3.3 Mức và giờ nhắc

`d` là số ngày theo lịch tính từ ngày của `anchor` (sau khi dời). Ngày của `anchor` có `d = 0`. Lịch gồm các ngày `d = 0..13`.

| `d` | Mức | Giờ nhắc |
|---|---|---|
| 0 | `fresh` | `anchor`, `anchor + 3h`, 20:00, tối đa 3 lần |
| 1–2 | `streak` | 09:00, 12:00, 17:00, 20:00 |
| 3–6 | `fading` | 08:00, 11:00, 14:00, 17:00, 20:00 |
| 7–13 | `comeback` | 08:00, 11:00, 14:00, 17:00, 20:00 |

Lọc ngày `d = 0`: các giờ ứng viên được sắp tăng dần. Giữ một giờ khi nó không sớm hơn `anchor`, nằm trong 07:00–22:00 và cách giờ đã giữ trước đó ít nhất 2 giờ. Ví dụ:

- `anchor` 07:00: nhắc 07:00, 10:00, 20:00.
- `anchor` 19:00: chỉ nhắc 19:00. 20:00 cách chưa đủ 2 giờ, 22:00 rơi vào giờ ngủ.
- `anchor` 21:30: chỉ nhắc 21:30.

Tối đa 3 + 2×4 + 4×5 + 7×5 = 66 lần trong 14 ngày, xa giới hạn 500 alarm của Android. Sau ngày 13 không còn nhắc cho đến lần `sync` tiếp theo.

### 3.4 Nội dung

- `count` của một lần nhắc là số từ có `reminderTime` không muộn hơn giờ nhắc đó, kể cả từ đã quá hạn. Vì `anchor` là mốc sớm nhất nên `count ≥ 1`.
- Mỗi mức có 5 câu, mỗi câu có placeholder `{count}`. Câu được chọn bằng `Random`, không trùng với câu của lần nhắc ngay trước trong cùng mức.
- Tiêu đề dùng chung một key `review_reminder_title`.
- Gợi ý giọng: `fresh` nhẹ nhàng ("Có {count} từ đang chờ ôn"), `streak` nhắc chuỗi ngày học, `fading` nói từ sắp quên, `comeback` kéo người dùng quay lại ("Chỉ cần 2 phút cho {count} từ").

## 4. Thiết kế

### 4.1 Dart

**`lib/helper/review_reminder_planner.dart` (mới).** Logic thuần, không gọi DB và platform.

```dart
enum ReminderTier { fresh, streak, fading, comeback }

class ReviewReminder {            // Equatable
  final DateTime at;
  final ReminderTier tier;
  final String title;
  final String body;
}

class ReviewReminderMessages {
  final String title;
  final Map<ReminderTier, List<String Function(int count)>> bodies;
}

class ReviewReminderPlanner {
  static List<ReviewReminder> plan({
    required List<DateTime> reminderTimes, // một phần tử cho mỗi từ đã ôn
    required DateTime now,
    required ReviewReminderMessages messages,
    required Random random,
  });
}
```

Trả về danh sách rỗng khi `reminderTimes` rỗng. Danh sách trả về được sắp theo `at`.

**`IVocabularyRepository`.** Thêm `Future<List<DateTime>> reviewReminderTimes()`, trả về `SetTimeHelper.reminderTime` của mọi từ có `lastReviewed`. Bỏ `nextReviewReminderTime` (chỉ `AlarmService` dùng) và chuyển các test của nó sang hàm mới.

**`AlarmService.syncReviewReminder`.**

1. Lấy `reviewReminderTimes()`, tạo `ReviewReminderMessages` từ `S.current`, gọi `plan(...)` với `Random()`.
2. Danh sách rỗng thì gọi `cancelReviewAlarm`.
3. Ngược lại gọi `scheduleReviewPlan` với `{'reminders': [{'at': millis, 'title': ..., 'body': ...}, ...]}`.

**l10n.** Thêm `review_reminder_title` và 20 key `review_reminder_<tier>_<1..5>` (mỗi key có placeholder `count` kiểu `int`) vào `intl_en.arb` và `intl_vi.arb`. Bỏ `review_reminder_message`.

### 4.2 Kotlin

**`ReviewPlanStore` (mới).** Lưu danh sách nhắc dạng JSON trong SharedPreferences `review_reminders`, key `plan`. Có `save(list)`, `load()`, `clear()`.

**`AndroidAlarmScheduler`.**

- `scheduleReviewPlan(reminders)`: hủy các alarm trong plan đã lưu, hủy alarm cũ `1001` (cho người dùng nâng cấp), đặt từng lần nhắc với request code `2000 + i`, rồi lưu plan mới.
- `cancelReview()`: hủy các alarm trong plan đã lưu và alarm `1001`, rồi xóa plan.
- `rearmFromStore(now)`: đặt lại các lần nhắc có `at > now`.
- Đặt alarm: API 31+ thì dùng `setExactAndAllowWhileIdle` khi `canScheduleExactAlarms()` trả về true, ngược lại dùng `setAndAllowWhileIdle`. Dưới API 31 luôn dùng alarm chính xác.
- PendingIntent của lần nhắc mang extra `title`, `body`. Việc hủy chỉ cần đúng component và request code.

**`AlarmReceiver`.** Đọc `title` và `body`. Nếu có thì gọi `NotificationHelper.showReview(title, body)`. Nếu không có thì vẫn đọc `"Extra"` như cũ cho `scheduleAlarm`. Bỏ intent-filter boot khỏi receiver này.

**`BootReceiver` (mới).** Nhận `BOOT_COMPLETED`, `QUICKBOOT_POWERON`, `MY_PACKAGE_REPLACED`, rồi gọi `rearmFromStore(System.currentTimeMillis())`. Khai báo trong `AndroidManifest.xml` với `exported="true"`, cho chắc chắn nhận được broadcast hệ thống trên mọi bản Android. App khác có gửi broadcast này thì cũng chỉ làm lịch được đặt lại, không có hại.

**`NotificationHelper`.** Thêm `showReview(title, body)` với id cố định `REVIEW_NOTIFICATION_ID`, để thông báo mới thay thông báo cũ. `showNotification(message)` giữ nguyên.

**`MainActivity`.** Thêm nhánh `scheduleReviewPlan`. Bỏ nhánh `scheduleReviewAlarm`. `cancelReviewAlarm` giữ tên.

## 5. Lỗi và trường hợp biên

- Kênh native lỗi: `_invoke` đã bắt `PlatformException` và `MissingPluginException`. `syncReviewReminder` bắt mọi lỗi và chỉ ghi log, giống hiện tại.
- JSON đã lưu bị hỏng: `load()` trả về danh sách rỗng, không crash receiver.
- Khởi động lại máy khi mọi lần nhắc đã qua: không đặt gì.
- Người dùng đổi ngôn ngữ: câu nhắc đã đặt giữ ngôn ngữ cũ cho đến lần `sync` tiếp theo.

## 6. Kiểm thử

**Unit test Dart: `test/helper/review_reminder_planner_test.dart`.** Dùng `Random` có seed và `now` cố định.

- Không có từ thì danh sách rỗng.
- Các ví dụ `anchor` 07:00, 19:00, 21:30 ở §3.3 cho đúng giờ nhắc ngày 0.
- Dời `anchor`: 23:00 sang 07:00 hôm sau, 05:00 sang 07:00 cùng ngày.
- `anchor` quá hạn thành `now + 1h`.
- Đúng mức và đúng giờ cho các ngày 1, 2, 3, 6, 7, 13. Không có lần nhắc ngày 14. Không có lần nhắc nào trong 22:00–07:00.
- `count` tăng khi thêm từ đến hạn. Lần nhắc đầu có `count ≥ 1`.
- Hai lần nhắc liền nhau cùng mức không dùng cùng một câu.

**Test repository.** Chuyển các case `nextReviewReminderTime` trong `test/repository/vocabulary_word_level_test.dart` và `test/page/learning/word_progress_flow_test.dart` sang `reviewReminderTimes`.

**Kiểm tra tay trên máy Android:**

- Ôn vài từ rồi xem alarm bằng `adb shell dumpsys alarm | grep test_abc`.
- Tua đồng hồ hoặc chờ để thấy thông báo, tiêu đề và câu đã dịch, thông báo mới thay thông báo cũ.
- Khởi động lại máy rồi kiểm tra alarm vẫn còn.
- Thu hồi quyền alarm chính xác rồi kiểm tra vẫn đặt được alarm.
- Cài bản mới đè lên bản cũ rồi kiểm tra alarm `1001` đã bị hủy và lịch mới có mặt.

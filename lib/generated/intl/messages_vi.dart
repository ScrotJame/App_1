// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a vi locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'vi';

  static String m0(word) => "Xóa \"${word}\"?";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addWord": MessageLookupByLibrary.simpleMessage("Thêm từ mới"),
    "adjI": MessageLookupByLibrary.simpleMessage("Tính từ đuôi i"),
    "adjNa": MessageLookupByLibrary.simpleMessage("Tính từ đuôi na"),
    "adverb": MessageLookupByLibrary.simpleMessage("Trạng từ"),
    "base_name": MessageLookupByLibrary.simpleMessage("Chiến binh"),
    "cancel": MessageLookupByLibrary.simpleMessage("Hủy"),
    "confirmDeleteMsg": m0,
    "delete": MessageLookupByLibrary.simpleMessage("Xóa"),
    "emptyList": MessageLookupByLibrary.simpleMessage("Chưa có từ vựng nào"),
    "emptyListHint": MessageLookupByLibrary.simpleMessage(
      "Nhấn + để thêm từ mới",
    ),
    "errorEnterMeaning": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập nghĩa",
    ),
    "errorEnterWord": MessageLookupByLibrary.simpleMessage(
      "Vui lòng nhập từ vựng",
    ),
    "expression": MessageLookupByLibrary.simpleMessage("Cụm từ"),
    "fieldMeaning": MessageLookupByLibrary.simpleMessage("Nghĩa"),
    "fieldPronunciation": MessageLookupByLibrary.simpleMessage("Phát âm"),
    "fieldVocabulary": MessageLookupByLibrary.simpleMessage("Từ vựng"),
    "level": MessageLookupByLibrary.simpleMessage("Cấp độ"),
    "noun": MessageLookupByLibrary.simpleMessage("Danh từ"),
    "save": MessageLookupByLibrary.simpleMessage("Lưu"),
    "tabAll": MessageLookupByLibrary.simpleMessage("Tất cả"),
    "tabLearned": MessageLookupByLibrary.simpleMessage("Đã học"),
    "tabNew": MessageLookupByLibrary.simpleMessage("Mới"),
    "verb": MessageLookupByLibrary.simpleMessage("Động từ"),
    "vocabularyList": MessageLookupByLibrary.simpleMessage("Danh sách từ vựng"),
    "wordCount": MessageLookupByLibrary.simpleMessage(" từ"),
  };
}

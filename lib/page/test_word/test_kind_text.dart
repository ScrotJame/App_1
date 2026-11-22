import 'package:flutter/material.dart';

import '../../commons/enums.dart';
import '../../generated/l10n.dart';

/// How each kind of question is named and drawn.
extension TestKindText on TestKind {
  String get title => switch (this) {
        TestKind.choice => S.current.test_kind_choice,
        TestKind.typing => S.current.test_kind_typing,
        TestKind.listening => S.current.test_kind_listening,
        TestKind.trueFalse => S.current.test_kind_true_false,
      };

  String get description => switch (this) {
        TestKind.choice => S.current.test_kind_choice_desc,
        TestKind.typing => S.current.test_kind_typing_desc,
        TestKind.listening => S.current.test_kind_listening_desc,
        TestKind.trueFalse => S.current.test_kind_true_false_desc,
      };

  IconData get icon => switch (this) {
        TestKind.choice => Icons.checklist_rounded,
        TestKind.typing => Icons.keyboard_alt_outlined,
        TestKind.listening => Icons.headphones_rounded,
        TestKind.trueFalse => Icons.rule_rounded,
      };
}

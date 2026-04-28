import 'package:test_abc/generated/l10n.dart';

import '../commons/enums.dart';

extension VocabTagExt on VocabTagJP {
  String get label {
    switch (this) {
      case VocabTagJP.noun:
        return S.current.noun;
      case VocabTagJP.verb:
        return S.current.verb;
      case VocabTagJP.adjI:
        return S.current.adjI;
      case VocabTagJP.adjNa:
        return S.current.adjNa;
      case VocabTagJP.adverb:
        return S.current.adverb;
      case VocabTagJP.expression:
        return S.current.expression;
    }
  }
}
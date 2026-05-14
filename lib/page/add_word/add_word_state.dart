part of 'add_word_cubit.dart';

enum PageType { Add, Put }

class AddWordState extends Equatable {
  AddWordState({
    this.vocabulary = '',
    this.furigana = '',
    this.meaning = '',
    this.wordType = '',
    this.jlptLevel = '',
    this.loadstatus = LOADSTATUS.INITAL,
    this.errorMessage,
    this.tags,
    this.selectedTagIds = const [],
    this.detectedLanguage,
    this.languageDetectStatus = LOADSTATUS.INITAL,
    this.isLanguageManuallySet = false,
  });

  final String vocabulary;
  final String furigana;
  final String meaning;
  final String wordType;
  final String jlptLevel;
  final LOADSTATUS? loadstatus;
  final String? errorMessage;

  /// Toàn bộ tag lấy từ DB để hiển thị danh sách chọn
  final List<Tag>? tags;

  /// Các tag đang được chọn (theo id)
  final List<int> selectedTagIds;
  final String? detectedLanguage;
  final LOADSTATUS languageDetectStatus;
  final bool isLanguageManuallySet;
  // ─── Helper ───────────────────────────────────────────────
  bool isTagSelected(int tagId) => selectedTagIds.contains(tagId);

  AddWordState copyWith({
    String? vocabulary,
    String? furigana,
    String? meaning,
    String? wordType,
    String? jlptLevel,
    LOADSTATUS? loadstatus,
    String? errorMessage,
    List<Tag>? tags,
    List<int>? selectedTagIds,
    String? detectedLanguage,
    LOADSTATUS? languageDetectStatus,
    bool clearLanguage = false,
    bool? isLanguageManuallySet,
  }) {
    return AddWordState(
      vocabulary: vocabulary ?? this.vocabulary,
      furigana: furigana ?? this.furigana,
      meaning: meaning ?? this.meaning,
      wordType: wordType ?? this.wordType,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      loadstatus: loadstatus ?? this.loadstatus,
      errorMessage: errorMessage ?? this.errorMessage,
      tags: tags ?? this.tags,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      detectedLanguage: clearLanguage ? null : (detectedLanguage ?? this.detectedLanguage),
      languageDetectStatus: languageDetectStatus ?? this.languageDetectStatus,
      isLanguageManuallySet: clearLanguage ? false : (isLanguageManuallySet ?? this.isLanguageManuallySet),
    );
  }

  bool get isPreviewReady =>
      vocabulary.isNotEmpty || furigana.isNotEmpty || meaning.isNotEmpty;

  String get detectedLanguageLabel => LanguageHelper.getDetectedLanguageLabel(detectedLanguage);

  String get languageBadgeLabel {
    if (detectedLanguage == null) return '';
    final found = kSupportedLanguages
        .where((l) => l.code == detectedLanguage)
        .firstOrNull;
    return found != null ? '${found.flag} ${found.label}' : detectedLanguageLabel;
  }
  @override
  List<Object?> get props => [
    vocabulary,
    furigana,
    meaning,
    wordType,
    jlptLevel,
    loadstatus,
    errorMessage,
    tags,
    selectedTagIds,
    detectedLanguage,
    languageDetectStatus,
    isLanguageManuallySet
  ];
}
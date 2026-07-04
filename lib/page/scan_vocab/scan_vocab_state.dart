part of 'scan_vocab_cubit.dart';

// ─── Danh sách ngôn ngữ hỗ trợ chọn thủ công ────────────────────────────────

// ─── Một block văn bản từ OCR, có vị trí trên ảnh gốc ───────────────────────
class OcrBlock extends Equatable {
  final String text;
  final Rect boundingBox; // toạ độ trên ảnh GỐC (pixel)
  final TokenRole role;
  final bool isSelected;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    this.role = TokenRole.none,
    this.isSelected = false,
  });

  OcrBlock copyWith({TokenRole? role, bool? isSelected}) {
    return OcrBlock(
      text: text,
      boundingBox: boundingBox,
      role: role ?? this.role,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [text, boundingBox, role, isSelected];
}

class ScannedVocabItem extends Equatable {
  final String word;
  final String pronunciation;
  final String meaning;
  final String language;

  const ScannedVocabItem({
    this.word = '',
    this.pronunciation = '',
    this.meaning = '',
    required this.language,
  });

  ScannedVocabItem copyWith({
    String? word,
    String? pronunciation,
    String? meaning,
    String? language,
  }) {
    return ScannedVocabItem(
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      language: language ?? this.language,
    );
  }

  bool get hasError => word.trim().isEmpty || meaning.trim().isEmpty;

  @override
  List<Object?> get props => [word, pronunciation, meaning, language];
}

// ─── State chính ─────────────────────────────────────────────────────────────
class ScanVocabState extends Equatable {
  final Size? imageSize;
  final List<OcrBlock> blocks;
  final TokenRole activeRole;
  final List<ScannedVocabItem> vocabItems;
  final SCANSTATUS status;
  final String? errorMessage;
  final Rect? dragRect;
  final String? detectedLanguage;
  /// true khi user đã chọn ngôn ngữ thủ công → auto-detect sẽ không ghi đè
  final bool isLanguageManuallySet;

  const ScanVocabState({
    this.imageSize,
    this.blocks = const [],
    this.activeRole = TokenRole.word,
    this.vocabItems = const [],
    this.status = SCANSTATUS.idle,
    this.errorMessage,
    this.dragRect,
    this.detectedLanguage,
    this.isLanguageManuallySet = false,
  });

  // ─── Preview từ đang được chọn ────────────────────────────────────────────
  ScannedVocabItem get currentPreview {
    final languageFromBlocks = blocks
        .where((b) => b.role == TokenRole.language)
        .map((b) => b.text)
        .join(' ');
    return ScannedVocabItem(
      word: blocks.where((b) => b.role == TokenRole.word).map((b) => b.text).join(' '),
      pronunciation: blocks.where((b) => b.role == TokenRole.pronunciation).map((b) => b.text).join(' '),
      meaning: blocks.where((b) => b.role == TokenRole.meaning).map((b) => b.text).join(' '),
      language: languageFromBlocks,
    );
  }

  bool get hasAnySelection => blocks.any((b) => b.isSelected);
  String get detectedLanguageLabel => LanguageHelper.getDetectedLanguageLabel(detectedLanguage);

  /// Label hiển thị cho badge, ưu tiên kSupportedLanguages
  String get languageBadgeLabel {
    if (detectedLanguage == null) return '';
    final found = kSupportedLanguages.where((l) => l.code == detectedLanguage).firstOrNull;
    return found != null ? '${found.flag} ${found.label}' : detectedLanguageLabel;
  }

  ScanVocabState copyWith({
    Size? imageSize,
    List<OcrBlock>? blocks,
    TokenRole? activeRole,
    List<ScannedVocabItem>? vocabItems,
    SCANSTATUS? status,
    String? errorMessage,
    Rect? dragRect,
    bool clearDragRect = false,
    bool clearError = false,
    String? detectedLanguage,
    bool clearLanguage = false,
    bool? isLanguageManuallySet,
  }) {
    return ScanVocabState(
      imageSize: imageSize ?? this.imageSize,
      blocks: blocks ?? this.blocks,
      activeRole: activeRole ?? this.activeRole,
      vocabItems: vocabItems ?? this.vocabItems,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dragRect: clearDragRect ? null : (dragRect ?? this.dragRect),
      detectedLanguage: clearLanguage ? null : (detectedLanguage ?? this.detectedLanguage),
      isLanguageManuallySet: clearLanguage ? false : (isLanguageManuallySet ?? this.isLanguageManuallySet),
    );
  }

  @override
  List<Object?> get props => [
    imageSize, blocks, activeRole, vocabItems,
    status, errorMessage, dragRect,
    detectedLanguage, isLanguageManuallySet,
  ];
}

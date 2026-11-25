part of 'scan_vocab_cubit.dart';

// ─── Danh sách ngôn ngữ hỗ trợ chọn thủ công ────────────────────────────────

// ─── Một block văn bản từ OCR, có vị trí trên ảnh gốc ───────────────────────
class OcrBlock extends Equatable {
  final String text;
  final Rect boundingBox; // toạ độ trên ảnh GỐC (pixel)
  final TokenRole role;
  final bool isSelected;

  /// Được chọn bằng vai trò "Từ": app còn tự chia nó thành Từ / Âm.
  final bool autoRole;

  const OcrBlock({
    required this.text,
    required this.boundingBox,
    this.role = TokenRole.none,
    this.isSelected = false,
    this.autoRole = false,
  });

  OcrBlock copyWith({TokenRole? role, bool? isSelected, bool? autoRole}) {
    return OcrBlock(
      text: text,
      boundingBox: boundingBox,
      role: role ?? this.role,
      isSelected: isSelected ?? this.isSelected,
      autoRole: autoRole ?? this.autoRole,
    );
  }

  @override
  List<Object?> get props => [text, boundingBox, role, isSelected, autoRole];
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
  /// Điểm bắt đầu kéo (toạ độ widget); dragRect luôn dựng từ điểm này.
  final Offset? dragOrigin;
  final String? detectedLanguage;
  /// true khi user đã chọn ngôn ngữ thủ công → auto-detect sẽ không ghi đè
  final bool isLanguageManuallySet;

  /// Chữ người dùng sửa tay, ghi đè chữ lấy từ ảnh của vai trò đó.
  final Map<TokenRole, String> edits;

  const ScanVocabState({
    this.imageSize,
    this.blocks = const [],
    this.activeRole = TokenRole.word,
    this.vocabItems = const [],
    this.status = SCANSTATUS.idle,
    this.errorMessage,
    this.dragRect,
    this.dragOrigin,
    this.detectedLanguage,
    this.isLanguageManuallySet = false,
    this.edits = const {},
  });

  // ─── Preview từ đang được chọn ────────────────────────────────────────────
  static String textOfRole(List<OcrBlock> blocks, TokenRole role) =>
      joinOcrTokens(blocks.where((b) => b.role == role).map((b) => b.text));

  /// Chữ của các mảnh mang [role], nối theo thứ tự OCR (xem [joinOcrTokens]).
  String textForRole(TokenRole role) => textOfRole(blocks, role);

  ScannedVocabItem get currentPreview {
    final rawWord = textForRole(TokenRole.word);
    final rawReading =
        stripBrackets(textForRole(TokenRole.pronunciation));
    // `X（かな）` chỉ tách khi ảnh chưa cho cách đọc riêng.
    final split = rawReading.isEmpty ? splitBracketReading(rawWord) : null;
    return ScannedVocabItem(
      word: edits[TokenRole.word] ?? split?.word ?? rawWord,
      pronunciation: edits[TokenRole.pronunciation] ??
          split?.reading ??
          rawReading,
      meaning: edits[TokenRole.meaning] ?? textForRole(TokenRole.meaning),
      language: textForRole(TokenRole.language),
    );
  }

  bool get hasAnySelection =>
      edits.isNotEmpty || blocks.any((b) => b.isSelected);

  /// Quét xong nhưng không tìm thấy chữ nào.
  bool get hasNoText => status == SCANSTATUS.scanned && blocks.isEmpty;

  String get errorText => errorMessage ?? '';
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
    Offset? dragOrigin,
    bool clearDragRect = false,
    bool clearError = false,
    String? detectedLanguage,
    bool clearLanguage = false,
    bool? isLanguageManuallySet,
    Map<TokenRole, String>? edits,
  }) {
    return ScanVocabState(
      imageSize: imageSize ?? this.imageSize,
      blocks: blocks ?? this.blocks,
      activeRole: activeRole ?? this.activeRole,
      vocabItems: vocabItems ?? this.vocabItems,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dragRect: clearDragRect ? null : (dragRect ?? this.dragRect),
      dragOrigin: clearDragRect ? null : (dragOrigin ?? this.dragOrigin),
      detectedLanguage: clearLanguage ? null : (detectedLanguage ?? this.detectedLanguage),
      isLanguageManuallySet: clearLanguage ? false : (isLanguageManuallySet ?? this.isLanguageManuallySet),
      edits: edits ?? this.edits,
    );
  }

  @override
  List<Object?> get props => [
    imageSize, blocks, activeRole, vocabItems,
    status, errorMessage, dragRect, dragOrigin,
    detectedLanguage, isLanguageManuallySet, edits,
  ];
}

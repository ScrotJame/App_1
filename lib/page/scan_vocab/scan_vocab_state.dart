part of 'scan_vocab_cubit.dart';

enum TokenRole { none, word, pronunciation, meaning }

enum SCANSTATUS { idle, scanning, scanned, error }

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

// ─── Từ vựng đã cấu hình xong ────────────────────────────────────────────────
class ScannedVocabItem extends Equatable {
  final String word;
  final String pronunciation;
  final String meaning;

  const ScannedVocabItem({
    this.word = '',
    this.pronunciation = '',
    this.meaning = '',
  });

  ScannedVocabItem copyWith({String? word, String? pronunciation, String? meaning}) {
    return ScannedVocabItem(
      word: word ?? this.word,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
    );
  }

  bool get hasError => word.trim().isEmpty || meaning.trim().isEmpty;

  @override
  List<Object?> get props => [word, pronunciation, meaning];
}

// ─── State chính ─────────────────────────────────────────────────────────────
class ScanVocabState extends Equatable {
  /// Kích thước ảnh gốc (pixel) — dùng để scale bounding box lên widget
  final Size? imageSize;

  final List<OcrBlock> blocks;
  final TokenRole activeRole;
  final List<ScannedVocabItem> vocabItems;
  final SCANSTATUS status;
  final String? errorMessage;

  /// Vùng đang drag (toạ độ trên widget, chưa scale)
  final Rect? dragRect;

  const ScanVocabState({
    this.imageSize,
    this.blocks = const [],
    this.activeRole = TokenRole.word,
    this.vocabItems = const [],
    this.status = SCANSTATUS.idle,
    this.errorMessage,
    this.dragRect,
  });

  // ─── Preview từ đang được chọn ────────────────────────────────────────────
  ScannedVocabItem get currentPreview => ScannedVocabItem(
    word: blocks.where((b) => b.role == TokenRole.word).map((b) => b.text).join(' '),
    pronunciation: blocks.where((b) => b.role == TokenRole.pronunciation).map((b) => b.text).join(' '),
    meaning: blocks.where((b) => b.role == TokenRole.meaning).map((b) => b.text).join(' '),
  );

  bool get hasAnySelection => blocks.any((b) => b.isSelected);

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
  }) {
    return ScanVocabState(
      imageSize: imageSize ?? this.imageSize,
      blocks: blocks ?? this.blocks,
      activeRole: activeRole ?? this.activeRole,
      vocabItems: vocabItems ?? this.vocabItems,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dragRect: clearDragRect ? null : (dragRect ?? this.dragRect),
    );
  }

  @override
  List<Object?> get props => [imageSize, blocks, activeRole, vocabItems, status, errorMessage, dragRect];
}
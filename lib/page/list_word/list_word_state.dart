part of 'list_word_cubit.dart';

enum FilterTab { all, learned, newWord }

class ListWordState extends Equatable {
  const ListWordState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.activeTab = FilterTab.all,
    this.searchQuery = '',
    this.isSearching = false,
    this.loadstatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  /// Toàn bộ từ lấy từ DB
  final List<VocabularyEntry> allWords;

  /// Danh sách hiển thị sau khi filter + search
  final List<VocabularyEntry> filteredWords;

  final FilterTab activeTab;
  final String searchQuery;

  /// Bật/tắt thanh tìm kiếm trên AppBar
  final bool isSearching;

  final LOADSTATUS loadstatus;
  final String? errorMessage;

  // ─── Computed getters ─────────────────────────────────────

  int get totalCount => allWords.length;

  // int get learnedCount =>
  //     allWords.where((w) => w.isFavorite == true).length;
  //
  // int get newCount =>
  //     allWords.where((w) => w.isFavorite != true).length;

  // ─── CopyWith ─────────────────────────────────────────────

  ListWordState copyWith({
    List<VocabularyEntry>? allWords,
    List<VocabularyEntry>? filteredWords,
    FilterTab? activeTab,
    String? searchQuery,
    bool? isSearching,
    LOADSTATUS? loadstatus,
    String? errorMessage,
  }) {
    return ListWordState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      loadstatus: loadstatus ?? this.loadstatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    allWords,
    filteredWords,
    activeTab,
    searchQuery,
    isSearching,
    loadstatus,
    errorMessage,
  ];
}
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

  /// Toàn bộ từ lấy từ DB (kèm tags)
  final List<VocabularyWithTags> allWords;

  /// Danh sách hiển thị sau khi filter + search
  final List<VocabularyWithTags> filteredWords;

  final FilterTab activeTab;
  final String searchQuery;
  final bool isSearching;
  final LOADSTATUS loadstatus;
  final String? errorMessage;

  // ─── Computed ─────────────────────────────────────────────
  int get totalCount => allWords.length;

  // ─── CopyWith ─────────────────────────────────────────────
  ListWordState copyWith({
    List<VocabularyWithTags>? allWords,
    List<VocabularyWithTags>? filteredWords,
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
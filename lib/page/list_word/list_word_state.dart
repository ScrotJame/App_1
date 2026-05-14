part of 'list_word_cubit.dart';

class ListWordState extends Equatable {
  final List<VocabularyWithTags> allWords;
  final List<VocabularyWithTags> filteredWords;
  final List<String> languageTags;
  final String? activeLanguage;
  final String searchQuery;
  final bool isSearching;
  final LOADSTATUS loadstatus;
  final String? errorMessage;

  const ListWordState({
    this.allWords = const [],
    this.filteredWords = const [],
    this.languageTags = const [],
    this.activeLanguage,
    this.searchQuery = '',
    this.isSearching = false,
    this.loadstatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  int get totalCount => allWords.length;

  ListWordState copyWith({
    List<VocabularyWithTags>? allWords,
    List<VocabularyWithTags>? filteredWords,
    List<String>? languageTags,
    String? activeLanguage,
    bool clearActiveLanguage = false,
    String? searchQuery,
    bool? isSearching,
    LOADSTATUS? loadstatus,
    String? errorMessage,
  }) {
    return ListWordState(
      allWords: allWords ?? this.allWords,
      filteredWords: filteredWords ?? this.filteredWords,
      languageTags: languageTags ?? this.languageTags,
      activeLanguage: clearActiveLanguage ? null : (activeLanguage ?? this.activeLanguage),
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
    languageTags,
    activeLanguage,
    searchQuery,
    isSearching,
    loadstatus,
    errorMessage,
  ];
}
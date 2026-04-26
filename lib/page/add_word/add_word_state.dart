part of 'add_word_cubit.dart';

class AddWordState extends Equatable {
  AddWordState({
    this.vocabulary = '',
    this.furigana = '',
    this.meaning = '',
    this.wordType = '',
    this.jlptLevel = '',
    this.loadstatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  final String vocabulary;
  final String furigana;
  final String meaning;
  final String wordType;
  final String jlptLevel;
  final LOADSTATUS? loadstatus;
  final String? errorMessage;

  AddWordState copyWith({
    String? vocabulary,
    String? furigana,
    String? meaning,
    String? wordType,
    String? jlptLevel,
    LOADSTATUS? loadstatus,
    String? errorMessage,
  }) {
    return AddWordState(
      vocabulary: vocabulary ?? this.vocabulary,
      furigana: furigana ?? this.furigana,
      meaning: meaning ?? this.meaning,
      wordType: wordType ?? this.wordType,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      loadstatus: loadstatus ?? this.loadstatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isPreviewReady =>
      vocabulary.isNotEmpty || furigana.isNotEmpty || meaning.isNotEmpty;

  @override
  List<Object?> get props => [
    vocabulary,
    furigana,
    meaning,
    wordType,
    jlptLevel,
    loadstatus,
    errorMessage,
  ];
}
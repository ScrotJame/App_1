import 'package:equatable/equatable.dart';
import 'package:test_abc/database/app_db.dart';

class UnitWithWords extends Equatable {
  const UnitWithWords({
    required this.unit,
    required this.words,
  });

  final UnitsEntry unit;
  final List<VocabularyEntry> words;

  int get wordCount => words.length;

  @override
  List<Object?> get props => [unit, words];
}
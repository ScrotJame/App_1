
import '../database/app_db.dart';

class VocabularyWithTags {
  final VocabularyEntry word;
  final String? languageTags;
  final List<Tag>? tags;

  const VocabularyWithTags({
    required this.word,
    this.languageTags,
    this.tags,
  });

  bool? get hasTags => tags?.isNotEmpty;
}
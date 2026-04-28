
import '../database/app_db.dart';

class VocabularyWithTags {
  final VocabularyEntry word;
  final List<Tag> tags;

  const VocabularyWithTags({
    required this.word,
    required this.tags,
  });

  bool get hasTags => tags.isNotEmpty;
}
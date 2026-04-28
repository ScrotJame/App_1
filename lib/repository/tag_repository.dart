// tag_repository.dart
import 'package:drift/drift.dart';

import '../database/app_db.dart';

abstract class ITagRepository {
  Future<List<Tag>> getAllTags();
  Future<List<Tag>> getTagsForLanguage(String? language);
  Future<int> insertTag({required String name, String? language});
  Future<int> deleteTag(int id);
}

class TagRepository implements ITagRepository {
  final AppDatabase _db;
  TagRepository(this._db);

  @override
  Future<List<Tag>> getAllTags() =>
      _db.select(_db.tags).get();

  // Lấy tag theo ngôn ngữ của từ — null = mọi ngôn ngữ
  @override
  Future<List<Tag>> getTagsForLanguage(String? language) =>
      (_db.select(_db.tags)
        ..where((t) =>
        t.targetLanguage.isNull() |
        t.targetLanguage.equals(language ?? '')))
          .get();

  @override
  Future<int> insertTag({required String name, String? language}) =>
      _db.into(_db.tags).insert(
        TagsCompanion.insert(
          tagName: name,
          targetLanguage: language != null
              ? Value(language)
              : const Value.absent(),
        ),
      );

  @override
  Future<int> deleteTag(int id) =>
      (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
}
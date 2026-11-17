class ImportResult {
  final bool success;
  final String? error;
  final ImportSummary? summary;

  const ImportResult.ok(this.summary)
      : success = true,
        error = null;
  const ImportResult.fail(this.error)
      : success = false,
        summary = null;
}

class ImportSummary {
  final int usersUpdated;
  final int activitiesAdded;
  final int wordProgressMerged;
  final int unitsAdded;
  final int vocabulariesAdded;
  final int tagsAdded;
  final int vocabularyTagsAdded;
  final int userItemsMerged;
  final int learningHistoryAdded;
  final int achievementsMerged;
  final int companionsMerged;

  const ImportSummary({
    required this.usersUpdated,
    required this.activitiesAdded,
    required this.wordProgressMerged,
    required this.unitsAdded,
    required this.vocabulariesAdded,
    required this.tagsAdded,
    required this.vocabularyTagsAdded,
    required this.userItemsMerged,
    this.learningHistoryAdded = 0,
    this.achievementsMerged = 0,
    this.companionsMerged = 0,
  });
}

class ExportResult {
  final bool success;
  final bool cancelled;
  final String? error;
  final String? filePath; // null nếu share hoặc upload lên server

  const ExportResult.ok({this.filePath})
      : success = true,
        cancelled = false,
        error = null;
  const ExportResult.fail(this.error)
      : success = false,
        cancelled = false,
        filePath = null;
  const ExportResult.cancelled()
      : success = false,
        cancelled = true,
        error = null,
        filePath = null;
}
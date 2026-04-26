// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $UnitsEntriesTable extends UnitsEntries
    with TableInfo<$UnitsEntriesTable, UnitsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UnitsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 255),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'units_entries';
  @override
  VerificationContext validateIntegrity(Insertable<UnitsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UnitsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UnitsEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
    );
  }

  @override
  $UnitsEntriesTable createAlias(String alias) {
    return $UnitsEntriesTable(attachedDatabase, alias);
  }
}

class UnitsEntry extends DataClass implements Insertable<UnitsEntry> {
  final int id;
  final String title;
  const UnitsEntry({required this.id, required this.title});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    return map;
  }

  UnitsEntriesCompanion toCompanion(bool nullToAbsent) {
    return UnitsEntriesCompanion(
      id: Value(id),
      title: Value(title),
    );
  }

  factory UnitsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UnitsEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
    };
  }

  UnitsEntry copyWith({int? id, String? title}) => UnitsEntry(
        id: id ?? this.id,
        title: title ?? this.title,
      );
  UnitsEntry copyWithCompanion(UnitsEntriesCompanion data) {
    return UnitsEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UnitsEntry(')
          ..write('id: $id, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UnitsEntry && other.id == this.id && other.title == this.title);
}

class UnitsEntriesCompanion extends UpdateCompanion<UnitsEntry> {
  final Value<int> id;
  final Value<String> title;
  const UnitsEntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
  });
  UnitsEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
  }) : title = Value(title);
  static Insertable<UnitsEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
    });
  }

  UnitsEntriesCompanion copyWith({Value<int>? id, Value<String>? title}) {
    return UnitsEntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UnitsEntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }
}

class $VocabularyEntriesTable extends VocabularyEntries
    with TableInfo<$VocabularyEntriesTable, VocabularyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
      'word', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
      'meaning', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exampleMeta =
      const VerificationMeta('example');
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
      'example', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pronunciationMeta =
      const VerificationMeta('pronunciation');
  @override
  late final GeneratedColumn<String> pronunciation = GeneratedColumn<String>(
      'pronunciation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wrongCountMeta =
      const VerificationMeta('wrongCount');
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
      'wrong_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewedMeta =
      const VerificationMeta('lastReviewed');
  @override
  late final GeneratedColumn<DateTime> lastReviewed = GeneratedColumn<DateTime>(
      'last_reviewed', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextReviewMeta =
      const VerificationMeta('nextReview');
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
      'next_review', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _unitIdMeta = const VerificationMeta('unitId');
  @override
  late final GeneratedColumn<int> unitId = GeneratedColumn<int>(
      'unit_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES units_entries (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        word,
        meaning,
        example,
        pronunciation,
        language,
        level,
        correctCount,
        wrongCount,
        lastReviewed,
        nextReview,
        unitId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_entries';
  @override
  VerificationContext validateIntegrity(Insertable<VocabularyEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
          _wordMeta, word.isAcceptableOrUnknown(data['word']!, _wordMeta));
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('example')) {
      context.handle(_exampleMeta,
          example.isAcceptableOrUnknown(data['example']!, _exampleMeta));
    }
    if (data.containsKey('pronunciation')) {
      context.handle(
          _pronunciationMeta,
          pronunciation.isAcceptableOrUnknown(
              data['pronunciation']!, _pronunciationMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
          _wrongCountMeta,
          wrongCount.isAcceptableOrUnknown(
              data['wrong_count']!, _wrongCountMeta));
    }
    if (data.containsKey('last_reviewed')) {
      context.handle(
          _lastReviewedMeta,
          lastReviewed.isAcceptableOrUnknown(
              data['last_reviewed']!, _lastReviewedMeta));
    }
    if (data.containsKey('next_review')) {
      context.handle(
          _nextReviewMeta,
          nextReview.isAcceptableOrUnknown(
              data['next_review']!, _nextReviewMeta));
    }
    if (data.containsKey('unit_id')) {
      context.handle(_unitIdMeta,
          unitId.isAcceptableOrUnknown(data['unit_id']!, _unitIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      example: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example']),
      pronunciation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pronunciation']),
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language']),
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      wrongCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wrong_count'])!,
      lastReviewed: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed']),
      nextReview: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_review']),
      unitId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}unit_id']),
    );
  }

  @override
  $VocabularyEntriesTable createAlias(String alias) {
    return $VocabularyEntriesTable(attachedDatabase, alias);
  }
}

class VocabularyEntry extends DataClass implements Insertable<VocabularyEntry> {
  final int id;
  final String word;
  final String meaning;
  final String? example;
  final String? pronunciation;
  final String? language;
  final int level;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final int? unitId;

  const VocabularyEntry(
      {required this.id,
      required this.word,
      required this.meaning,
      this.example,
      this.pronunciation,
      this.language,
      required this.level,
      required this.correctCount,
      required this.wrongCount,
      this.lastReviewed,
      this.nextReview,
      this.unitId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || pronunciation != null) {
      map['pronunciation'] = Variable<String>(pronunciation);
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['level'] = Variable<int>(level);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    if (!nullToAbsent || lastReviewed != null) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed);
    }
    if (!nullToAbsent || nextReview != null) {
      map['next_review'] = Variable<DateTime>(nextReview);
    }
    if (!nullToAbsent || unitId != null) {
      map['unit_id'] = Variable<int>(unitId);
    }
    return map;
  }

  VocabularyEntriesCompanion toCompanion(bool nullToAbsent) {
    return VocabularyEntriesCompanion(
      id: Value(id),
      word: Value(word),
      meaning: Value(meaning),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      pronunciation: pronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciation),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      level: Value(level),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      lastReviewed: lastReviewed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewed),
      nextReview: nextReview == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReview),
      unitId:
          unitId == null && nullToAbsent ? const Value.absent() : Value(unitId),
    );
  }

  factory VocabularyEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyEntry(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      meaning: serializer.fromJson<String>(json['meaning']),
      example: serializer.fromJson<String?>(json['example']),
      pronunciation: serializer.fromJson<String?>(json['pronunciation']),
      language: serializer.fromJson<String?>(json['language']),
      level: serializer.fromJson<int>(json['level']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      lastReviewed: serializer.fromJson<DateTime?>(json['lastReviewed']),
      nextReview: serializer.fromJson<DateTime?>(json['nextReview']),
      unitId: serializer.fromJson<int?>(json['unitId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'meaning': serializer.toJson<String>(meaning),
      'example': serializer.toJson<String?>(example),
      'pronunciation': serializer.toJson<String?>(pronunciation),
      'language': serializer.toJson<String?>(language),
      'level': serializer.toJson<int>(level),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'lastReviewed': serializer.toJson<DateTime?>(lastReviewed),
      'nextReview': serializer.toJson<DateTime?>(nextReview),
      'unitId': serializer.toJson<int?>(unitId),
    };
  }

  VocabularyEntry copyWith(
          {int? id,
          String? word,
          String? meaning,
          Value<String?> example = const Value.absent(),
          Value<String?> pronunciation = const Value.absent(),
          Value<String?> language = const Value.absent(),
          int? level,
          int? correctCount,
          int? wrongCount,
          Value<DateTime?> lastReviewed = const Value.absent(),
          Value<DateTime?> nextReview = const Value.absent(),
          Value<int?> unitId = const Value.absent()}) =>
      VocabularyEntry(
        id: id ?? this.id,
        word: word ?? this.word,
        meaning: meaning ?? this.meaning,
        example: example.present ? example.value : this.example,
        pronunciation:
            pronunciation.present ? pronunciation.value : this.pronunciation,
        language: language.present ? language.value : this.language,
        level: level ?? this.level,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        lastReviewed:
            lastReviewed.present ? lastReviewed.value : this.lastReviewed,
        nextReview: nextReview.present ? nextReview.value : this.nextReview,
        unitId: unitId.present ? unitId.value : this.unitId,
      );
  VocabularyEntry copyWithCompanion(VocabularyEntriesCompanion data) {
    return VocabularyEntry(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      example: data.example.present ? data.example.value : this.example,
      pronunciation: data.pronunciation.present
          ? data.pronunciation.value
          : this.pronunciation,
      language: data.language.present ? data.language.value : this.language,
      level: data.level.present ? data.level.value : this.level,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount:
          data.wrongCount.present ? data.wrongCount.value : this.wrongCount,
      lastReviewed: data.lastReviewed.present
          ? data.lastReviewed.value
          : this.lastReviewed,
      nextReview:
          data.nextReview.present ? data.nextReview.value : this.nextReview,
      unitId: data.unitId.present ? data.unitId.value : this.unitId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntry(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('example: $example, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('language: $language, ')
          ..write('level: $level, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('nextReview: $nextReview, ')
          ..write('unitId: $unitId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      word,
      meaning,
      example,
      pronunciation,
      language,
      level,
      correctCount,
      wrongCount,
      lastReviewed,
      nextReview,
      unitId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyEntry &&
          other.id == this.id &&
          other.word == this.word &&
          other.meaning == this.meaning &&
          other.example == this.example &&
          other.pronunciation == this.pronunciation &&
          other.language == this.language &&
          other.level == this.level &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.lastReviewed == this.lastReviewed &&
          other.nextReview == this.nextReview &&
          other.unitId == this.unitId);
}

class VocabularyEntriesCompanion extends UpdateCompanion<VocabularyEntry> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> meaning;
  final Value<String?> example;
  final Value<String?> pronunciation;
  final Value<String?> language;
  final Value<int> level;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<DateTime?> lastReviewed;
  final Value<DateTime?> nextReview;
  final Value<int?> unitId;
  const VocabularyEntriesCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.meaning = const Value.absent(),
    this.example = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.language = const Value.absent(),
    this.level = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.unitId = const Value.absent(),
  });
  VocabularyEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String meaning,
    this.example = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.language = const Value.absent(),
    this.level = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.unitId = const Value.absent(),
  })  : word = Value(word),
        meaning = Value(meaning);
  static Insertable<VocabularyEntry> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? meaning,
    Expression<String>? example,
    Expression<String>? pronunciation,
    Expression<String>? language,
    Expression<int>? level,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<DateTime>? lastReviewed,
    Expression<DateTime>? nextReview,
    Expression<int>? unitId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (meaning != null) 'meaning': meaning,
      if (example != null) 'example': example,
      if (pronunciation != null) 'pronunciation': pronunciation,
      if (language != null) 'language': language,
      if (level != null) 'level': level,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (lastReviewed != null) 'last_reviewed': lastReviewed,
      if (nextReview != null) 'next_review': nextReview,
      if (unitId != null) 'unit_id': unitId,
    });
  }

  VocabularyEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? word,
      Value<String>? meaning,
      Value<String?>? example,
      Value<String?>? pronunciation,
      Value<String?>? language,
      Value<int>? level,
      Value<int>? correctCount,
      Value<int>? wrongCount,
      Value<DateTime?>? lastReviewed,
      Value<DateTime?>? nextReview,
      Value<int?>? unitId}) {
    return VocabularyEntriesCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      pronunciation: pronunciation ?? this.pronunciation,
      language: language ?? this.language,
      level: level ?? this.level,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      unitId: unitId ?? this.unitId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (pronunciation.present) {
      map['pronunciation'] = Variable<String>(pronunciation.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (lastReviewed.present) {
      map['last_reviewed'] = Variable<DateTime>(lastReviewed.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (unitId.present) {
      map['unit_id'] = Variable<int>(unitId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('example: $example, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('language: $language, ')
          ..write('level: $level, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('nextReview: $nextReview, ')
          ..write('unitId: $unitId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UnitsEntriesTable unitsEntries = $UnitsEntriesTable(this);
  late final $VocabularyEntriesTable vocabularyEntries =
      $VocabularyEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [unitsEntries, vocabularyEntries];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('units_entries',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('vocabulary_entries', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$UnitsEntriesTableCreateCompanionBuilder = UnitsEntriesCompanion
    Function({
  Value<int> id,
  required String title,
});
typedef $$UnitsEntriesTableUpdateCompanionBuilder = UnitsEntriesCompanion
    Function({
  Value<int> id,
  Value<String> title,
});

final class $$UnitsEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $UnitsEntriesTable, UnitsEntry> {
  $$UnitsEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VocabularyEntriesTable, List<VocabularyEntry>>
      _vocabularyEntriesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vocabularyEntries,
              aliasName: $_aliasNameGenerator(
                  db.unitsEntries.id, db.vocabularyEntries.unitId));

  $$VocabularyEntriesTableProcessedTableManager get vocabularyEntriesRefs {
    final manager =
        $$VocabularyEntriesTableTableManager($_db, $_db.vocabularyEntries)
            .filter((f) => f.unitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_vocabularyEntriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UnitsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $UnitsEntriesTable> {
  $$UnitsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  Expression<bool> vocabularyEntriesRefs(
      Expression<bool> Function($$VocabularyEntriesTableFilterComposer f) f) {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabularyEntries,
        getReferencedColumn: (t) => t.unitId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyEntriesTableFilterComposer(
              $db: $db,
              $table: $db.vocabularyEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UnitsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UnitsEntriesTable> {
  $$UnitsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));
}

class $$UnitsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UnitsEntriesTable> {
  $$UnitsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  Expression<T> vocabularyEntriesRefs<T extends Object>(
      Expression<T> Function($$VocabularyEntriesTableAnnotationComposer a) f) {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.vocabularyEntries,
            getReferencedColumn: (t) => t.unitId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$VocabularyEntriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.vocabularyEntries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UnitsEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UnitsEntriesTable,
    UnitsEntry,
    $$UnitsEntriesTableFilterComposer,
    $$UnitsEntriesTableOrderingComposer,
    $$UnitsEntriesTableAnnotationComposer,
    $$UnitsEntriesTableCreateCompanionBuilder,
    $$UnitsEntriesTableUpdateCompanionBuilder,
    (UnitsEntry, $$UnitsEntriesTableReferences),
    UnitsEntry,
    PrefetchHooks Function({bool vocabularyEntriesRefs})> {
  $$UnitsEntriesTableTableManager(_$AppDatabase db, $UnitsEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UnitsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UnitsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UnitsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
          }) =>
              UnitsEntriesCompanion(
            id: id,
            title: title,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
          }) =>
              UnitsEntriesCompanion.insert(
            id: id,
            title: title,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UnitsEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({vocabularyEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vocabularyEntriesRefs) db.vocabularyEntries
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vocabularyEntriesRefs)
                    await $_getPrefetchedData<UnitsEntry, $UnitsEntriesTable,
                            VocabularyEntry>(
                        currentTable: table,
                        referencedTable: $$UnitsEntriesTableReferences
                            ._vocabularyEntriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UnitsEntriesTableReferences(db, table, p0)
                                .vocabularyEntriesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.unitId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UnitsEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UnitsEntriesTable,
    UnitsEntry,
    $$UnitsEntriesTableFilterComposer,
    $$UnitsEntriesTableOrderingComposer,
    $$UnitsEntriesTableAnnotationComposer,
    $$UnitsEntriesTableCreateCompanionBuilder,
    $$UnitsEntriesTableUpdateCompanionBuilder,
    (UnitsEntry, $$UnitsEntriesTableReferences),
    UnitsEntry,
    PrefetchHooks Function({bool vocabularyEntriesRefs})>;
typedef $$VocabularyEntriesTableCreateCompanionBuilder
    = VocabularyEntriesCompanion Function({
  Value<int> id,
  required String word,
  required String meaning,
  Value<String?> example,
  Value<String?> pronunciation,
  Value<String?> language,
  Value<int> level,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastReviewed,
  Value<DateTime?> nextReview,
  Value<int?> unitId,
});
typedef $$VocabularyEntriesTableUpdateCompanionBuilder
    = VocabularyEntriesCompanion Function({
  Value<int> id,
  Value<String> word,
  Value<String> meaning,
  Value<String?> example,
  Value<String?> pronunciation,
  Value<String?> language,
  Value<int> level,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastReviewed,
  Value<DateTime?> nextReview,
  Value<int?> unitId,
});

final class $$VocabularyEntriesTableReferences extends BaseReferences<
    _$AppDatabase, $VocabularyEntriesTable, VocabularyEntry> {
  $$VocabularyEntriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UnitsEntriesTable _unitIdTable(_$AppDatabase db) =>
      db.unitsEntries.createAlias($_aliasNameGenerator(
          db.vocabularyEntries.unitId, db.unitsEntries.id));

  $$UnitsEntriesTableProcessedTableManager? get unitId {
    final $_column = $_itemColumn<int>('unit_id');
    if ($_column == null) return null;
    final manager = $$UnitsEntriesTableTableManager($_db, $_db.unitsEntries)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_unitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VocabularyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get example => $composableBuilder(
      column: $table.example, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pronunciation => $composableBuilder(
      column: $table.pronunciation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewed => $composableBuilder(
      column: $table.lastReviewed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => ColumnFilters(column));

  $$UnitsEntriesTableFilterComposer get unitId {
    final $$UnitsEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.unitsEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsEntriesTableFilterComposer(
              $db: $db,
              $table: $db.unitsEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaning => $composableBuilder(
      column: $table.meaning, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get example => $composableBuilder(
      column: $table.example, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pronunciation => $composableBuilder(
      column: $table.pronunciation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewed => $composableBuilder(
      column: $table.lastReviewed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => ColumnOrderings(column));

  $$UnitsEntriesTableOrderingComposer get unitId {
    final $$UnitsEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.unitsEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.unitsEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyEntriesTable> {
  $$VocabularyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get pronunciation => $composableBuilder(
      column: $table.pronunciation, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewed => $composableBuilder(
      column: $table.lastReviewed, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => column);

  $$UnitsEntriesTableAnnotationComposer get unitId {
    final $$UnitsEntriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.unitId,
        referencedTable: $db.unitsEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UnitsEntriesTableAnnotationComposer(
              $db: $db,
              $table: $db.unitsEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyEntriesTable,
    VocabularyEntry,
    $$VocabularyEntriesTableFilterComposer,
    $$VocabularyEntriesTableOrderingComposer,
    $$VocabularyEntriesTableAnnotationComposer,
    $$VocabularyEntriesTableCreateCompanionBuilder,
    $$VocabularyEntriesTableUpdateCompanionBuilder,
    (VocabularyEntry, $$VocabularyEntriesTableReferences),
    VocabularyEntry,
    PrefetchHooks Function({bool unitId})> {
  $$VocabularyEntriesTableTableManager(
      _$AppDatabase db, $VocabularyEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String?> example = const Value.absent(),
            Value<String?> pronunciation = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime?> lastReviewed = const Value.absent(),
            Value<DateTime?> nextReview = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
          }) =>
              VocabularyEntriesCompanion(
            id: id,
            word: word,
            meaning: meaning,
            example: example,
            pronunciation: pronunciation,
            language: language,
            level: level,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewed: lastReviewed,
            nextReview: nextReview,
            unitId: unitId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String word,
            required String meaning,
            Value<String?> example = const Value.absent(),
            Value<String?> pronunciation = const Value.absent(),
            Value<String?> language = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime?> lastReviewed = const Value.absent(),
            Value<DateTime?> nextReview = const Value.absent(),
            Value<int?> unitId = const Value.absent(),
          }) =>
              VocabularyEntriesCompanion.insert(
            id: id,
            word: word,
            meaning: meaning,
            example: example,
            pronunciation: pronunciation,
            language: language,
            level: level,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewed: lastReviewed,
            nextReview: nextReview,
            unitId: unitId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VocabularyEntriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({unitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (unitId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.unitId,
                    referencedTable:
                        $$VocabularyEntriesTableReferences._unitIdTable(db),
                    referencedColumn:
                        $$VocabularyEntriesTableReferences._unitIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$VocabularyEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VocabularyEntriesTable,
    VocabularyEntry,
    $$VocabularyEntriesTableFilterComposer,
    $$VocabularyEntriesTableOrderingComposer,
    $$VocabularyEntriesTableAnnotationComposer,
    $$VocabularyEntriesTableCreateCompanionBuilder,
    $$VocabularyEntriesTableUpdateCompanionBuilder,
    (VocabularyEntry, $$VocabularyEntriesTableReferences),
    VocabularyEntry,
    PrefetchHooks Function({bool unitId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UnitsEntriesTableTableManager get unitsEntries =>
      $$UnitsEntriesTableTableManager(_db, _db.unitsEntries);
  $$VocabularyEntriesTableTableManager get vocabularyEntries =>
      $$VocabularyEntriesTableTableManager(_db, _db.vocabularyEntries);
}

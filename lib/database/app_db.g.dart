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
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 225),
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
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_favorite" IN (0, 1))'));
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
        isFavorite,
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
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
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
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite']),
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
  final bool? isFavorite;
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
      this.isFavorite,
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
    if (!nullToAbsent || isFavorite != null) {
      map['is_favorite'] = Variable<bool>(isFavorite);
    }
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
      isFavorite: isFavorite == null && nullToAbsent
          ? const Value.absent()
          : Value(isFavorite),
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
      isFavorite: serializer.fromJson<bool?>(json['isFavorite']),
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
      'isFavorite': serializer.toJson<bool?>(isFavorite),
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
          Value<bool?> isFavorite = const Value.absent(),
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
        isFavorite: isFavorite.present ? isFavorite.value : this.isFavorite,
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
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
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
          ..write('isFavorite: $isFavorite, ')
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
      isFavorite,
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
          other.isFavorite == this.isFavorite &&
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
  final Value<bool?> isFavorite;
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
    this.isFavorite = const Value.absent(),
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
    this.isFavorite = const Value.absent(),
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
    Expression<bool>? isFavorite,
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
      if (isFavorite != null) 'is_favorite': isFavorite,
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
      Value<bool?>? isFavorite,
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
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
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
          ..write('isFavorite: $isFavorite, ')
          ..write('lastReviewed: $lastReviewed, ')
          ..write('nextReview: $nextReview, ')
          ..write('unitId: $unitId')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tagNameMeta =
      const VerificationMeta('tagName');
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
      'tag_name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _targetLanguageMeta =
      const VerificationMeta('targetLanguage');
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
      'target_language', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, tagName, targetLanguage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tag_name')) {
      context.handle(_tagNameMeta,
          tagName.isAcceptableOrUnknown(data['tag_name']!, _tagNameMeta));
    } else if (isInserting) {
      context.missing(_tagNameMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
          _targetLanguageMeta,
          targetLanguage.isAcceptableOrUnknown(
              data['target_language']!, _targetLanguageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tagName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_name'])!,
      targetLanguage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_language']),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String tagName;
  final String? targetLanguage;
  const Tag({required this.id, required this.tagName, this.targetLanguage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tag_name'] = Variable<String>(tagName);
    if (!nullToAbsent || targetLanguage != null) {
      map['target_language'] = Variable<String>(targetLanguage);
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      tagName: Value(tagName),
      targetLanguage: targetLanguage == null && nullToAbsent
          ? const Value.absent()
          : Value(targetLanguage),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      tagName: serializer.fromJson<String>(json['tagName']),
      targetLanguage: serializer.fromJson<String?>(json['targetLanguage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tagName': serializer.toJson<String>(tagName),
      'targetLanguage': serializer.toJson<String?>(targetLanguage),
    };
  }

  Tag copyWith(
          {int? id,
          String? tagName,
          Value<String?> targetLanguage = const Value.absent()}) =>
      Tag(
        id: id ?? this.id,
        tagName: tagName ?? this.tagName,
        targetLanguage:
            targetLanguage.present ? targetLanguage.value : this.targetLanguage,
      );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('tagName: $tagName, ')
          ..write('targetLanguage: $targetLanguage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tagName, targetLanguage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.tagName == this.tagName &&
          other.targetLanguage == this.targetLanguage);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> tagName;
  final Value<String?> targetLanguage;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.tagName = const Value.absent(),
    this.targetLanguage = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    required String tagName,
    this.targetLanguage = const Value.absent(),
  }) : tagName = Value(tagName);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? tagName,
    Expression<String>? targetLanguage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tagName != null) 'tag_name': tagName,
      if (targetLanguage != null) 'target_language': targetLanguage,
    });
  }

  TagsCompanion copyWith(
      {Value<int>? id,
      Value<String>? tagName,
      Value<String?>? targetLanguage}) {
    return TagsCompanion(
      id: id ?? this.id,
      tagName: tagName ?? this.tagName,
      targetLanguage: targetLanguage ?? this.targetLanguage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tagName.present) {
      map['tag_name'] = Variable<String>(tagName.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('tagName: $tagName, ')
          ..write('targetLanguage: $targetLanguage')
          ..write(')'))
        .toString();
  }
}

class $VocabularyTagsTable extends VocabularyTags
    with TableInfo<$VocabularyTagsTable, VocabularyTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vocabulary_entries (id)'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tags (id)'));
  @override
  List<GeneratedColumn> get $columns => [wordId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_tags';
  @override
  VerificationContext validateIntegrity(Insertable<VocabularyTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, tagId};
  @override
  VocabularyTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyTag(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $VocabularyTagsTable createAlias(String alias) {
    return $VocabularyTagsTable(attachedDatabase, alias);
  }
}

class VocabularyTag extends DataClass implements Insertable<VocabularyTag> {
  final int wordId;
  final int tagId;
  const VocabularyTag({required this.wordId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  VocabularyTagsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyTagsCompanion(
      wordId: Value(wordId),
      tagId: Value(tagId),
    );
  }

  factory VocabularyTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyTag(
      wordId: serializer.fromJson<int>(json['wordId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  VocabularyTag copyWith({int? wordId, int? tagId}) => VocabularyTag(
        wordId: wordId ?? this.wordId,
        tagId: tagId ?? this.tagId,
      );
  VocabularyTag copyWithCompanion(VocabularyTagsCompanion data) {
    return VocabularyTag(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyTag(')
          ..write('wordId: $wordId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyTag &&
          other.wordId == this.wordId &&
          other.tagId == this.tagId);
}

class VocabularyTagsCompanion extends UpdateCompanion<VocabularyTag> {
  final Value<int> wordId;
  final Value<int> tagId;
  final Value<int> rowid;
  const VocabularyTagsCompanion({
    this.wordId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyTagsCompanion.insert({
    required int wordId,
    required int tagId,
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        tagId = Value(tagId);
  static Insertable<VocabularyTag> custom({
    Expression<int>? wordId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyTagsCompanion copyWith(
      {Value<int>? wordId, Value<int>? tagId, Value<int>? rowid}) {
    return VocabularyTagsCompanion(
      wordId: wordId ?? this.wordId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyTagsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersEntrieTable extends UsersEntrie
    with TableInfo<$UsersEntrieTable, UsersEntrieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersEntrieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keyOpenMeta =
      const VerificationMeta('keyOpen');
  @override
  late final GeneratedColumn<String> keyOpen = GeneratedColumn<String>(
      'key_open', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _currentStreakMeta =
      const VerificationMeta('currentStreak');
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
      'current_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _longestStreakMeta =
      const VerificationMeta('longestStreak');
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
      'longest_streak', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalLearnedMeta =
      const VerificationMeta('totalLearned');
  @override
  late final GeneratedColumn<int> totalLearned = GeneratedColumn<int>(
      'total_learned', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastActiveDateMeta =
      const VerificationMeta('lastActiveDate');
  @override
  late final GeneratedColumn<DateTime> lastActiveDate =
      GeneratedColumn<DateTime>('last_active_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _gemsMeta = const VerificationMeta('gems');
  @override
  late final GeneratedColumn<int> gems = GeneratedColumn<int>(
      'gems', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _experienceMeta =
      const VerificationMeta('experience');
  @override
  late final GeneratedColumn<int> experience = GeneratedColumn<int>(
      'experience', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        keyOpen,
        username,
        currentStreak,
        longestStreak,
        totalLearned,
        lastActiveDate,
        gems,
        level,
        experience
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_entrie';
  @override
  VerificationContext validateIntegrity(Insertable<UsersEntrieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key_open')) {
      context.handle(_keyOpenMeta,
          keyOpen.isAcceptableOrUnknown(data['key_open']!, _keyOpenMeta));
    } else if (isInserting) {
      context.missing(_keyOpenMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('current_streak')) {
      context.handle(
          _currentStreakMeta,
          currentStreak.isAcceptableOrUnknown(
              data['current_streak']!, _currentStreakMeta));
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
          _longestStreakMeta,
          longestStreak.isAcceptableOrUnknown(
              data['longest_streak']!, _longestStreakMeta));
    }
    if (data.containsKey('total_learned')) {
      context.handle(
          _totalLearnedMeta,
          totalLearned.isAcceptableOrUnknown(
              data['total_learned']!, _totalLearnedMeta));
    }
    if (data.containsKey('last_active_date')) {
      context.handle(
          _lastActiveDateMeta,
          lastActiveDate.isAcceptableOrUnknown(
              data['last_active_date']!, _lastActiveDateMeta));
    }
    if (data.containsKey('gems')) {
      context.handle(
          _gemsMeta, gems.isAcceptableOrUnknown(data['gems']!, _gemsMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('experience')) {
      context.handle(
          _experienceMeta,
          experience.isAcceptableOrUnknown(
              data['experience']!, _experienceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {keyOpen};
  @override
  UsersEntrieData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersEntrieData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id']),
      keyOpen: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_open'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      currentStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_streak'])!,
      longestStreak: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}longest_streak'])!,
      totalLearned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_learned'])!,
      lastActiveDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_active_date']),
      gems: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gems'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      experience: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}experience'])!,
    );
  }

  @override
  $UsersEntrieTable createAlias(String alias) {
    return $UsersEntrieTable(attachedDatabase, alias);
  }
}

class UsersEntrieData extends DataClass implements Insertable<UsersEntrieData> {
  final String? id;
  final String keyOpen;
  final String username;
  final int currentStreak;
  final int longestStreak;
  final int totalLearned;
  final DateTime? lastActiveDate;
  final int gems;
  final int level;
  final int experience;
  const UsersEntrieData(
      {this.id,
      required this.keyOpen,
      required this.username,
      required this.currentStreak,
      required this.longestStreak,
      required this.totalLearned,
      this.lastActiveDate,
      required this.gems,
      required this.level,
      required this.experience});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['key_open'] = Variable<String>(keyOpen);
    map['username'] = Variable<String>(username);
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['total_learned'] = Variable<int>(totalLearned);
    if (!nullToAbsent || lastActiveDate != null) {
      map['last_active_date'] = Variable<DateTime>(lastActiveDate);
    }
    map['gems'] = Variable<int>(gems);
    map['level'] = Variable<int>(level);
    map['experience'] = Variable<int>(experience);
    return map;
  }

  UsersEntrieCompanion toCompanion(bool nullToAbsent) {
    return UsersEntrieCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      keyOpen: Value(keyOpen),
      username: Value(username),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      totalLearned: Value(totalLearned),
      lastActiveDate: lastActiveDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActiveDate),
      gems: Value(gems),
      level: Value(level),
      experience: Value(experience),
    );
  }

  factory UsersEntrieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersEntrieData(
      id: serializer.fromJson<String?>(json['id']),
      keyOpen: serializer.fromJson<String>(json['keyOpen']),
      username: serializer.fromJson<String>(json['username']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      totalLearned: serializer.fromJson<int>(json['totalLearned']),
      lastActiveDate: serializer.fromJson<DateTime?>(json['lastActiveDate']),
      gems: serializer.fromJson<int>(json['gems']),
      level: serializer.fromJson<int>(json['level']),
      experience: serializer.fromJson<int>(json['experience']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'keyOpen': serializer.toJson<String>(keyOpen),
      'username': serializer.toJson<String>(username),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'totalLearned': serializer.toJson<int>(totalLearned),
      'lastActiveDate': serializer.toJson<DateTime?>(lastActiveDate),
      'gems': serializer.toJson<int>(gems),
      'level': serializer.toJson<int>(level),
      'experience': serializer.toJson<int>(experience),
    };
  }

  UsersEntrieData copyWith(
          {Value<String?> id = const Value.absent(),
          String? keyOpen,
          String? username,
          int? currentStreak,
          int? longestStreak,
          int? totalLearned,
          Value<DateTime?> lastActiveDate = const Value.absent(),
          int? gems,
          int? level,
          int? experience}) =>
      UsersEntrieData(
        id: id.present ? id.value : this.id,
        keyOpen: keyOpen ?? this.keyOpen,
        username: username ?? this.username,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        totalLearned: totalLearned ?? this.totalLearned,
        lastActiveDate:
            lastActiveDate.present ? lastActiveDate.value : this.lastActiveDate,
        gems: gems ?? this.gems,
        level: level ?? this.level,
        experience: experience ?? this.experience,
      );
  UsersEntrieData copyWithCompanion(UsersEntrieCompanion data) {
    return UsersEntrieData(
      id: data.id.present ? data.id.value : this.id,
      keyOpen: data.keyOpen.present ? data.keyOpen.value : this.keyOpen,
      username: data.username.present ? data.username.value : this.username,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      totalLearned: data.totalLearned.present
          ? data.totalLearned.value
          : this.totalLearned,
      lastActiveDate: data.lastActiveDate.present
          ? data.lastActiveDate.value
          : this.lastActiveDate,
      gems: data.gems.present ? data.gems.value : this.gems,
      level: data.level.present ? data.level.value : this.level,
      experience:
          data.experience.present ? data.experience.value : this.experience,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersEntrieData(')
          ..write('id: $id, ')
          ..write('keyOpen: $keyOpen, ')
          ..write('username: $username, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('totalLearned: $totalLearned, ')
          ..write('lastActiveDate: $lastActiveDate, ')
          ..write('gems: $gems, ')
          ..write('level: $level, ')
          ..write('experience: $experience')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyOpen, username, currentStreak,
      longestStreak, totalLearned, lastActiveDate, gems, level, experience);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersEntrieData &&
          other.id == this.id &&
          other.keyOpen == this.keyOpen &&
          other.username == this.username &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.totalLearned == this.totalLearned &&
          other.lastActiveDate == this.lastActiveDate &&
          other.gems == this.gems &&
          other.level == this.level &&
          other.experience == this.experience);
}

class UsersEntrieCompanion extends UpdateCompanion<UsersEntrieData> {
  final Value<String?> id;
  final Value<String> keyOpen;
  final Value<String> username;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<int> totalLearned;
  final Value<DateTime?> lastActiveDate;
  final Value<int> gems;
  final Value<int> level;
  final Value<int> experience;
  final Value<int> rowid;
  const UsersEntrieCompanion({
    this.id = const Value.absent(),
    this.keyOpen = const Value.absent(),
    this.username = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.totalLearned = const Value.absent(),
    this.lastActiveDate = const Value.absent(),
    this.gems = const Value.absent(),
    this.level = const Value.absent(),
    this.experience = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersEntrieCompanion.insert({
    this.id = const Value.absent(),
    required String keyOpen,
    required String username,
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.totalLearned = const Value.absent(),
    this.lastActiveDate = const Value.absent(),
    this.gems = const Value.absent(),
    this.level = const Value.absent(),
    this.experience = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : keyOpen = Value(keyOpen),
        username = Value(username);
  static Insertable<UsersEntrieData> custom({
    Expression<String>? id,
    Expression<String>? keyOpen,
    Expression<String>? username,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<int>? totalLearned,
    Expression<DateTime>? lastActiveDate,
    Expression<int>? gems,
    Expression<int>? level,
    Expression<int>? experience,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyOpen != null) 'key_open': keyOpen,
      if (username != null) 'username': username,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (totalLearned != null) 'total_learned': totalLearned,
      if (lastActiveDate != null) 'last_active_date': lastActiveDate,
      if (gems != null) 'gems': gems,
      if (level != null) 'level': level,
      if (experience != null) 'experience': experience,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersEntrieCompanion copyWith(
      {Value<String?>? id,
      Value<String>? keyOpen,
      Value<String>? username,
      Value<int>? currentStreak,
      Value<int>? longestStreak,
      Value<int>? totalLearned,
      Value<DateTime?>? lastActiveDate,
      Value<int>? gems,
      Value<int>? level,
      Value<int>? experience,
      Value<int>? rowid}) {
    return UsersEntrieCompanion(
      id: id ?? this.id,
      keyOpen: keyOpen ?? this.keyOpen,
      username: username ?? this.username,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLearned: totalLearned ?? this.totalLearned,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      gems: gems ?? this.gems,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (keyOpen.present) {
      map['key_open'] = Variable<String>(keyOpen.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (totalLearned.present) {
      map['total_learned'] = Variable<int>(totalLearned.value);
    }
    if (lastActiveDate.present) {
      map['last_active_date'] = Variable<DateTime>(lastActiveDate.value);
    }
    if (gems.present) {
      map['gems'] = Variable<int>(gems.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (experience.present) {
      map['experience'] = Variable<int>(experience.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersEntrieCompanion(')
          ..write('id: $id, ')
          ..write('keyOpen: $keyOpen, ')
          ..write('username: $username, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('totalLearned: $totalLearned, ')
          ..write('lastActiveDate: $lastActiveDate, ')
          ..write('gems: $gems, ')
          ..write('level: $level, ')
          ..write('experience: $experience, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserActivitiesEntrieTable extends UserActivitiesEntrie
    with TableInfo<$UserActivitiesEntrieTable, UserActivitiesEntrieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserActivitiesEntrieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userKeyMeta =
      const VerificationMeta('userKey');
  @override
  late final GeneratedColumn<String> userKey = GeneratedColumn<String>(
      'user_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES users_entrie (key_open)'));
  static const VerificationMeta _activityDateMeta =
      const VerificationMeta('activityDate');
  @override
  late final GeneratedColumn<DateTime> activityDate = GeneratedColumn<DateTime>(
      'activity_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, userKey, activityDate, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_activities_entrie';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserActivitiesEntrieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_key')) {
      context.handle(_userKeyMeta,
          userKey.isAcceptableOrUnknown(data['user_key']!, _userKeyMeta));
    } else if (isInserting) {
      context.missing(_userKeyMeta);
    }
    if (data.containsKey('activity_date')) {
      context.handle(
          _activityDateMeta,
          activityDate.isAcceptableOrUnknown(
              data['activity_date']!, _activityDateMeta));
    } else if (isInserting) {
      context.missing(_activityDateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserActivitiesEntrieData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserActivitiesEntrieData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_key'])!,
      activityDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}activity_date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $UserActivitiesEntrieTable createAlias(String alias) {
    return $UserActivitiesEntrieTable(attachedDatabase, alias);
  }
}

class UserActivitiesEntrieData extends DataClass
    implements Insertable<UserActivitiesEntrieData> {
  final int id;
  final String userKey;
  final DateTime activityDate;
  final String? note;
  const UserActivitiesEntrieData(
      {required this.id,
      required this.userKey,
      required this.activityDate,
      this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_key'] = Variable<String>(userKey);
    map['activity_date'] = Variable<DateTime>(activityDate);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  UserActivitiesEntrieCompanion toCompanion(bool nullToAbsent) {
    return UserActivitiesEntrieCompanion(
      id: Value(id),
      userKey: Value(userKey),
      activityDate: Value(activityDate),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory UserActivitiesEntrieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserActivitiesEntrieData(
      id: serializer.fromJson<int>(json['id']),
      userKey: serializer.fromJson<String>(json['userKey']),
      activityDate: serializer.fromJson<DateTime>(json['activityDate']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userKey': serializer.toJson<String>(userKey),
      'activityDate': serializer.toJson<DateTime>(activityDate),
      'note': serializer.toJson<String?>(note),
    };
  }

  UserActivitiesEntrieData copyWith(
          {int? id,
          String? userKey,
          DateTime? activityDate,
          Value<String?> note = const Value.absent()}) =>
      UserActivitiesEntrieData(
        id: id ?? this.id,
        userKey: userKey ?? this.userKey,
        activityDate: activityDate ?? this.activityDate,
        note: note.present ? note.value : this.note,
      );
  UserActivitiesEntrieData copyWithCompanion(
      UserActivitiesEntrieCompanion data) {
    return UserActivitiesEntrieData(
      id: data.id.present ? data.id.value : this.id,
      userKey: data.userKey.present ? data.userKey.value : this.userKey,
      activityDate: data.activityDate.present
          ? data.activityDate.value
          : this.activityDate,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserActivitiesEntrieData(')
          ..write('id: $id, ')
          ..write('userKey: $userKey, ')
          ..write('activityDate: $activityDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userKey, activityDate, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserActivitiesEntrieData &&
          other.id == this.id &&
          other.userKey == this.userKey &&
          other.activityDate == this.activityDate &&
          other.note == this.note);
}

class UserActivitiesEntrieCompanion
    extends UpdateCompanion<UserActivitiesEntrieData> {
  final Value<int> id;
  final Value<String> userKey;
  final Value<DateTime> activityDate;
  final Value<String?> note;
  const UserActivitiesEntrieCompanion({
    this.id = const Value.absent(),
    this.userKey = const Value.absent(),
    this.activityDate = const Value.absent(),
    this.note = const Value.absent(),
  });
  UserActivitiesEntrieCompanion.insert({
    this.id = const Value.absent(),
    required String userKey,
    required DateTime activityDate,
    this.note = const Value.absent(),
  })  : userKey = Value(userKey),
        activityDate = Value(activityDate);
  static Insertable<UserActivitiesEntrieData> custom({
    Expression<int>? id,
    Expression<String>? userKey,
    Expression<DateTime>? activityDate,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userKey != null) 'user_key': userKey,
      if (activityDate != null) 'activity_date': activityDate,
      if (note != null) 'note': note,
    });
  }

  UserActivitiesEntrieCompanion copyWith(
      {Value<int>? id,
      Value<String>? userKey,
      Value<DateTime>? activityDate,
      Value<String?>? note}) {
    return UserActivitiesEntrieCompanion(
      id: id ?? this.id,
      userKey: userKey ?? this.userKey,
      activityDate: activityDate ?? this.activityDate,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userKey.present) {
      map['user_key'] = Variable<String>(userKey.value);
    }
    if (activityDate.present) {
      map['activity_date'] = Variable<DateTime>(activityDate.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserActivitiesEntrieCompanion(')
          ..write('id: $id, ')
          ..write('userKey: $userKey, ')
          ..write('activityDate: $activityDate, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $UserWordProgressEntrieTable extends UserWordProgressEntrie
    with TableInfo<$UserWordProgressEntrieTable, UserWordProgressEntrieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWordProgressEntrieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users_entrie (id)'));
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vocabulary_entries (id)'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPracticedMeta =
      const VerificationMeta('lastPracticed');
  @override
  late final GeneratedColumn<DateTime> lastPracticed =
      GeneratedColumn<DateTime>('last_practiced', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _nextReviewMeta =
      const VerificationMeta('nextReview');
  @override
  late final GeneratedColumn<DateTime> nextReview = GeneratedColumn<DateTime>(
      'next_review', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, wordId, status, lastPracticed, nextReview];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_word_progress_entrie';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserWordProgressEntrieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('last_practiced')) {
      context.handle(
          _lastPracticedMeta,
          lastPracticed.isAcceptableOrUnknown(
              data['last_practiced']!, _lastPracticedMeta));
    }
    if (data.containsKey('next_review')) {
      context.handle(
          _nextReviewMeta,
          nextReview.isAcceptableOrUnknown(
              data['next_review']!, _nextReviewMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, wordId};
  @override
  UserWordProgressEntrieData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWordProgressEntrieData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      lastPracticed: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_practiced']),
      nextReview: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_review']),
    );
  }

  @override
  $UserWordProgressEntrieTable createAlias(String alias) {
    return $UserWordProgressEntrieTable(attachedDatabase, alias);
  }
}

class UserWordProgressEntrieData extends DataClass
    implements Insertable<UserWordProgressEntrieData> {
  final int userId;
  final int wordId;
  final int status;
  final DateTime? lastPracticed;
  final DateTime? nextReview;
  const UserWordProgressEntrieData(
      {required this.userId,
      required this.wordId,
      required this.status,
      this.lastPracticed,
      this.nextReview});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['word_id'] = Variable<int>(wordId);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || lastPracticed != null) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed);
    }
    if (!nullToAbsent || nextReview != null) {
      map['next_review'] = Variable<DateTime>(nextReview);
    }
    return map;
  }

  UserWordProgressEntrieCompanion toCompanion(bool nullToAbsent) {
    return UserWordProgressEntrieCompanion(
      userId: Value(userId),
      wordId: Value(wordId),
      status: Value(status),
      lastPracticed: lastPracticed == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPracticed),
      nextReview: nextReview == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReview),
    );
  }

  factory UserWordProgressEntrieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWordProgressEntrieData(
      userId: serializer.fromJson<int>(json['userId']),
      wordId: serializer.fromJson<int>(json['wordId']),
      status: serializer.fromJson<int>(json['status']),
      lastPracticed: serializer.fromJson<DateTime?>(json['lastPracticed']),
      nextReview: serializer.fromJson<DateTime?>(json['nextReview']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'wordId': serializer.toJson<int>(wordId),
      'status': serializer.toJson<int>(status),
      'lastPracticed': serializer.toJson<DateTime?>(lastPracticed),
      'nextReview': serializer.toJson<DateTime?>(nextReview),
    };
  }

  UserWordProgressEntrieData copyWith(
          {int? userId,
          int? wordId,
          int? status,
          Value<DateTime?> lastPracticed = const Value.absent(),
          Value<DateTime?> nextReview = const Value.absent()}) =>
      UserWordProgressEntrieData(
        userId: userId ?? this.userId,
        wordId: wordId ?? this.wordId,
        status: status ?? this.status,
        lastPracticed:
            lastPracticed.present ? lastPracticed.value : this.lastPracticed,
        nextReview: nextReview.present ? nextReview.value : this.nextReview,
      );
  UserWordProgressEntrieData copyWithCompanion(
      UserWordProgressEntrieCompanion data) {
    return UserWordProgressEntrieData(
      userId: data.userId.present ? data.userId.value : this.userId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      status: data.status.present ? data.status.value : this.status,
      lastPracticed: data.lastPracticed.present
          ? data.lastPracticed.value
          : this.lastPracticed,
      nextReview:
          data.nextReview.present ? data.nextReview.value : this.nextReview,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWordProgressEntrieData(')
          ..write('userId: $userId, ')
          ..write('wordId: $wordId, ')
          ..write('status: $status, ')
          ..write('lastPracticed: $lastPracticed, ')
          ..write('nextReview: $nextReview')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, wordId, status, lastPracticed, nextReview);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWordProgressEntrieData &&
          other.userId == this.userId &&
          other.wordId == this.wordId &&
          other.status == this.status &&
          other.lastPracticed == this.lastPracticed &&
          other.nextReview == this.nextReview);
}

class UserWordProgressEntrieCompanion
    extends UpdateCompanion<UserWordProgressEntrieData> {
  final Value<int> userId;
  final Value<int> wordId;
  final Value<int> status;
  final Value<DateTime?> lastPracticed;
  final Value<DateTime?> nextReview;
  final Value<int> rowid;
  const UserWordProgressEntrieCompanion({
    this.userId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.status = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserWordProgressEntrieCompanion.insert({
    required int userId,
    required int wordId,
    this.status = const Value.absent(),
    this.lastPracticed = const Value.absent(),
    this.nextReview = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        wordId = Value(wordId);
  static Insertable<UserWordProgressEntrieData> custom({
    Expression<int>? userId,
    Expression<int>? wordId,
    Expression<int>? status,
    Expression<DateTime>? lastPracticed,
    Expression<DateTime>? nextReview,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (wordId != null) 'word_id': wordId,
      if (status != null) 'status': status,
      if (lastPracticed != null) 'last_practiced': lastPracticed,
      if (nextReview != null) 'next_review': nextReview,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserWordProgressEntrieCompanion copyWith(
      {Value<int>? userId,
      Value<int>? wordId,
      Value<int>? status,
      Value<DateTime?>? lastPracticed,
      Value<DateTime?>? nextReview,
      Value<int>? rowid}) {
    return UserWordProgressEntrieCompanion(
      userId: userId ?? this.userId,
      wordId: wordId ?? this.wordId,
      status: status ?? this.status,
      lastPracticed: lastPracticed ?? this.lastPracticed,
      nextReview: nextReview ?? this.nextReview,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (lastPracticed.present) {
      map['last_practiced'] = Variable<DateTime>(lastPracticed.value);
    }
    if (nextReview.present) {
      map['next_review'] = Variable<DateTime>(nextReview.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWordProgressEntrieCompanion(')
          ..write('userId: $userId, ')
          ..write('wordId: $wordId, ')
          ..write('status: $status, ')
          ..write('lastPracticed: $lastPracticed, ')
          ..write('nextReview: $nextReview, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsEntrieTable extends ItemsEntrie
    with TableInfo<$ItemsEntrieTable, ItemsEntrieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsEntrieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
      'price', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, description, price];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items_entrie';
  @override
  VerificationContext validateIntegrity(Insertable<ItemsEntrieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemsEntrieData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemsEntrieData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price'])!,
    );
  }

  @override
  $ItemsEntrieTable createAlias(String alias) {
    return $ItemsEntrieTable(attachedDatabase, alias);
  }
}

class ItemsEntrieData extends DataClass implements Insertable<ItemsEntrieData> {
  final int id;
  final String name;
  final String? description;
  final int price;
  const ItemsEntrieData(
      {required this.id,
      required this.name,
      this.description,
      required this.price});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['price'] = Variable<int>(price);
    return map;
  }

  ItemsEntrieCompanion toCompanion(bool nullToAbsent) {
    return ItemsEntrieCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      price: Value(price),
    );
  }

  factory ItemsEntrieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemsEntrieData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      price: serializer.fromJson<int>(json['price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'price': serializer.toJson<int>(price),
    };
  }

  ItemsEntrieData copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          int? price}) =>
      ItemsEntrieData(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        price: price ?? this.price,
      );
  ItemsEntrieData copyWithCompanion(ItemsEntrieCompanion data) {
    return ItemsEntrieData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      price: data.price.present ? data.price.value : this.price,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemsEntrieData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, price);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemsEntrieData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.price == this.price);
}

class ItemsEntrieCompanion extends UpdateCompanion<ItemsEntrieData> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> price;
  const ItemsEntrieCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.price = const Value.absent(),
  });
  ItemsEntrieCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required int price,
  })  : name = Value(name),
        price = Value(price);
  static Insertable<ItemsEntrieData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? price,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (price != null) 'price': price,
    });
  }

  ItemsEntrieCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<int>? price}) {
    return ItemsEntrieCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsEntrieCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('price: $price')
          ..write(')'))
        .toString();
  }
}

class $UserItemsEntrieTable extends UserItemsEntrie
    with TableInfo<$UserItemsEntrieTable, UserItemsEntrieData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserItemsEntrieTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES users_entrie (id)'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
      'item_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES items_entrie (id)'));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [userId, itemId, quantity];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_items_entrie';
  @override
  VerificationContext validateIntegrity(
      Insertable<UserItemsEntrieData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, itemId};
  @override
  UserItemsEntrieData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserItemsEntrieData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
    );
  }

  @override
  $UserItemsEntrieTable createAlias(String alias) {
    return $UserItemsEntrieTable(attachedDatabase, alias);
  }
}

class UserItemsEntrieData extends DataClass
    implements Insertable<UserItemsEntrieData> {
  final int userId;
  final int itemId;
  final int quantity;
  const UserItemsEntrieData(
      {required this.userId, required this.itemId, required this.quantity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['item_id'] = Variable<int>(itemId);
    map['quantity'] = Variable<int>(quantity);
    return map;
  }

  UserItemsEntrieCompanion toCompanion(bool nullToAbsent) {
    return UserItemsEntrieCompanion(
      userId: Value(userId),
      itemId: Value(itemId),
      quantity: Value(quantity),
    );
  }

  factory UserItemsEntrieData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserItemsEntrieData(
      userId: serializer.fromJson<int>(json['userId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      quantity: serializer.fromJson<int>(json['quantity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'itemId': serializer.toJson<int>(itemId),
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  UserItemsEntrieData copyWith({int? userId, int? itemId, int? quantity}) =>
      UserItemsEntrieData(
        userId: userId ?? this.userId,
        itemId: itemId ?? this.itemId,
        quantity: quantity ?? this.quantity,
      );
  UserItemsEntrieData copyWithCompanion(UserItemsEntrieCompanion data) {
    return UserItemsEntrieData(
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserItemsEntrieData(')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, itemId, quantity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserItemsEntrieData &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity);
}

class UserItemsEntrieCompanion extends UpdateCompanion<UserItemsEntrieData> {
  final Value<int> userId;
  final Value<int> itemId;
  final Value<int> quantity;
  final Value<int> rowid;
  const UserItemsEntrieCompanion({
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserItemsEntrieCompanion.insert({
    required int userId,
    required int itemId,
    this.quantity = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        itemId = Value(itemId);
  static Insertable<UserItemsEntrieData> custom({
    Expression<int>? userId,
    Expression<int>? itemId,
    Expression<int>? quantity,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserItemsEntrieCompanion copyWith(
      {Value<int>? userId,
      Value<int>? itemId,
      Value<int>? quantity,
      Value<int>? rowid}) {
    return UserItemsEntrieCompanion(
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserItemsEntrieCompanion(')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('rowid: $rowid')
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
  late final $TagsTable tags = $TagsTable(this);
  late final $VocabularyTagsTable vocabularyTags = $VocabularyTagsTable(this);
  late final $UsersEntrieTable usersEntrie = $UsersEntrieTable(this);
  late final $UserActivitiesEntrieTable userActivitiesEntrie =
      $UserActivitiesEntrieTable(this);
  late final $UserWordProgressEntrieTable userWordProgressEntrie =
      $UserWordProgressEntrieTable(this);
  late final $ItemsEntrieTable itemsEntrie = $ItemsEntrieTable(this);
  late final $UserItemsEntrieTable userItemsEntrie =
      $UserItemsEntrieTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        unitsEntries,
        vocabularyEntries,
        tags,
        vocabularyTags,
        usersEntrie,
        userActivitiesEntrie,
        userWordProgressEntrie,
        itemsEntrie,
        userItemsEntrie
      ];
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
  Value<bool?> isFavorite,
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
  Value<bool?> isFavorite,
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

  static MultiTypedResultKey<$VocabularyTagsTable, List<VocabularyTag>>
      _vocabularyTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vocabularyTags,
              aliasName: $_aliasNameGenerator(
                  db.vocabularyEntries.id, db.vocabularyTags.wordId));

  $$VocabularyTagsTableProcessedTableManager get vocabularyTagsRefs {
    final manager = $$VocabularyTagsTableTableManager($_db, $_db.vocabularyTags)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vocabularyTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$UserWordProgressEntrieTable,
      List<UserWordProgressEntrieData>> _userWordProgressEntrieRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.userWordProgressEntrie,
          aliasName: $_aliasNameGenerator(
              db.vocabularyEntries.id, db.userWordProgressEntrie.wordId));

  $$UserWordProgressEntrieTableProcessedTableManager
      get userWordProgressEntrieRefs {
    final manager = $$UserWordProgressEntrieTableTableManager(
            $_db, $_db.userWordProgressEntrie)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_userWordProgressEntrieRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
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

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

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

  Expression<bool> vocabularyTagsRefs(
      Expression<bool> Function($$VocabularyTagsTableFilterComposer f) f) {
    final $$VocabularyTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabularyTags,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTagsTableFilterComposer(
              $db: $db,
              $table: $db.vocabularyTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> userWordProgressEntrieRefs(
      Expression<bool> Function($$UserWordProgressEntrieTableFilterComposer f)
          f) {
    final $$UserWordProgressEntrieTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.userWordProgressEntrie,
            getReferencedColumn: (t) => t.wordId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserWordProgressEntrieTableFilterComposer(
                  $db: $db,
                  $table: $db.userWordProgressEntrie,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
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

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

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

  Expression<T> vocabularyTagsRefs<T extends Object>(
      Expression<T> Function($$VocabularyTagsTableAnnotationComposer a) f) {
    final $$VocabularyTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabularyTags,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.vocabularyTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> userWordProgressEntrieRefs<T extends Object>(
      Expression<T> Function($$UserWordProgressEntrieTableAnnotationComposer a)
          f) {
    final $$UserWordProgressEntrieTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.userWordProgressEntrie,
            getReferencedColumn: (t) => t.wordId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserWordProgressEntrieTableAnnotationComposer(
                  $db: $db,
                  $table: $db.userWordProgressEntrie,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
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
    PrefetchHooks Function(
        {bool unitId,
        bool vocabularyTagsRefs,
        bool userWordProgressEntrieRefs})> {
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
            Value<bool?> isFavorite = const Value.absent(),
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
            isFavorite: isFavorite,
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
            Value<bool?> isFavorite = const Value.absent(),
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
            isFavorite: isFavorite,
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
          prefetchHooksCallback: (
              {unitId = false,
              vocabularyTagsRefs = false,
              userWordProgressEntrieRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vocabularyTagsRefs) db.vocabularyTags,
                if (userWordProgressEntrieRefs) db.userWordProgressEntrie
              ],
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
                return [
                  if (vocabularyTagsRefs)
                    await $_getPrefetchedData<VocabularyEntry,
                            $VocabularyEntriesTable, VocabularyTag>(
                        currentTable: table,
                        referencedTable: $$VocabularyEntriesTableReferences
                            ._vocabularyTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VocabularyEntriesTableReferences(db, table, p0)
                                .vocabularyTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items),
                  if (userWordProgressEntrieRefs)
                    await $_getPrefetchedData<
                            VocabularyEntry,
                            $VocabularyEntriesTable,
                            UserWordProgressEntrieData>(
                        currentTable: table,
                        referencedTable: $$VocabularyEntriesTableReferences
                            ._userWordProgressEntrieRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VocabularyEntriesTableReferences(db, table, p0)
                                .userWordProgressEntrieRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items)
                ];
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
    PrefetchHooks Function(
        {bool unitId,
        bool vocabularyTagsRefs,
        bool userWordProgressEntrieRefs})>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String tagName,
  Value<String?> targetLanguage,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> tagName,
  Value<String?> targetLanguage,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VocabularyTagsTable, List<VocabularyTag>>
      _vocabularyTagsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.vocabularyTags,
              aliasName:
                  $_aliasNameGenerator(db.tags.id, db.vocabularyTags.tagId));

  $$VocabularyTagsTableProcessedTableManager get vocabularyTagsRefs {
    final manager = $$VocabularyTagsTableTableManager($_db, $_db.vocabularyTags)
        .filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_vocabularyTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetLanguage => $composableBuilder(
      column: $table.targetLanguage,
      builder: (column) => ColumnFilters(column));

  Expression<bool> vocabularyTagsRefs(
      Expression<bool> Function($$VocabularyTagsTableFilterComposer f) f) {
    final $$VocabularyTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabularyTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTagsTableFilterComposer(
              $db: $db,
              $table: $db.vocabularyTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagName => $composableBuilder(
      column: $table.tagName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
      column: $table.targetLanguage,
      builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
      column: $table.targetLanguage, builder: (column) => column);

  Expression<T> vocabularyTagsRefs<T extends Object>(
      Expression<T> Function($$VocabularyTagsTableAnnotationComposer a) f) {
    final $$VocabularyTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.vocabularyTags,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.vocabularyTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool vocabularyTagsRefs})> {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tagName = const Value.absent(),
            Value<String?> targetLanguage = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            tagName: tagName,
            targetLanguage: targetLanguage,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tagName,
            Value<String?> targetLanguage = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            id: id,
            tagName: tagName,
            targetLanguage: targetLanguage,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TagsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({vocabularyTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (vocabularyTagsRefs) db.vocabularyTags
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (vocabularyTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, VocabularyTag>(
                        currentTable: table,
                        referencedTable:
                            $$TagsTableReferences._vocabularyTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableReferences(db, table, p0)
                                .vocabularyTagsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, $$TagsTableReferences),
    Tag,
    PrefetchHooks Function({bool vocabularyTagsRefs})>;
typedef $$VocabularyTagsTableCreateCompanionBuilder = VocabularyTagsCompanion
    Function({
  required int wordId,
  required int tagId,
  Value<int> rowid,
});
typedef $$VocabularyTagsTableUpdateCompanionBuilder = VocabularyTagsCompanion
    Function({
  Value<int> wordId,
  Value<int> tagId,
  Value<int> rowid,
});

final class $$VocabularyTagsTableReferences
    extends BaseReferences<_$AppDatabase, $VocabularyTagsTable, VocabularyTag> {
  $$VocabularyTagsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyEntriesTable _wordIdTable(_$AppDatabase db) =>
      db.vocabularyEntries.createAlias($_aliasNameGenerator(
          db.vocabularyTags.wordId, db.vocabularyEntries.id));

  $$VocabularyEntriesTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager =
        $$VocabularyEntriesTableTableManager($_db, $_db.vocabularyEntries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) => db.tags
      .createAlias($_aliasNameGenerator(db.vocabularyTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager($_db, $_db.tags)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$VocabularyTagsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyTagsTable> {
  $$VocabularyTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$VocabularyEntriesTableFilterComposer get wordId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.vocabularyEntries,
        getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableFilterComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyTagsTable> {
  $$VocabularyTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$VocabularyEntriesTableOrderingComposer get wordId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.vocabularyEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.vocabularyEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableOrderingComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyTagsTable> {
  $$VocabularyTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$VocabularyEntriesTableAnnotationComposer get wordId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.wordId,
            referencedTable: $db.vocabularyEntries,
            getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tags,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableAnnotationComposer(
              $db: $db,
              $table: $db.tags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VocabularyTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyTagsTable,
    VocabularyTag,
    $$VocabularyTagsTableFilterComposer,
    $$VocabularyTagsTableOrderingComposer,
    $$VocabularyTagsTableAnnotationComposer,
    $$VocabularyTagsTableCreateCompanionBuilder,
    $$VocabularyTagsTableUpdateCompanionBuilder,
    (VocabularyTag, $$VocabularyTagsTableReferences),
    VocabularyTag,
    PrefetchHooks Function({bool wordId, bool tagId})> {
  $$VocabularyTagsTableTableManager(
      _$AppDatabase db, $VocabularyTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> wordId = const Value.absent(),
            Value<int> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTagsCompanion(
            wordId: wordId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int wordId,
            required int tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTagsCompanion.insert(
            wordId: wordId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VocabularyTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false, tagId = false}) {
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
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$VocabularyTagsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$VocabularyTagsTableReferences._wordIdTable(db).id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable:
                        $$VocabularyTagsTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$VocabularyTagsTableReferences._tagIdTable(db).id,
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

typedef $$VocabularyTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VocabularyTagsTable,
    VocabularyTag,
    $$VocabularyTagsTableFilterComposer,
    $$VocabularyTagsTableOrderingComposer,
    $$VocabularyTagsTableAnnotationComposer,
    $$VocabularyTagsTableCreateCompanionBuilder,
    $$VocabularyTagsTableUpdateCompanionBuilder,
    (VocabularyTag, $$VocabularyTagsTableReferences),
    VocabularyTag,
    PrefetchHooks Function({bool wordId, bool tagId})>;
typedef $$UsersEntrieTableCreateCompanionBuilder = UsersEntrieCompanion
    Function({
  Value<String?> id,
  required String keyOpen,
  required String username,
  Value<int> currentStreak,
  Value<int> longestStreak,
  Value<int> totalLearned,
  Value<DateTime?> lastActiveDate,
  Value<int> gems,
  Value<int> level,
  Value<int> experience,
  Value<int> rowid,
});
typedef $$UsersEntrieTableUpdateCompanionBuilder = UsersEntrieCompanion
    Function({
  Value<String?> id,
  Value<String> keyOpen,
  Value<String> username,
  Value<int> currentStreak,
  Value<int> longestStreak,
  Value<int> totalLearned,
  Value<DateTime?> lastActiveDate,
  Value<int> gems,
  Value<int> level,
  Value<int> experience,
  Value<int> rowid,
});

final class $$UsersEntrieTableReferences
    extends BaseReferences<_$AppDatabase, $UsersEntrieTable, UsersEntrieData> {
  $$UsersEntrieTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserActivitiesEntrieTable,
      List<UserActivitiesEntrieData>> _userActivitiesEntrieRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.userActivitiesEntrie,
          aliasName: $_aliasNameGenerator(
              db.usersEntrie.keyOpen, db.userActivitiesEntrie.userKey));

  $$UserActivitiesEntrieTableProcessedTableManager
      get userActivitiesEntrieRefs {
    final manager =
        $$UserActivitiesEntrieTableTableManager($_db, $_db.userActivitiesEntrie)
            .filter((f) =>
                f.userKey.keyOpen.sqlEquals($_itemColumn<String>('key_open')!));

    final cache =
        $_typedResult.readTableOrNull(_userActivitiesEntrieRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UsersEntrieTableFilterComposer
    extends Composer<_$AppDatabase, $UsersEntrieTable> {
  $$UsersEntrieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyOpen => $composableBuilder(
      column: $table.keyOpen, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalLearned => $composableBuilder(
      column: $table.totalLearned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActiveDate => $composableBuilder(
      column: $table.lastActiveDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gems => $composableBuilder(
      column: $table.gems, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get experience => $composableBuilder(
      column: $table.experience, builder: (column) => ColumnFilters(column));

  Expression<bool> userActivitiesEntrieRefs(
      Expression<bool> Function($$UserActivitiesEntrieTableFilterComposer f)
          f) {
    final $$UserActivitiesEntrieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.keyOpen,
        referencedTable: $db.userActivitiesEntrie,
        getReferencedColumn: (t) => t.userKey,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserActivitiesEntrieTableFilterComposer(
              $db: $db,
              $table: $db.userActivitiesEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$UsersEntrieTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersEntrieTable> {
  $$UsersEntrieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyOpen => $composableBuilder(
      column: $table.keyOpen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalLearned => $composableBuilder(
      column: $table.totalLearned,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActiveDate => $composableBuilder(
      column: $table.lastActiveDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gems => $composableBuilder(
      column: $table.gems, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get level => $composableBuilder(
      column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get experience => $composableBuilder(
      column: $table.experience, builder: (column) => ColumnOrderings(column));
}

class $$UsersEntrieTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersEntrieTable> {
  $$UsersEntrieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyOpen =>
      $composableBuilder(column: $table.keyOpen, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
      column: $table.currentStreak, builder: (column) => column);

  GeneratedColumn<int> get longestStreak => $composableBuilder(
      column: $table.longestStreak, builder: (column) => column);

  GeneratedColumn<int> get totalLearned => $composableBuilder(
      column: $table.totalLearned, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActiveDate => $composableBuilder(
      column: $table.lastActiveDate, builder: (column) => column);

  GeneratedColumn<int> get gems =>
      $composableBuilder(column: $table.gems, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get experience => $composableBuilder(
      column: $table.experience, builder: (column) => column);

  Expression<T> userActivitiesEntrieRefs<T extends Object>(
      Expression<T> Function($$UserActivitiesEntrieTableAnnotationComposer a)
          f) {
    final $$UserActivitiesEntrieTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.keyOpen,
            referencedTable: $db.userActivitiesEntrie,
            getReferencedColumn: (t) => t.userKey,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$UserActivitiesEntrieTableAnnotationComposer(
                  $db: $db,
                  $table: $db.userActivitiesEntrie,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$UsersEntrieTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersEntrieTable,
    UsersEntrieData,
    $$UsersEntrieTableFilterComposer,
    $$UsersEntrieTableOrderingComposer,
    $$UsersEntrieTableAnnotationComposer,
    $$UsersEntrieTableCreateCompanionBuilder,
    $$UsersEntrieTableUpdateCompanionBuilder,
    (UsersEntrieData, $$UsersEntrieTableReferences),
    UsersEntrieData,
    PrefetchHooks Function({bool userActivitiesEntrieRefs})> {
  $$UsersEntrieTableTableManager(_$AppDatabase db, $UsersEntrieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersEntrieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersEntrieTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersEntrieTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> id = const Value.absent(),
            Value<String> keyOpen = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<int> currentStreak = const Value.absent(),
            Value<int> longestStreak = const Value.absent(),
            Value<int> totalLearned = const Value.absent(),
            Value<DateTime?> lastActiveDate = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> experience = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersEntrieCompanion(
            id: id,
            keyOpen: keyOpen,
            username: username,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalLearned: totalLearned,
            lastActiveDate: lastActiveDate,
            gems: gems,
            level: level,
            experience: experience,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String?> id = const Value.absent(),
            required String keyOpen,
            required String username,
            Value<int> currentStreak = const Value.absent(),
            Value<int> longestStreak = const Value.absent(),
            Value<int> totalLearned = const Value.absent(),
            Value<DateTime?> lastActiveDate = const Value.absent(),
            Value<int> gems = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<int> experience = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsersEntrieCompanion.insert(
            id: id,
            keyOpen: keyOpen,
            username: username,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalLearned: totalLearned,
            lastActiveDate: lastActiveDate,
            gems: gems,
            level: level,
            experience: experience,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UsersEntrieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userActivitiesEntrieRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userActivitiesEntrieRefs) db.userActivitiesEntrie
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userActivitiesEntrieRefs)
                    await $_getPrefetchedData<UsersEntrieData,
                            $UsersEntrieTable, UserActivitiesEntrieData>(
                        currentTable: table,
                        referencedTable: $$UsersEntrieTableReferences
                            ._userActivitiesEntrieRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UsersEntrieTableReferences(db, table, p0)
                                .userActivitiesEntrieRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.userKey == item.keyOpen),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UsersEntrieTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersEntrieTable,
    UsersEntrieData,
    $$UsersEntrieTableFilterComposer,
    $$UsersEntrieTableOrderingComposer,
    $$UsersEntrieTableAnnotationComposer,
    $$UsersEntrieTableCreateCompanionBuilder,
    $$UsersEntrieTableUpdateCompanionBuilder,
    (UsersEntrieData, $$UsersEntrieTableReferences),
    UsersEntrieData,
    PrefetchHooks Function({bool userActivitiesEntrieRefs})>;
typedef $$UserActivitiesEntrieTableCreateCompanionBuilder
    = UserActivitiesEntrieCompanion Function({
  Value<int> id,
  required String userKey,
  required DateTime activityDate,
  Value<String?> note,
});
typedef $$UserActivitiesEntrieTableUpdateCompanionBuilder
    = UserActivitiesEntrieCompanion Function({
  Value<int> id,
  Value<String> userKey,
  Value<DateTime> activityDate,
  Value<String?> note,
});

final class $$UserActivitiesEntrieTableReferences extends BaseReferences<
    _$AppDatabase, $UserActivitiesEntrieTable, UserActivitiesEntrieData> {
  $$UserActivitiesEntrieTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $UsersEntrieTable _userKeyTable(_$AppDatabase db) =>
      db.usersEntrie.createAlias($_aliasNameGenerator(
          db.userActivitiesEntrie.userKey, db.usersEntrie.keyOpen));

  $$UsersEntrieTableProcessedTableManager get userKey {
    final $_column = $_itemColumn<String>('user_key')!;

    final manager = $$UsersEntrieTableTableManager($_db, $_db.usersEntrie)
        .filter((f) => f.keyOpen.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserActivitiesEntrieTableFilterComposer
    extends Composer<_$AppDatabase, $UserActivitiesEntrieTable> {
  $$UserActivitiesEntrieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get activityDate => $composableBuilder(
      column: $table.activityDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  $$UsersEntrieTableFilterComposer get userKey {
    final $$UsersEntrieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userKey,
        referencedTable: $db.usersEntrie,
        getReferencedColumn: (t) => t.keyOpen,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersEntrieTableFilterComposer(
              $db: $db,
              $table: $db.usersEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserActivitiesEntrieTableOrderingComposer
    extends Composer<_$AppDatabase, $UserActivitiesEntrieTable> {
  $$UserActivitiesEntrieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get activityDate => $composableBuilder(
      column: $table.activityDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  $$UsersEntrieTableOrderingComposer get userKey {
    final $$UsersEntrieTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userKey,
        referencedTable: $db.usersEntrie,
        getReferencedColumn: (t) => t.keyOpen,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersEntrieTableOrderingComposer(
              $db: $db,
              $table: $db.usersEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserActivitiesEntrieTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserActivitiesEntrieTable> {
  $$UserActivitiesEntrieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get activityDate => $composableBuilder(
      column: $table.activityDate, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$UsersEntrieTableAnnotationComposer get userKey {
    final $$UsersEntrieTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userKey,
        referencedTable: $db.usersEntrie,
        getReferencedColumn: (t) => t.keyOpen,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UsersEntrieTableAnnotationComposer(
              $db: $db,
              $table: $db.usersEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserActivitiesEntrieTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserActivitiesEntrieTable,
    UserActivitiesEntrieData,
    $$UserActivitiesEntrieTableFilterComposer,
    $$UserActivitiesEntrieTableOrderingComposer,
    $$UserActivitiesEntrieTableAnnotationComposer,
    $$UserActivitiesEntrieTableCreateCompanionBuilder,
    $$UserActivitiesEntrieTableUpdateCompanionBuilder,
    (UserActivitiesEntrieData, $$UserActivitiesEntrieTableReferences),
    UserActivitiesEntrieData,
    PrefetchHooks Function({bool userKey})> {
  $$UserActivitiesEntrieTableTableManager(
      _$AppDatabase db, $UserActivitiesEntrieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserActivitiesEntrieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserActivitiesEntrieTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserActivitiesEntrieTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userKey = const Value.absent(),
            Value<DateTime> activityDate = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) =>
              UserActivitiesEntrieCompanion(
            id: id,
            userKey: userKey,
            activityDate: activityDate,
            note: note,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String userKey,
            required DateTime activityDate,
            Value<String?> note = const Value.absent(),
          }) =>
              UserActivitiesEntrieCompanion.insert(
            id: id,
            userKey: userKey,
            activityDate: activityDate,
            note: note,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserActivitiesEntrieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userKey = false}) {
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
                if (userKey) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userKey,
                    referencedTable:
                        $$UserActivitiesEntrieTableReferences._userKeyTable(db),
                    referencedColumn: $$UserActivitiesEntrieTableReferences
                        ._userKeyTable(db)
                        .keyOpen,
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

typedef $$UserActivitiesEntrieTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserActivitiesEntrieTable,
        UserActivitiesEntrieData,
        $$UserActivitiesEntrieTableFilterComposer,
        $$UserActivitiesEntrieTableOrderingComposer,
        $$UserActivitiesEntrieTableAnnotationComposer,
        $$UserActivitiesEntrieTableCreateCompanionBuilder,
        $$UserActivitiesEntrieTableUpdateCompanionBuilder,
        (UserActivitiesEntrieData, $$UserActivitiesEntrieTableReferences),
        UserActivitiesEntrieData,
        PrefetchHooks Function({bool userKey})>;
typedef $$UserWordProgressEntrieTableCreateCompanionBuilder
    = UserWordProgressEntrieCompanion Function({
  required int userId,
  required int wordId,
  Value<int> status,
  Value<DateTime?> lastPracticed,
  Value<DateTime?> nextReview,
  Value<int> rowid,
});
typedef $$UserWordProgressEntrieTableUpdateCompanionBuilder
    = UserWordProgressEntrieCompanion Function({
  Value<int> userId,
  Value<int> wordId,
  Value<int> status,
  Value<DateTime?> lastPracticed,
  Value<DateTime?> nextReview,
  Value<int> rowid,
});

final class $$UserWordProgressEntrieTableReferences extends BaseReferences<
    _$AppDatabase, $UserWordProgressEntrieTable, UserWordProgressEntrieData> {
  $$UserWordProgressEntrieTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $VocabularyEntriesTable _wordIdTable(_$AppDatabase db) =>
      db.vocabularyEntries.createAlias($_aliasNameGenerator(
          db.userWordProgressEntrie.wordId, db.vocabularyEntries.id));

  $$VocabularyEntriesTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager =
        $$VocabularyEntriesTableTableManager($_db, $_db.vocabularyEntries)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserWordProgressEntrieTableFilterComposer
    extends Composer<_$AppDatabase, $UserWordProgressEntrieTable> {
  $$UserWordProgressEntrieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => ColumnFilters(column));

  $$VocabularyEntriesTableFilterComposer get wordId {
    final $$VocabularyEntriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.vocabularyEntries,
        getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$UserWordProgressEntrieTableOrderingComposer
    extends Composer<_$AppDatabase, $UserWordProgressEntrieTable> {
  $$UserWordProgressEntrieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => ColumnOrderings(column));

  $$VocabularyEntriesTableOrderingComposer get wordId {
    final $$VocabularyEntriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.vocabularyEntries,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VocabularyEntriesTableOrderingComposer(
              $db: $db,
              $table: $db.vocabularyEntries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserWordProgressEntrieTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserWordProgressEntrieTable> {
  $$UserWordProgressEntrieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPracticed => $composableBuilder(
      column: $table.lastPracticed, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReview => $composableBuilder(
      column: $table.nextReview, builder: (column) => column);

  $$VocabularyEntriesTableAnnotationComposer get wordId {
    final $$VocabularyEntriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.wordId,
            referencedTable: $db.vocabularyEntries,
            getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$UserWordProgressEntrieTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserWordProgressEntrieTable,
    UserWordProgressEntrieData,
    $$UserWordProgressEntrieTableFilterComposer,
    $$UserWordProgressEntrieTableOrderingComposer,
    $$UserWordProgressEntrieTableAnnotationComposer,
    $$UserWordProgressEntrieTableCreateCompanionBuilder,
    $$UserWordProgressEntrieTableUpdateCompanionBuilder,
    (UserWordProgressEntrieData, $$UserWordProgressEntrieTableReferences),
    UserWordProgressEntrieData,
    PrefetchHooks Function({bool wordId})> {
  $$UserWordProgressEntrieTableTableManager(
      _$AppDatabase db, $UserWordProgressEntrieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWordProgressEntrieTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWordProgressEntrieTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWordProgressEntrieTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<int> wordId = const Value.absent(),
            Value<int> status = const Value.absent(),
            Value<DateTime?> lastPracticed = const Value.absent(),
            Value<DateTime?> nextReview = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWordProgressEntrieCompanion(
            userId: userId,
            wordId: wordId,
            status: status,
            lastPracticed: lastPracticed,
            nextReview: nextReview,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int userId,
            required int wordId,
            Value<int> status = const Value.absent(),
            Value<DateTime?> lastPracticed = const Value.absent(),
            Value<DateTime?> nextReview = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserWordProgressEntrieCompanion.insert(
            userId: userId,
            wordId: wordId,
            status: status,
            lastPracticed: lastPracticed,
            nextReview: nextReview,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserWordProgressEntrieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
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
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable: $$UserWordProgressEntrieTableReferences
                        ._wordIdTable(db),
                    referencedColumn: $$UserWordProgressEntrieTableReferences
                        ._wordIdTable(db)
                        .id,
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

typedef $$UserWordProgressEntrieTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserWordProgressEntrieTable,
        UserWordProgressEntrieData,
        $$UserWordProgressEntrieTableFilterComposer,
        $$UserWordProgressEntrieTableOrderingComposer,
        $$UserWordProgressEntrieTableAnnotationComposer,
        $$UserWordProgressEntrieTableCreateCompanionBuilder,
        $$UserWordProgressEntrieTableUpdateCompanionBuilder,
        (UserWordProgressEntrieData, $$UserWordProgressEntrieTableReferences),
        UserWordProgressEntrieData,
        PrefetchHooks Function({bool wordId})>;
typedef $$ItemsEntrieTableCreateCompanionBuilder = ItemsEntrieCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  required int price,
});
typedef $$ItemsEntrieTableUpdateCompanionBuilder = ItemsEntrieCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<int> price,
});

final class $$ItemsEntrieTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsEntrieTable, ItemsEntrieData> {
  $$ItemsEntrieTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserItemsEntrieTable, List<UserItemsEntrieData>>
      _userItemsEntrieRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.userItemsEntrie,
              aliasName: $_aliasNameGenerator(
                  db.itemsEntrie.id, db.userItemsEntrie.itemId));

  $$UserItemsEntrieTableProcessedTableManager get userItemsEntrieRefs {
    final manager =
        $$UserItemsEntrieTableTableManager($_db, $_db.userItemsEntrie)
            .filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_userItemsEntrieRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ItemsEntrieTableFilterComposer
    extends Composer<_$AppDatabase, $ItemsEntrieTable> {
  $$ItemsEntrieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  Expression<bool> userItemsEntrieRefs(
      Expression<bool> Function($$UserItemsEntrieTableFilterComposer f) f) {
    final $$UserItemsEntrieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userItemsEntrie,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserItemsEntrieTableFilterComposer(
              $db: $db,
              $table: $db.userItemsEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsEntrieTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsEntrieTable> {
  $$ItemsEntrieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));
}

class $$ItemsEntrieTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsEntrieTable> {
  $$ItemsEntrieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  Expression<T> userItemsEntrieRefs<T extends Object>(
      Expression<T> Function($$UserItemsEntrieTableAnnotationComposer a) f) {
    final $$UserItemsEntrieTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.userItemsEntrie,
        getReferencedColumn: (t) => t.itemId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$UserItemsEntrieTableAnnotationComposer(
              $db: $db,
              $table: $db.userItemsEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ItemsEntrieTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemsEntrieTable,
    ItemsEntrieData,
    $$ItemsEntrieTableFilterComposer,
    $$ItemsEntrieTableOrderingComposer,
    $$ItemsEntrieTableAnnotationComposer,
    $$ItemsEntrieTableCreateCompanionBuilder,
    $$ItemsEntrieTableUpdateCompanionBuilder,
    (ItemsEntrieData, $$ItemsEntrieTableReferences),
    ItemsEntrieData,
    PrefetchHooks Function({bool userItemsEntrieRefs})> {
  $$ItemsEntrieTableTableManager(_$AppDatabase db, $ItemsEntrieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsEntrieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsEntrieTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsEntrieTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> price = const Value.absent(),
          }) =>
              ItemsEntrieCompanion(
            id: id,
            name: name,
            description: description,
            price: price,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            required int price,
          }) =>
              ItemsEntrieCompanion.insert(
            id: id,
            name: name,
            description: description,
            price: price,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ItemsEntrieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({userItemsEntrieRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userItemsEntrieRefs) db.userItemsEntrie
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userItemsEntrieRefs)
                    await $_getPrefetchedData<ItemsEntrieData,
                            $ItemsEntrieTable, UserItemsEntrieData>(
                        currentTable: table,
                        referencedTable: $$ItemsEntrieTableReferences
                            ._userItemsEntrieRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ItemsEntrieTableReferences(db, table, p0)
                                .userItemsEntrieRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.itemId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ItemsEntrieTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemsEntrieTable,
    ItemsEntrieData,
    $$ItemsEntrieTableFilterComposer,
    $$ItemsEntrieTableOrderingComposer,
    $$ItemsEntrieTableAnnotationComposer,
    $$ItemsEntrieTableCreateCompanionBuilder,
    $$ItemsEntrieTableUpdateCompanionBuilder,
    (ItemsEntrieData, $$ItemsEntrieTableReferences),
    ItemsEntrieData,
    PrefetchHooks Function({bool userItemsEntrieRefs})>;
typedef $$UserItemsEntrieTableCreateCompanionBuilder = UserItemsEntrieCompanion
    Function({
  required int userId,
  required int itemId,
  Value<int> quantity,
  Value<int> rowid,
});
typedef $$UserItemsEntrieTableUpdateCompanionBuilder = UserItemsEntrieCompanion
    Function({
  Value<int> userId,
  Value<int> itemId,
  Value<int> quantity,
  Value<int> rowid,
});

final class $$UserItemsEntrieTableReferences extends BaseReferences<
    _$AppDatabase, $UserItemsEntrieTable, UserItemsEntrieData> {
  $$UserItemsEntrieTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ItemsEntrieTable _itemIdTable(_$AppDatabase db) =>
      db.itemsEntrie.createAlias(
          $_aliasNameGenerator(db.userItemsEntrie.itemId, db.itemsEntrie.id));

  $$ItemsEntrieTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsEntrieTableTableManager($_db, $_db.itemsEntrie)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$UserItemsEntrieTableFilterComposer
    extends Composer<_$AppDatabase, $UserItemsEntrieTable> {
  $$UserItemsEntrieTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  $$ItemsEntrieTableFilterComposer get itemId {
    final $$ItemsEntrieTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.itemsEntrie,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsEntrieTableFilterComposer(
              $db: $db,
              $table: $db.itemsEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserItemsEntrieTableOrderingComposer
    extends Composer<_$AppDatabase, $UserItemsEntrieTable> {
  $$UserItemsEntrieTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  $$ItemsEntrieTableOrderingComposer get itemId {
    final $$ItemsEntrieTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.itemsEntrie,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsEntrieTableOrderingComposer(
              $db: $db,
              $table: $db.itemsEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserItemsEntrieTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserItemsEntrieTable> {
  $$UserItemsEntrieTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  $$ItemsEntrieTableAnnotationComposer get itemId {
    final $$ItemsEntrieTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.itemId,
        referencedTable: $db.itemsEntrie,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ItemsEntrieTableAnnotationComposer(
              $db: $db,
              $table: $db.itemsEntrie,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$UserItemsEntrieTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserItemsEntrieTable,
    UserItemsEntrieData,
    $$UserItemsEntrieTableFilterComposer,
    $$UserItemsEntrieTableOrderingComposer,
    $$UserItemsEntrieTableAnnotationComposer,
    $$UserItemsEntrieTableCreateCompanionBuilder,
    $$UserItemsEntrieTableUpdateCompanionBuilder,
    (UserItemsEntrieData, $$UserItemsEntrieTableReferences),
    UserItemsEntrieData,
    PrefetchHooks Function({bool itemId})> {
  $$UserItemsEntrieTableTableManager(
      _$AppDatabase db, $UserItemsEntrieTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserItemsEntrieTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserItemsEntrieTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserItemsEntrieTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<int> itemId = const Value.absent(),
            Value<int> quantity = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserItemsEntrieCompanion(
            userId: userId,
            itemId: itemId,
            quantity: quantity,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int userId,
            required int itemId,
            Value<int> quantity = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserItemsEntrieCompanion.insert(
            userId: userId,
            itemId: itemId,
            quantity: quantity,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserItemsEntrieTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                if (itemId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.itemId,
                    referencedTable:
                        $$UserItemsEntrieTableReferences._itemIdTable(db),
                    referencedColumn:
                        $$UserItemsEntrieTableReferences._itemIdTable(db).id,
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

typedef $$UserItemsEntrieTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserItemsEntrieTable,
    UserItemsEntrieData,
    $$UserItemsEntrieTableFilterComposer,
    $$UserItemsEntrieTableOrderingComposer,
    $$UserItemsEntrieTableAnnotationComposer,
    $$UserItemsEntrieTableCreateCompanionBuilder,
    $$UserItemsEntrieTableUpdateCompanionBuilder,
    (UserItemsEntrieData, $$UserItemsEntrieTableReferences),
    UserItemsEntrieData,
    PrefetchHooks Function({bool itemId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UnitsEntriesTableTableManager get unitsEntries =>
      $$UnitsEntriesTableTableManager(_db, _db.unitsEntries);
  $$VocabularyEntriesTableTableManager get vocabularyEntries =>
      $$VocabularyEntriesTableTableManager(_db, _db.vocabularyEntries);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$VocabularyTagsTableTableManager get vocabularyTags =>
      $$VocabularyTagsTableTableManager(_db, _db.vocabularyTags);
  $$UsersEntrieTableTableManager get usersEntrie =>
      $$UsersEntrieTableTableManager(_db, _db.usersEntrie);
  $$UserActivitiesEntrieTableTableManager get userActivitiesEntrie =>
      $$UserActivitiesEntrieTableTableManager(_db, _db.userActivitiesEntrie);
  $$UserWordProgressEntrieTableTableManager get userWordProgressEntrie =>
      $$UserWordProgressEntrieTableTableManager(
          _db, _db.userWordProgressEntrie);
  $$ItemsEntrieTableTableManager get itemsEntrie =>
      $$ItemsEntrieTableTableManager(_db, _db.itemsEntrie);
  $$UserItemsEntrieTableTableManager get userItemsEntrie =>
      $$UserItemsEntrieTableTableManager(_db, _db.userItemsEntrie);
}

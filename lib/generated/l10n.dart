// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Vocabulary List`
  String get vocabularyList {
    return Intl.message(
      'Vocabulary List',
      name: 'vocabularyList',
      desc: '',
      args: [],
    );
  }

  /// `Add Word`
  String get addWord {
    return Intl.message('Add Word', name: 'addWord', desc: '', args: []);
  }

  /// ` words`
  String get wordCount {
    return Intl.message(' words', name: 'wordCount', desc: '', args: []);
  }

  /// `All`
  String get tabAll {
    return Intl.message('All', name: 'tabAll', desc: '', args: []);
  }

  /// `Learned`
  String get tabLearned {
    return Intl.message('Learned', name: 'tabLearned', desc: '', args: []);
  }

  /// `New`
  String get tabNew {
    return Intl.message('New', name: 'tabNew', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Please enter a word`
  String get errorEnterWord {
    return Intl.message(
      'Please enter a word',
      name: 'errorEnterWord',
      desc: '',
      args: [],
    );
  }

  /// `Please enter meaning`
  String get errorEnterMeaning {
    return Intl.message(
      'Please enter meaning',
      name: 'errorEnterMeaning',
      desc: '',
      args: [],
    );
  }

  /// `No vocabulary yet`
  String get emptyList {
    return Intl.message(
      'No vocabulary yet',
      name: 'emptyList',
      desc: '',
      args: [],
    );
  }

  /// `Tap + to add new word`
  String get emptyListHint {
    return Intl.message(
      'Tap + to add new word',
      name: 'emptyListHint',
      desc: '',
      args: [],
    );
  }

  /// `Delete "{word}"?`
  String confirmDeleteMsg(Object word) {
    return Intl.message(
      'Delete "$word"?',
      name: 'confirmDeleteMsg',
      desc: '',
      args: [word],
    );
  }

  /// `Vocabulary`
  String get fieldVocabulary {
    return Intl.message(
      'Vocabulary',
      name: 'fieldVocabulary',
      desc: '',
      args: [],
    );
  }

  /// `Pronunciation`
  String get fieldPronunciation {
    return Intl.message(
      'Pronunciation',
      name: 'fieldPronunciation',
      desc: '',
      args: [],
    );
  }

  /// `Meaning`
  String get fieldMeaning {
    return Intl.message('Meaning', name: 'fieldMeaning', desc: '', args: []);
  }

  /// `Noun`
  String get noun {
    return Intl.message('Noun', name: 'noun', desc: '', args: []);
  }

  /// `Verb`
  String get verb {
    return Intl.message('Verb', name: 'verb', desc: '', args: []);
  }

  /// `I-adjective`
  String get adjI {
    return Intl.message('I-adjective', name: 'adjI', desc: '', args: []);
  }

  /// `Na-adjective`
  String get adjNa {
    return Intl.message('Na-adjective', name: 'adjNa', desc: '', args: []);
  }

  /// `Adverb`
  String get adverb {
    return Intl.message('Adverb', name: 'adverb', desc: '', args: []);
  }

  /// `Expression`
  String get expression {
    return Intl.message('Expression', name: 'expression', desc: '', args: []);
  }

  /// `Warrior`
  String get base_name {
    return Intl.message('Warrior', name: 'base_name', desc: '', args: []);
  }

  /// `level`
  String get level {
    return Intl.message('level', name: 'level', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'vi'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}

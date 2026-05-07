import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../generated/l10n.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  static const _keyLanguageCode = 'app_language_code';

  AppCubit() : super(const AppState());

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLanguageCode);
    if (code == null || code.isEmpty) return;
    emit(state.copyWith(locale: Locale(code)));
  }

  Future<void> setLanguageCode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await prefs.remove(_keyLanguageCode);
      emit(state.copyWith(clearLocale: true));
      return;
    }
    await prefs.setString(_keyLanguageCode, code);
    emit(state.copyWith(locale: Locale(code)));
  }

}
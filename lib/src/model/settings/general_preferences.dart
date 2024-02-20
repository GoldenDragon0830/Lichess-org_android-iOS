import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/db/shared_preferences.dart';
import 'package:lichess_mobile/src/model/settings/sound_theme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'general_preferences.freezed.dart';
part 'general_preferences.g.dart';

const _prefKey = 'preferences.general';

@Riverpod(keepAlive: true)
class GeneralPreferences extends _$GeneralPreferences {
  static GeneralPrefsState fetchFromStorage(SharedPreferences prefs) {
    final stored = prefs.getString(_prefKey);
    return stored != null
        ? GeneralPrefsState.fromJson(
            jsonDecode(stored) as Map<String, dynamic>,
          )
        : GeneralPrefsState.defaults;
  }

  @override
  GeneralPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return fetchFromStorage(prefs);
  }

  Future<void> setThemeMode(ThemeMode themeMode) {
    return _save(state.copyWith(themeMode: themeMode));
  }

  Future<void> toggleSoundEnabled() {
    return _save(state.copyWith(isSoundEnabled: !state.isSoundEnabled));
  }

  Future<void> setSoundTheme(SoundTheme soundTheme) {
    return _save(state.copyWith(soundTheme: soundTheme));
  }

  Future<void> setColorPalette(ColorPalette colorPalette) {
    return _save(state.copyWith(colorPalette: colorPalette));
  }

  Future<void> _save(GeneralPrefsState newState) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _prefKey,
      jsonEncode(newState.toJson()),
    );
    state = newState;
  }
}

enum ColorPalette { system, board }

@Freezed(fromJson: true, toJson: true)
class GeneralPrefsState with _$GeneralPrefsState {
  const factory GeneralPrefsState({
    required ThemeMode themeMode,
    required bool isSoundEnabled,
    required SoundTheme soundTheme,

    /// The origin of the color palette (android 12+ only)
    required ColorPalette colorPalette,
  }) = _GeneralPrefsState;

  static const defaults = GeneralPrefsState(
    themeMode: ThemeMode.system,
    isSoundEnabled: true,
    soundTheme: SoundTheme.standard,
    colorPalette: ColorPalette.system,
  );

  factory GeneralPrefsState.fromJson(Map<String, dynamic> json) {
    try {
      return _$GeneralPrefsStateFromJson(json);
    } catch (_) {
      return defaults;
    }
  }
}

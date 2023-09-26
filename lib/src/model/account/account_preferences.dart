import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:result_extensions/result_extensions.dart';

import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';

import 'account_repository.dart';

part 'account_preferences.g.dart';

typedef AccountPrefState = ({
  AutoQueen autoQueen,
  AutoThreefold autoThreefold,
  Takeback takeback,
  Moretime moretime,
  BooleanPref confirmResign,
});

/// Get the account preferences for the current user.
///
/// The result is cached for the lifetime of the app, until refreshed.
/// If the server returns an error, default values are returned.
@Riverpod(keepAlive: true)
class AccountPreferences extends _$AccountPreferences {
  @override
  Future<AccountPrefState?> build() async {
    final session = ref.watch(authSessionProvider);

    if (session == null) {
      return null;
    }

    return _repo.getPreferences().fold(
          (value) => value,
          (_, __) => (
            autoQueen: AutoQueen.premove,
            autoThreefold: AutoThreefold.always,
            takeback: Takeback.always,
            moretime: Moretime.always,
            confirmResign: BooleanPref.yes,
          ),
        );
  }

  Future<void> setAutoQueen(AutoQueen value) async {
    await _repo.setPreference('autoQueen', value);
    ref.invalidateSelf();
  }

  AccountRepository get _repo => ref.read(accountRepositoryProvider);
}

sealed class AccountPref<T> {
  T get value;
}

enum BooleanPref implements AccountPref<int> {
  yes(1),
  no(0);

  const BooleanPref(this.value);

  @override
  final int value;

  String label(BuildContext context) {
    switch (this) {
      case BooleanPref.yes:
        return context.l10n.yes;
      case BooleanPref.no:
        return context.l10n.no;
    }
  }

  static BooleanPref fromInt(int value) {
    switch (value) {
      case 1:
        return BooleanPref.yes;
      case 0:
        return BooleanPref.no;
      default:
        throw Exception('Invalid value for BooleanPref');
    }
  }
}

enum AutoQueen implements AccountPref<int> {
  never(1),
  premove(2),
  always(3);

  const AutoQueen(this.value);

  @override
  final int value;

  String label(BuildContext context) {
    switch (this) {
      case AutoQueen.never:
        return context.l10n.never;
      case AutoQueen.premove:
        return context.l10n.preferencesWhenPremoving;
      case AutoQueen.always:
        return context.l10n.always;
    }
  }

  static AutoQueen fromInt(int value) {
    switch (value) {
      case 1:
        return AutoQueen.never;
      case 2:
        return AutoQueen.premove;
      case 3:
        return AutoQueen.always;
      default:
        throw Exception('Invalid value for AutoQueen');
    }
  }
}

enum AutoThreefold implements AccountPref<int> {
  never(1),
  time(2),
  always(3);

  const AutoThreefold(this.value);

  @override
  final int value;

  String label(BuildContext context) {
    switch (this) {
      case AutoThreefold.never:
        return context.l10n.never;
      case AutoThreefold.time:
        return context.l10n.preferencesWhenTimeRemainingLessThanThirtySeconds;
      case AutoThreefold.always:
        return context.l10n.always;
    }
  }

  static AutoThreefold fromInt(int value) {
    switch (value) {
      case 1:
        return AutoThreefold.never;
      case 2:
        return AutoThreefold.time;
      case 3:
        return AutoThreefold.always;
      default:
        throw Exception('Invalid value for AutoThreefold');
    }
  }
}

enum Takeback implements AccountPref<int> {
  never(1),
  casual(2),
  always(3);

  const Takeback(this.value);

  @override
  final int value;

  String label(BuildContext context) {
    switch (this) {
      case Takeback.never:
        return context.l10n.never;
      case Takeback.casual:
        return context.l10n.preferencesInCasualGamesOnly;
      case Takeback.always:
        return context.l10n.always;
    }
  }

  static Takeback fromInt(int value) {
    switch (value) {
      case 1:
        return Takeback.never;
      case 2:
        return Takeback.casual;
      case 3:
        return Takeback.always;
      default:
        throw Exception('Invalid value for Takeback');
    }
  }
}

enum Moretime implements AccountPref<int> {
  never(1),
  casual(2),
  always(3);

  const Moretime(this.value);

  @override
  final int value;

  String label(BuildContext context) {
    switch (this) {
      case Moretime.never:
        return context.l10n.never;
      case Moretime.casual:
        return context.l10n.preferencesInCasualGamesOnly;
      case Moretime.always:
        return context.l10n.always;
    }
  }

  static Moretime fromInt(int value) {
    switch (value) {
      case 1:
        return Moretime.never;
      case 2:
        return Moretime.casual;
      case 3:
        return Moretime.always;
      default:
        throw Exception('Invalid value for Moretime');
    }
  }
}

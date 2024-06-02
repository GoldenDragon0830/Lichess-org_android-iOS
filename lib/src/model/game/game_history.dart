import 'dart:async';

import 'package:async/async.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/account/account_repository.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/common/http.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/game/archived_game.dart';
import 'package:lichess_mobile/src/model/game/game_repository.dart';
import 'package:lichess_mobile/src/model/game/game_storage.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/model/user/user_repository_providers.dart';
import 'package:lichess_mobile/src/utils/connectivity.dart';
import 'package:lichess_mobile/src/utils/riverpod.dart';
import 'package:result_extensions/result_extensions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_history.freezed.dart';
part 'game_history.g.dart';

const kNumberOfRecentGames = 20;

const _nbPerPage = 20;

/// A provider that fetches the current app user's recent games.
///
/// If the user is logged in, the recent games are fetched from the server.
/// If the user is not logged in, or there is no connectivity, the recent games
/// stored locally are fetched instead.
@riverpod
Future<IList<LightArchivedGameWithPov>> myRecentGames(
  MyRecentGamesRef ref,
) async {
  final online = await ref
      .watch(connectivityChangesProvider.selectAsync((c) => c.isOnline));
  final session = ref.watch(authSessionProvider);
  if (session != null && online) {
    return ref.withClientCacheFor(
      (client) => GameRepository(client)
          .getUserGames(session.user.id, max: kNumberOfRecentGames),
      const Duration(hours: 1),
    );
  } else {
    final storage = ref.watch(gameStorageProvider);
    ref.cacheFor(const Duration(hours: 1));
    return storage
        .page(userId: session?.user.id, max: kNumberOfRecentGames)
        .then(
          (value) => value
              // we can assume that `youAre` is not null either for logged
              // in users or for anonymous users
              .map((e) => (game: e.game.data, pov: e.game.youAre ?? Side.white))
              .toIList(),
        );
  }
}

/// A provider that fetches the recent games from the server for a given user.
@riverpod
Future<IList<LightArchivedGameWithPov>> userRecentGames(
  UserRecentGamesRef ref, {
  required UserId userId,
}) {
  return ref.withClientCacheFor(
    (client) => GameRepository(client).getUserGames(userId),
    // cache is important because the associated widget is in a [ListView] and
    // the provider may be instanciated multiple times in a short period of time
    // (e.g. when scrolling)
    // TODO: consider debouncing the request instead of caching it, or make the
    // request in the parent widget and pass the result to the child
    const Duration(minutes: 1),
  );
}

/// A provider that fetches the total number of games played by given user, or the current app user if no user is provided.
///
/// If the user is logged in, the number of games is fetched from the server.
/// If the user is not logged in, or there is no connectivity, the number of games
/// stored locally are fetched instead.
@riverpod
Future<int> userNumberOfGames(
  UserNumberOfGamesRef ref,
  LightUser? user, {
  required bool isOnline,
}) async {
  final session = ref.watch(authSessionProvider);
  return user != null
      ? ref.watch(
          userProvider(id: user.id).selectAsync((u) => u.count?.all ?? 0),
        )
      : session != null && isOnline
          ? ref.watch(accountProvider.selectAsync((u) => u?.count?.all ?? 0))
          : ref.watch(gameStorageProvider).count(userId: user?.id);
}

/// A provider that paginates the game history for a given user, or the current app user if no user is provided.
///
/// The game history is fetched from the server if the user is logged in and app is online.
/// Otherwise, the game history is fetched from the local storage.
@riverpod
class UserGameHistory extends _$UserGameHistory {
  final _list = <LightArchivedGameWithPov>[];

  @override
  Future<UserGameHistoryState> build(
    UserId? userId, {
    /// Whether the history is requested in an online context. Applicable only
    /// when [userId] is null.
    ///
    /// If this is true, the provider will attempt to fetch the games from the
    /// server. If this is false, the provider will fetch the games from the
    /// local storage.
    required bool isOnline,
  }) async {
    ref.cacheFor(const Duration(minutes: 5));
    ref.onDispose(() {
      _list.clear();
    });

    final session = ref.watch(authSessionProvider);

    final recentGames = userId != null
        ? ref.read(userRecentGamesProvider(userId: userId).future)
        : ref.read(myRecentGamesProvider.future);

    _list.addAll(await recentGames);

    return UserGameHistoryState(
      gameList: _list.toIList(),
      isLoading: false,
      hasMore: true,
      hasError: false,
      online: isOnline,
      session: session,
    );
  }

  /// Fetches the next page of games.
  void getNext() {
    if (!state.hasValue) return;

    final currentVal = state.requireValue;
    state = AsyncData(currentVal.copyWith(isLoading: true));
    Result.capture(
      userId != null
          ? ref.withClient(
              (client) => GameRepository(client).getUserGames(
                userId!,
                max: _nbPerPage,
                until: _list.last.game.createdAt,
              ),
            )
          : currentVal.online && currentVal.session != null
              ? ref.withClient(
                  (client) => GameRepository(client).getUserGames(
                    currentVal.session!.user.id,
                    max: _nbPerPage,
                    until: _list.last.game.createdAt,
                  ),
                )
              : ref
                  .watch(gameStorageProvider)
                  .page(max: _nbPerPage, until: _list.last.game.createdAt)
                  .then(
                    (value) => value
                        // we can assume that `youAre` is not null either for logged
                        // in users or for anonymous users
                        .map(
                          (e) => (
                            game: e.game.data,
                            pov: e.game.youAre ?? Side.white
                          ),
                        )
                        .toIList(),
                  ),
    ).fold(
      (value) {
        if (value.isEmpty) {
          state = AsyncData(
            currentVal.copyWith(hasMore: false, isLoading: false),
          );
          return;
        }

        _list.addAll(value);

        state = AsyncData(
          currentVal.copyWith(
            gameList: _list.toIList(),
            isLoading: false,
            hasMore: value.length == _nbPerPage,
          ),
        );
      },
      (error, stackTrace) {
        state =
            AsyncData(currentVal.copyWith(isLoading: false, hasError: true));
      },
    );
  }
}

@freezed
class UserGameHistoryState with _$UserGameHistoryState {
  const factory UserGameHistoryState({
    required IList<LightArchivedGameWithPov> gameList,
    required bool isLoading,
    required bool hasMore,
    required bool hasError,
    required bool online,
    AuthSessionState? session,
  }) = _UserGameHistoryState;
}

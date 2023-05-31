import 'dart:async';

import 'package:async/async.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_history_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/auth/auth_controller.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_theme.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_repository.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_batch_storage.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_service.dart';
import 'package:lichess_mobile/src/utils/riverpod.dart';

part 'puzzle_providers.g.dart';
part 'puzzle_providers.freezed.dart';

@riverpod
Future<PuzzleContext?> nextPuzzle(
  NextPuzzleRef ref,
  PuzzleTheme theme,
) {
  final session = ref.watch(authSessionProvider);
  // ignore: avoid_manual_providers_as_generated_provider_dependency
  final puzzleService = ref.watch(defaultPuzzleServiceProvider);
  final userId = session?.user.id;
  return puzzleService.nextPuzzle(
    userId: userId,
    angle: theme,
  );
}

@riverpod
Future<PuzzleStreakResponse> streak(StreakRef ref) {
  final repo = ref.watch(puzzleRepositoryProvider);
  return Result.release(repo.streak());
}

@riverpod
Future<PuzzleStormResponse> storm(StormRef ref) {
  final repo = ref.watch(puzzleRepositoryProvider);
  return Result.release(repo.storm());
}

@Riverpod(keepAlive: true)
Future<Puzzle> puzzle(PuzzleRef ref, PuzzleId id) async {
  final historyRepo = ref.watch(puzzleHistoryStorageProvider);
  final puzzle = await historyRepo.fetch(puzzleId: id);
  if (puzzle != null) return puzzle;
  final repo = ref.watch(puzzleRepositoryProvider);
  return Result.release(repo.fetch(id));
}

@Riverpod(keepAlive: true)
Future<Puzzle> dailyPuzzle(DailyPuzzleRef ref) {
  final repo = ref.watch(puzzleRepositoryProvider);
  return Result.release(repo.daily());
}

@riverpod
Future<ISet<PuzzleTheme>> savedThemes(SavedThemesRef ref) {
  final session = ref.watch(authSessionProvider);
  final storage = ref.watch(puzzleBatchStorageProvider);
  return storage.fetchSavedThemes(userId: session?.user.id);
}

@riverpod
Future<PuzzleDashboard> puzzleDashboard(
  PuzzleDashboardRef ref,
  int days,
) async {
  final link = ref.cacheFor(const Duration(minutes: 5));
  final repo = ref.watch(puzzleRepositoryProvider);
  final result = await repo.puzzleDashboard(days);
  if (result.isError) {
    link.close();
  }
  return result.asFuture;
}

@riverpod
class PuzzleHistory extends _$PuzzleHistory {
  StreamSubscription<PuzzleAndResult>? _streamSub;
  final List<PuzzleAndResult> _list = [];
  DateTime _lastDate = DateTime.now();

  @override
  Future<PuzzleHistoryState> build() async {
    ref.cacheFor(const Duration(seconds: 30));
    ref.onDispose(() => _streamSub?.cancel());
    final stream = connectStream();

    return stream.first
        .then((value) => PuzzleHistoryState(historyList: [value]));
  }

  Stream<PuzzleAndResult> connectStream() {
    final repo = ref.watch(puzzleRepositoryProvider);
    final stream = repo.puzzleActivity(10, _lastDate).asBroadcastStream();

    _streamSub?.cancel();
    _streamSub = stream.listen(
      (event) {
        _list.add(event);
      },
      onDone: () {
        state = AsyncData(PuzzleHistoryState(historyList: _list.toList()));
        _lastDate = _list.last.date;
        _list.clear();
        _streamSub?.cancel();
      },
    );
    return stream;
  }

  Future<List<PuzzleAndResult>> getNext() async {
    final repo = ref.watch(puzzleRepositoryProvider);
    final stream = repo.puzzleActivity(50, DateTime.now());
    final completer = Completer<List<PuzzleAndResult>>();

    _streamSub = stream.listen(
      (event) {
        _list.add(event);
      },
      onDone: () {
        completer.complete(_list.toList());
        _lastDate = _list.last.date;
        _list.clear();
        _streamSub?.cancel();
      },
    );

    return completer.future;
  }
}

@freezed
class PuzzleHistoryState with _$PuzzleHistoryState {
  const factory PuzzleHistoryState({
    required List<PuzzleAndResult> historyList,
  }) = _PuzzleHistoryState;
}

import 'dart:async';
import 'package:async/async.dart';
import 'package:result_extensions/result_extensions.dart';
import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    hide Tuple2;

import 'package:lichess_mobile/src/common/move_feedback.dart';
import 'package:lichess_mobile/src/common/sound_service.dart';
import 'package:lichess_mobile/src/common/models.dart';
import 'package:lichess_mobile/src/common/tree.dart';
import 'package:lichess_mobile/src/common/uci.dart';
import 'package:lichess_mobile/src/utils/box.dart';
import 'package:lichess_mobile/src/model/engine/stockfish_engine.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_streak.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_repository.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_service.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_theme.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_preferences.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_session.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_difficulty.dart';

part 'puzzle_view_model.g.dart';
part 'puzzle_view_model.freezed.dart';

@riverpod
class PuzzleViewModel extends _$PuzzleViewModel {
  // ignore: avoid-late-keyword
  late Node _gameTree;
  StockfishEvaluation? _engine;
  Timer? _firstMoveTimer;
  Timer? _viewSolutionTimer;
  // on streak, we pre-load the next puzzle to avoid a delay when the user
  // completes the current one
  FutureResult<PuzzleContext?>? _nextPuzzleFuture;

  @override
  PuzzleViewModelState build(
    PuzzleContext initialContext, {
    PuzzleStreak? initialStreak,
  }) {
    ref.onDispose(() {
      _firstMoveTimer?.cancel();
      _viewSolutionTimer?.cancel();
      _engine?.dispose();
    });

    return _loadNewContext(initialContext, initialStreak);
  }

  Future<void> onUserMove(Move move) async {
    _addMove(move);

    if (state.mode == PuzzleMode.play) {
      final movesToTest =
          state.nodeList.sublist(state.initialPath.size).map((e) => e.sanMove);

      final isGoodMove = state.puzzle.testSolution(movesToTest);

      if (isGoodMove) {
        state = state.copyWith(
          feedback: PuzzleFeedback.good,
        );

        final isCheckmate = movesToTest.last.san.endsWith('#');
        final nextUci =
            state.puzzle.puzzle.solution.getOrNull(movesToTest.length);
        // checkmate is always a win
        if (isCheckmate) {
          _completePuzzle();
        }
        // another puzzle move: let's continue
        else if (nextUci != null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          _addMove(Move.fromUci(nextUci)!);
        }
        // no more puzzle move: it's a win
        else {
          _completePuzzle();
        }
      } else {
        state = state.copyWith(
          feedback: PuzzleFeedback.bad,
        );
        _onFailOrWin(PuzzleResult.lose);
        if (initialStreak == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          _setPath(state.currentPath.penultimate);
        }
      }
    }
  }

  void userNext() {
    _viewSolutionTimer?.cancel();
    _goToNextNode();
  }

  void userPrevious() {
    _viewSolutionTimer?.cancel();
    _goToPreviousNode();
  }

  void viewSolution() {
    if (state.mode == PuzzleMode.view) return;

    _mergeSolution();

    state = state.copyWith(
      nodeList: IList(_gameTree.nodesOn(state.currentPath)),
    );

    _onFailOrWin(PuzzleResult.lose);

    state = state.copyWith(
      mode: PuzzleMode.view,
    );

    _viewSolutionTimer =
        Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (state.canGoNext) {
        _goToNextNode();
      } else {
        timer.cancel();
      }
    });
  }

  void skipMove() {
    if (state.streak != null) {
      state = state.copyWith.streak!(hasSkipped: true);
      final moveIndex = state.currentPath.size - state.initialPath.size;
      final solution = state.puzzle.puzzle.solution[moveIndex];
      onUserMove(Move.fromUci(solution)!);
    }
  }

  Future<PuzzleContext?> changeDifficulty(PuzzleDifficulty difficulty) async {
    state = state.copyWith(
      isChangingDifficulty: true,
    );

    await ref
        .read(
          puzzlePreferencesProvider(initialContext.userId).notifier,
        )
        .setDifficulty(difficulty);

    final nextPuzzle = await ref.read(defaultPuzzleServiceProvider).resetBatch(
          userId: initialContext.userId,
          angle: initialContext.theme,
        );

    state = state.copyWith(
      isChangingDifficulty: false,
    );

    return nextPuzzle;
  }

  void continueWithNextPuzzle(PuzzleContext nextContext) {
    state = _loadNewContext(nextContext, state.streak);
  }

  void sendStreakResult() {
    if (initialContext.userId != null) {
      final repo = ref.read(puzzleRepositoryProvider);
      repo.postStreakRun(state.streak?.index ?? 0);
    }
  }

  FutureResult<PuzzleContext?> retryFetchNextStreakPuzzle(
    PuzzleStreak streak,
  ) async {
    state = state.copyWith(
      nextPuzzleStreakFetchIsRetrying: true,
    );

    final result = await _fetchNextStreakPuzzle(streak);

    state = state.copyWith(
      nextPuzzleStreakFetchIsRetrying: false,
    );

    result.match(
      onSuccess: (nextContext) {
        if (nextContext != null) {
          state = state.copyWith(
            streak: streak.copyWith(
              index: streak.index + 1,
            ),
          );
        } else {
          // no more puzzle
          state = state.copyWith(
            streak: streak.copyWith(
              index: streak.index + 1,
              finished: true,
            ),
          );
        }
      },
    );

    return result;
  }

  PuzzleViewModelState _loadNewContext(
    PuzzleContext context,
    PuzzleStreak? streak,
  ) {
    final root = Root.fromPgn(context.puzzle.game.pgn);
    _gameTree = root.nodeAt(root.mainlinePath.penultimate) as Node;

    // play first move after 1 second
    _firstMoveTimer = Timer(const Duration(seconds: 1), () {
      _setPath(state.initialPath);
      _startEngineEval();
    });

    final initialPath = UciPath.fromId(_gameTree.children.first.id);

    // preload next streak puzzle
    if (streak != null) {
      _nextPuzzleFuture = _fetchNextStreakPuzzle(streak);
    }

    return PuzzleViewModelState(
      puzzle: context.puzzle,
      glicko: context.glicko,
      mode: PuzzleMode.play,
      initialPath: initialPath,
      currentPath: UciPath.empty,
      nodeList: IList([ViewNode.fromNode(_gameTree)]),
      pov: _gameTree.nodeAt(initialPath).ply.isEven ? Side.white : Side.black,
      resultSent: false,
      isChangingDifficulty: false,
      streak: streak,
      nextPuzzleStreakFetchError: false,
      nextPuzzleStreakFetchIsRetrying: false,
    );
  }

  FutureResult<PuzzleContext?> _fetchNextStreakPuzzle(PuzzleStreak streak) {
    return streak.nextId != null
        ? ref.read(puzzleRepositoryProvider).fetch(streak.nextId!).map(
              (puzzle) => PuzzleContext(
                theme: PuzzleTheme.mix,
                puzzle: puzzle,
                userId: initialContext.userId,
              ),
            )
        : Future.value(Result.value(null));
  }

  void _goToNextNode() {
    if (state.node.children.isEmpty) return;
    _setPath(state.currentPath + state.node.children.first.id);
  }

  void _goToPreviousNode() {
    _setPath(state.currentPath.penultimate);
  }

  Future<void> _completePuzzle() async {
    state = state.copyWith(
      mode: PuzzleMode.view,
    );
    await _onFailOrWin(state.result ?? PuzzleResult.win);
    _startEngineEval();
  }

  Future<void> _onFailOrWin(PuzzleResult result) async {
    if (state.resultSent) return;

    state = state.copyWith(
      result: result,
      resultSent: true,
    );

    final sessionNotifier =
        puzzleSessionProvider(initialContext.userId, initialContext.theme)
            .notifier;
    final service = ref.read(defaultPuzzleServiceProvider);
    final soundService = ref.read(soundServiceProvider);

    if (state.streak == null) {
      final next = await service.solve(
        userId: initialContext.userId,
        angle: initialContext.theme,
        solution: PuzzleSolution(
          id: state.puzzle.puzzle.id,
          win: state.result == PuzzleResult.win,
          rated: initialContext.userId != null,
        ),
      );

      final rounds = next?.rounds;
      if (rounds != null) {
        ref.read(sessionNotifier).setRatingDiffs(rounds);
      }

      state = state.copyWith(
        nextContext: next,
      );

      ref.read(sessionNotifier).addAttempt(
            state.puzzle.puzzle.id,
            win: result == PuzzleResult.win,
          );
    } else {
      // one fail and streak is over
      if (result == PuzzleResult.lose) {
        soundService.play(Sound.error);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _setPath(state.currentPath.penultimate);
        _mergeSolution();
        state = state.copyWith(
          mode: PuzzleMode.view,
          nodeList: IList(_gameTree.nodesOn(state.currentPath)),
          streak: state.streak!.copyWith(
            finished: true,
          ),
        );
        _startEngineEval();
        sendStreakResult();
      } else {
        if (_nextPuzzleFuture == null) {
          assert(false, 'next puzzle future cannot be null with streak');
        } else {
          final result = await _nextPuzzleFuture!;
          result.match(
            onSuccess: (nextContext) async {
              state = state.copyWith.streak!(
                index: state.streak!.index + 1,
              );
              if (nextContext != null) {
                await Future<void>.delayed(const Duration(milliseconds: 250));
                soundService.play(Sound.confirmation);
                continueWithNextPuzzle(nextContext);
              } else {
                // no more puzzle
                state = state.copyWith.streak!(
                  finished: true,
                );
              }
            },
            onError: (error, _) {
              state = state.copyWith(
                nextPuzzleStreakFetchError: true,
              );
            },
          );
        }
      }
    }
  }

  void _setPath(UciPath path) {
    final pathChange = state.currentPath != path;
    final newNodeList = IList(_gameTree.nodesOn(path));
    final sanMove = newNodeList.last.sanMove;
    final isForward = path.size > state.currentPath.size;
    if (isForward) {
      final isCheck = sanMove.san.contains('+');
      if (sanMove.san.contains('x')) {
        ref.read(moveFeedbackServiceProvider).captureFeedback(check: isCheck);
      } else {
        ref.read(moveFeedbackServiceProvider).moveFeedback(check: isCheck);
      }
    }
    state = state.copyWith(
      currentPath: path,
      nodeList: newNodeList,
      lastMove: sanMove.move,
    );

    if (pathChange && state.mode == PuzzleMode.view) {
      _startEngineEval();
    }
  }

  void _startEngineEval() {
    // if (state.mode != PuzzleMode.view) return;

    _engine ??= StockfishEvaluation();

    final w = Work(
      threads: 3,
      maxDepth: 20,
      multiPv: 1,
      ply: state.node.ply,
      path: state.currentPath,
      initialFen: _gameTree.nodeAt(state.initialPath).fen,
      currentFen: state.node.fen,
      moves: IList(state.nodeList.map((e) => e.sanMove.move.uci)),
      emit: (work, eval) {
        _gameTree.updateAt(
          work.path,
          (node) => node.copyWith(eval: Box(eval)),
        );
        if (work.path == state.currentPath) {
          state = state.copyWith(
            nodeList: IList(_gameTree.nodesOn(state.currentPath)),
          );
        }
      },
    );

    if (_engine?.isReady == true) {
      _engine?.compute(w);
    } else {
      void computeWhenReady() {
        if (_engine?.isReady == true) {
          _engine?.compute(w);
        }
        _engine?.state.removeListener(computeWhenReady);
      }

      _engine?.state.addListener(computeWhenReady);
    }
  }

  void _addMove(Move move) {
    final tuple = _gameTree.addMoveAt(
      state.currentPath,
      move,
      prepend: state.mode == PuzzleMode.play,
    );
    final newPath = tuple.item1;
    if (newPath != null) {
      _setPath(newPath);
    }
  }

  void _mergeSolution() {
    final initialNode = _gameTree.nodeAt(state.initialPath);
    final fromPly = initialNode.ply;
    final posAndNodes = state.puzzle.puzzle.solution.foldIndexed(
      Tuple2(initialNode.position, IList<Node>(const [])),
      (index, previous, uci) {
        final move = Move.fromUci(uci);
        final tuple = previous.item1.playToSan(move!);
        final newPos = tuple.item1;
        final newSan = tuple.item2;
        return Tuple2(
          newPos,
          previous.item2.add(
            Node(
              id: UciCharPair.fromMove(move),
              ply: fromPly + index,
              fen: newPos.fen,
              position: newPos,
              sanMove: SanMove(newSan, move),
            ),
          ),
        );
      },
    );
    _gameTree.addNodesAt(state.initialPath, posAndNodes.item2, prepend: true);
  }
}

enum PuzzleMode { play, view }

enum PuzzleResult { win, lose }

enum PuzzleFeedback { good, bad }

@freezed
class PuzzleViewModelState with _$PuzzleViewModelState {
  const PuzzleViewModelState._();

  const factory PuzzleViewModelState({
    required Puzzle puzzle,
    required PuzzleGlicko? glicko,
    required PuzzleMode mode,
    required UciPath initialPath,
    required UciPath currentPath,
    required Side pov,
    required IList<ViewNode> nodeList, // must be non empty
    Move? lastMove,
    PuzzleResult? result,
    PuzzleFeedback? feedback,
    required bool resultSent,
    required bool isChangingDifficulty,
    PuzzleContext? nextContext,
    PuzzleStreak? streak,
    // if the automatic attempt to fetch the next puzzle in the streak fails
    // we will make the user retry
    required bool nextPuzzleStreakFetchError,
    required bool nextPuzzleStreakFetchIsRetrying,
  }) = _PuzzleScreenState;

  ViewNode get node => nodeList.last;
  Position get position => nodeList.last.position;
  String get fen => nodeList.last.fen;
  bool get canGoNext => mode == PuzzleMode.view && node.children.isNotEmpty;
  bool get canGoBack =>
      mode == PuzzleMode.view && currentPath.size > initialPath.size;

  IMap<String, ISet<String>> get validMoves => algebraicLegalMoves(position);
}

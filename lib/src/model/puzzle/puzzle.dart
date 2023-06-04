import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lichess_mobile/src/model/common/tree.dart';

import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/common/time_increment.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_theme.dart';

part 'puzzle.freezed.dart';
part 'puzzle.g.dart';

@Freezed(fromJson: true, toJson: true)
class Puzzle with _$Puzzle {
  const Puzzle._();

  const factory Puzzle({
    required PuzzleData puzzle,
    required PuzzleGame game,
    bool? isDailyPuzzle,
  }) = _Puzzle;

  factory Puzzle.fromJson(Map<String, dynamic> json) => _$PuzzleFromJson(json);

  /// Test user moves against solution.
  bool testSolution(Iterable<SanMove> sanMoves) {
    for (var i = 0; i < sanMoves.length; i++) {
      final sanMove = sanMoves.elementAt(i);
      final uci = sanMove.move.uci;
      final isCheckmate = sanMove.san.endsWith('#');
      final solutionUci = puzzle.solution.getOrNull(i);
      if (isCheckmate) {
        return true;
      }
      if (uci != solutionUci &&
          (!altCastles.containsKey(uci) || altCastles[uci] != solutionUci)) {
        return false;
      }
    }
    return true;
  }
}

@Freezed(fromJson: true, toJson: true)
class PuzzleData with _$PuzzleData {
  const PuzzleData._();

  const factory PuzzleData({
    required PuzzleId id,
    required int rating,
    required int plays,
    required int initialPly,
    required IList<UCIMove> solution,
    required ISet<String> themes,
  }) = _PuzzleData;

  factory PuzzleData.fromJson(Map<String, dynamic> json) =>
      _$PuzzleDataFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class PuzzleGlicko with _$PuzzleGlicko {
  const PuzzleGlicko._();

  const factory PuzzleGlicko({
    required double rating,
    required double deviation,
    bool? provisional,
  }) = _PuzzleGlicko;

  factory PuzzleGlicko.fromJson(Map<String, dynamic> json) =>
      _$PuzzleGlickoFromJson(json);
}

@freezed
class PuzzleRound with _$PuzzleRound {
  const factory PuzzleRound({
    required PuzzleId id,
    required int ratingDiff,
    required bool win,
  }) = _PuzzleRound;
}

@Freezed(fromJson: true, toJson: true)
class PuzzleGame with _$PuzzleGame {
  const factory PuzzleGame({
    required GameId id,
    required Perf perf,
    required bool rated,
    required PuzzleGamePlayer white,
    required PuzzleGamePlayer black,
    required String pgn,
    TimeIncrement? clock,
  }) = _PuzzleGame;

  factory PuzzleGame.fromJson(Map<String, dynamic> json) =>
      _$PuzzleGameFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class PuzzleGamePlayer with _$PuzzleGamePlayer {
  const factory PuzzleGamePlayer({
    required Side side,
    required UserId userId,
    required String name,
    String? title,
  }) = _PuzzleGamePlayer;

  factory PuzzleGamePlayer.fromJson(Map<String, dynamic> json) =>
      _$PuzzleGamePlayerFromJson(json);
}

@Freezed(fromJson: true, toJson: true)
class PuzzleSolution with _$PuzzleSolution {
  const factory PuzzleSolution({
    required PuzzleId id,
    required bool win,
    required bool rated,
  }) = _PuzzleSolution;

  factory PuzzleSolution.fromJson(Map<String, dynamic> json) =>
      _$PuzzleSolutionFromJson(json);
}

@freezed
class PuzzlePreview with _$PuzzlePreview {
  const factory PuzzlePreview({
    required Side orientation,
    required String initialFen,
    required Move initialMove,
  }) = _PuzzlePreview;

  factory PuzzlePreview.fromPuzzle(Puzzle puzzle) {
    final root = Root.fromPgn(puzzle.game.pgn);
    final node = root.nodeAt(root.mainlinePath) as Node;
    return PuzzlePreview(
      orientation: node.ply.isEven ? Side.white : Side.black,
      initialFen: node.position.fen,
      initialMove: node.sanMove.move,
    );
  }
}

@Freezed(fromJson: true)
class LitePuzzle with _$LitePuzzle {
  const LitePuzzle._();

  const factory LitePuzzle({
    required PuzzleId id,
    required String fen,
    required IList<UCIMove> solution,
    required int rating,
  }) = _LitePuzzle;

  factory LitePuzzle.fromJson(Map<String, dynamic> json) =>
      _$LitePuzzleFromJson(json);

  (Side, String, Move) get preview {
    final pos1 = Chess.fromSetup(Setup.parseFen(fen));
    final move = Move.fromUci(solution.first);
    final pos = pos1.play(move!);
    return (pos.turn, pos.fen, move);
  }
}

@freezed
class PuzzleDashboard with _$PuzzleDashboard {
  const factory PuzzleDashboard({
    required PuzzleDashboardData global,
    required IList<PuzzleDashboardData> themes,
  }) = _PuzzleDashboard;
}

@freezed
class PuzzleDashboardData with _$PuzzleDashboardData {
  const factory PuzzleDashboardData({
    required int nb,
    required int firstWins,
    required int replayWins,
    required int performance,
    required PuzzleTheme theme,
  }) = _PuzzleDashboardData;
}

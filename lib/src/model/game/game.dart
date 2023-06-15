import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/common/speed.dart';

import 'player.dart';
import 'game_status.dart';

part 'game.freezed.dart';

@freezed
class PlayableGame with _$PlayableGame {
  const PlayableGame._();

  const factory PlayableGame({
    required GameId id,
    required bool rated,
    required Variant variant,
    required Speed speed,
    required Perf perf,
    String? initialFen,
    required GameStatus status,
    required Player white,
    required Player black,
    String? pgn,
    PlayableClockData? clock,
  }) = _PlayableGame;
}

@freezed
class PlayableClockData with _$PlayableClockData {
  const factory PlayableClockData({
    required Duration initial,
    required Duration increment,
    required bool running,
    required Duration white,
    required Duration black,

    /// Remaining time threshold to switch the clock to "emergency" mode.
    Duration? emergency,

    /// Time added to the clock by the "add more time" button.
    Duration? moreTime,
  }) = _PlayableClockData;
}

@freezed
class ArchivedGameData with _$ArchivedGameData {
  const factory ArchivedGameData({
    required GameId id,
    required bool rated,
    required Speed speed,
    required Perf perf,
    required DateTime createdAt,
    required DateTime lastMoveAt,
    required GameStatus status,
    required Player white,
    required Player black,
    required Variant variant,
    String? initialFen,
    String? lastFen,
    Side? winner,
  }) = _ArchivedGameData;
}

@freezed
class ArchivedGame with _$ArchivedGame {
  const ArchivedGame._();

  const factory ArchivedGame({
    required ArchivedGameData data,
    required IList<GameStep> steps,
    // IList<MoveAnalysis>? analysis,
    ClockData? clock,
  }) = _ArchivedGame;

  MaterialDiffSide? materialDiffAt(int cursor, Side side) =>
      steps.isNotEmpty ? steps[cursor].diff.bySide(side) : null;

  GameStep? stepAt(int cursor) => steps.isNotEmpty ? steps[cursor] : null;

  String? fenAt(int cursor) =>
      steps.isNotEmpty ? steps[cursor].position.fen : null;

  Move? moveAt(int cursor) =>
      steps.isNotEmpty ? Move.fromUci(steps[cursor].uci) : null;

  Position? positionAt(int cursor) =>
      steps.isNotEmpty ? steps[cursor].position : null;

  Duration? whiteClockAt(int cursor) =>
      steps.isNotEmpty ? steps[cursor].whiteClock : null;

  Duration? blackClockAt(int cursor) =>
      steps.isNotEmpty ? steps[cursor].blackClock : null;

  Move? get lastMove => steps.isNotEmpty ? Move.fromUci(steps.last.uci) : null;
  Position? get lastPosition => steps.isNotEmpty ? steps.last.position : null;
}

@freezed
class ClockData with _$ClockData {
  const factory ClockData({
    required Duration initial,
    required Duration increment,
  }) = _ClockData;
}

@freezed
class MaterialDiffSide with _$MaterialDiffSide {
  const factory MaterialDiffSide({
    required IMap<Role, int> pieces,
    required int score,
  }) = _MaterialDiffSide;
}

const IMap<Role, int> pieceScores = IMapConst({
  Role.king: 0,
  Role.queen: 9,
  Role.rook: 5,
  Role.bishop: 3,
  Role.knight: 3,
  Role.pawn: 1,
});

@freezed
class MaterialDiff with _$MaterialDiff {
  const MaterialDiff._();

  const factory MaterialDiff({
    required MaterialDiffSide black,
    required MaterialDiffSide white,
  }) = _MaterialDiff;

  factory MaterialDiff.fromBoard(Board board) {
    int score = 0;
    final IMap<Role, int> blackCount = board.materialCount(Side.black);
    final IMap<Role, int> whiteCount = board.materialCount(Side.white);

    Map<Role, int> count;
    Map<Role, int> black;
    Map<Role, int> white;

    count = {
      Role.king: 0,
      Role.queen: 0,
      Role.rook: 0,
      Role.bishop: 0,
      Role.knight: 0,
      Role.pawn: 0,
    };

    black = {
      Role.king: 0,
      Role.queen: 0,
      Role.rook: 0,
      Role.bishop: 0,
      Role.knight: 0,
      Role.pawn: 0,
    };

    white = {
      Role.king: 0,
      Role.queen: 0,
      Role.rook: 0,
      Role.bishop: 0,
      Role.knight: 0,
      Role.pawn: 0,
    };

    whiteCount.forEach((role, cnt) {
      count[role] = cnt - blackCount[role]!;
      score += pieceScores[role]! * count[role]!;
    });

    count.forEach((role, cnt) {
      if (cnt > 0) {
        white[role] = cnt;
      } else if (cnt < 0) {
        black[role] = -cnt;
      }
    });

    return MaterialDiff(
      black: MaterialDiffSide(pieces: black.toIMap(), score: -score),
      white: MaterialDiffSide(pieces: white.toIMap(), score: score),
    );
  }

  MaterialDiffSide bySide(Side side) => side == Side.black ? black : white;
}

@freezed
class GameStep with _$GameStep {
  const factory GameStep({
    required int ply,
    required String san,
    required String uci,
    required Position position,
    required MaterialDiff diff,
    Duration? whiteClock,
    Duration? blackClock,
  }) = _GameStep;
}

@freezed
class PlayerAnalysis with _$PlayerAnalysis {
  const factory PlayerAnalysis({
    required int inaccuracy,
    required int mistake,
    required int blunder,
    int? acpl,
  }) = _PlayerAnalysis;
}

@freezed
class MoveAnalysis with _$MoveAnalysis {
  const factory MoveAnalysis({
    int? eval,
    UCIMove? best,
    String? variation,
    AnalysisJudgment? judgment,
  }) = _MoveAnalysis;
}

@freezed
class AnalysisJudgment with _$AnalysisJudgment {
  const factory AnalysisJudgment({
    required String name,
    required String comment,
  }) = _AnalysisJugdment;
}

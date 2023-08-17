import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/uci.dart';
import 'package:lichess_mobile/src/model/common/eval.dart';
import 'package:lichess_mobile/src/model/common/node.dart';

part 'work.freezed.dart';

typedef EvalResult = (Work, ClientEval);

/// A work item for the engine.
@freezed
class Work with _$Work {
  const Work._();

  const factory Work({
    required Variant variant,
    required int threads,
    int? hashSize,
    bool? stopRequested,
    required UciPath path,
    required int maxDepth,
    required int multiPv,
    bool? threatMode,
    required String initialFen,
    required IList<Step> steps,
    required Position currentPosition,
  }) = _Work;

  /// The work position FEN.
  String get fen => steps.lastOrNull?.fen ?? initialFen;

  /// The work ply.
  int get ply => steps.lastOrNull?.ply ?? 0;

  /// Cached eval for the work position.
  ClientEval? get evalCache => steps.lastOrNull?.eval;
}

@freezed
class Step with _$Step {
  const Step._();

  const factory Step({
    required int ply,
    required String fen,
    required SanMove sanMove,
    ClientEval? eval,
  }) = _Step;

  factory Step.fromNode(ViewBranch node) {
    return Step(
      ply: node.ply,
      fen: node.fen,
      sanMove: node.sanMove,
      eval: node.eval,
    );
  }

  /// Stockfish in chess960 mode always needs a "king takes rook" UCI notation.
  ///
  /// Cannot be used in chess960 variant where this notation is already forced and
  /// where it would conflict with the actual move.
  UCIMove get castleSafeUCI {
    if (sanMove.san == 'O-O' || sanMove.san == 'O-O-O') {
      return _castleMoves.containsKey(sanMove.move.uci)
          ? _castleMoves[sanMove.move.uci]!
          : sanMove.move.uci;
    } else {
      return sanMove.move.uci;
    }
  }
}

const _castleMoves = {
  'e1c1': 'e1a1',
  'e1g1': 'e1h1',
  'e8c8': 'e8a8',
  'e8g8': 'e8h8',
};

import 'dart:math' as math;
import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    hide Tuple2;

import 'package:lichess_mobile/src/model/common/chess.dart';

part 'eval.freezed.dart';

@freezed
class ClientEval with _$ClientEval {
  const ClientEval._();

  const factory ClientEval({
    required String fen,
    required int depth,
    required int nodes,
    required IList<PvData> pvs,
    required int millis,
    required int maxDepth,
    int? cp,
    int? mate,
  }) = _ClientEval;

  double get knps => nodes / millis;

  Move? get bestMove {
    final uci = pvs.firstOrNull?.moves.firstOrNull;
    if (uci == null) return null;
    return Move.fromUci(uci);
  }

  String get evalString {
    if (cp != null) {
      final e = math.max(math.min((cp! / 10).round() / 10, 99), -99);
      return (e > 0 ? '+' : '') + e.toStringAsFixed(1);
    } else if (mate != null) {
      return '#$mate';
    } else {
      return '-';
    }
  }

  /// The winning chances for the given [Side].
  ///
  /// 1  = infinitely winning
  /// -1 = infinitely losing
  double winningChances(Side side) => _toPov(side, _whiteWinningChances);

  double get _whiteWinningChances {
    if (mate != null) {
      return _mateWinningChances(mate!);
    } else if (cp != null) {
      return _cpWinningChances(cp!);
    } else {
      return 0;
    }
  }
}

@freezed
class PvData with _$PvData {
  const factory PvData({
    required IList<UCIMove> moves,
    int? mate,
    int? cp,
  }) = _PvData;
}

double _toPov(Side side, double diff) => side == Side.white ? diff : -diff;

// https://github.com/lichess-org/lila/pull/11148
double _rawWinningChances(num cp) {
  // https://github.com/lichess-org/lila/pull/11148
  const multiplier = -0.00368208;
  return 2 / (1 + math.exp(multiplier * cp)) - 1;
}

double _cpWinningChances(int cp) =>
    _rawWinningChances(math.min(math.max(-1000, cp), 1000));

double _mateWinningChances(int mate) {
  final cp = (21 - math.min(10, mate.abs())) * 100;
  final signed = cp * (mate > 0 ? 1 : -1);
  return _rawWinningChances(signed);
}

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:deep_pick/deep_pick.dart';

enum GameStatus {
  unknown(-1),
  created(10),
  started(20),
  aborted(25),
  mate(30),
  resign(31),
  stalemate(32),
  timeout(33),
  draw(34),
  outoftime(35),
  cheat(36),
  noStart(37),
  unknownFinish(38),
  variantEnd(60);

  const GameStatus(this.value);
  final int value;
}

final IMap<String, GameStatus> gameStatusNameMap =
    IMap(GameStatus.values.asNameMap());

extension GameExtension on Pick {
  GameStatus asGameStatusOrThrow() {
    final value = required().value;
    if (value is GameStatus) {
      return value;
    }
    if (value is String) {
      final gameStatus = gameStatusNameMap[value];
      if (gameStatus != null) {
        return gameStatus;
      }
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to GameStatus",
    );
  }

  GameStatus? asGameStatusOrNull() {
    if (value == null) return null;
    try {
      return asGameStatusOrThrow();
    } catch (_) {
      return null;
    }
  }
}

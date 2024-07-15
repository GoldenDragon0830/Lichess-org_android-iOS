import 'package:deep_pick/deep_pick.dart';

extension type const StringId(String value) {
  StringId.fromJson(dynamic json) : this(json as String);
  String toJson() => value;

  int get length => value.length;
  bool startsWith(String prefix) => value.startsWith(prefix);
}

extension type const GameAnyId._(String value) implements StringId {
  GameAnyId(this.value) : assert(value.length == 8 || value.length == 12);
  GameId get gameId => GameId(value.substring(0, 8));
  bool get isFullId => value.length == 12;
  bool get isGameId => value.length == 8;
  GameFullId? get gameFullId => isFullId ? GameFullId(value) : null;

  GameAnyId.fromJson(dynamic json) : this(json as String);
}

extension type const GameId._(String value) implements StringId, GameAnyId {
  const GameId(this.value) : assert(value.length == 8);

  bool get isValid => RegExp(r'''[\w-]{8}''').hasMatch(value);

  GameId.fromJson(dynamic json) : this(json as String);
}

extension type const GameFullId._(String value) implements StringId, GameAnyId {
  const GameFullId(this.value) : assert(value.length == 12);

  GameFullId.fromJson(dynamic json) : this(json as String);
}

extension type const GamePlayerId._(String value) implements StringId {
  const GamePlayerId(this.value) : assert(value.length == 4);

  GamePlayerId.fromJson(dynamic json) : this(json as String);
}

extension type const PuzzleId(String value) implements StringId {
  PuzzleId.fromJson(dynamic json) : this(json as String);
}

extension type const UserId(String value) implements StringId {
  UserId.fromUserName(String userName) : this(userName.toLowerCase());
  UserId.fromJson(dynamic json) : this(json as String);
}

extension type const ChallengeId(String value) implements StringId {}

extension type const BroadcastRoundId(String value) implements StringId {}

extension IDPick on Pick {
  UserId asUserIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return UserId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to UserId",
    );
  }

  UserId? asUserIdOrNull() {
    if (value == null) return null;
    try {
      return asUserIdOrThrow();
    } catch (_) {
      return null;
    }
  }

  GameId asGameIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return GameId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to GameId",
    );
  }

  GameId? asGameIdOrNull() {
    if (value == null) return null;
    try {
      return asGameIdOrThrow();
    } catch (_) {
      return null;
    }
  }

  GameFullId asGameFullIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return GameFullId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to GameId",
    );
  }

  GameFullId? asGameFullIdOrNull() {
    if (value == null) return null;
    try {
      return asGameFullIdOrThrow();
    } catch (_) {
      return null;
    }
  }

  PuzzleId asPuzzleIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return PuzzleId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to PuzzleId",
    );
  }

  PuzzleId? asPuzzleIdOrNull() {
    if (value == null) return null;
    try {
      return asPuzzleIdOrThrow();
    } catch (_) {
      return null;
    }
  }

  ChallengeId asChallengeIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return ChallengeId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to ChallengeId",
    );
  }

  ChallengeId? asChallengeIdOrNull() {
    if (value == null) return null;
    try {
      return asChallengeIdOrThrow();
    } catch (_) {
      return null;
    }
  }

  BroadcastRoundId asBroadcastRoundIdOrThrow() {
    final value = required().value;
    if (value is String) {
      return BroadcastRoundId(value);
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to BroadcastRoundId",
    );
  }

  BroadcastRoundId? asBroadcastRoundIddOrNull() {
    if (value == null) return null;
    try {
      return asBroadcastRoundIdOrThrow();
    } catch (_) {
      return null;
    }
  }
}

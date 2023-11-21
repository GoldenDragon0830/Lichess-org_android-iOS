import 'package:flutter/widgets.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:deep_pick/deep_pick.dart';

import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/speed.dart';

/// Represents a lichess rating perf item
enum Perf {
  ultraBullet('UltraBullet', 'Ultra', LichessIcons.ultrabullet),
  bullet('Bullet', 'Bullet', LichessIcons.bullet),
  blitz('Blitz', 'Blitz', LichessIcons.blitz),
  rapid('Rapid', 'Rapid', LichessIcons.rapid),
  classical('Classical', 'Classical', LichessIcons.classical),
  correspondence('Correspondence', 'Corresp.', LichessIcons.correspondence),
  fromPosition('From Position', 'From Pos.', LichessIcons.feather),
  chess960('Chess 960', '960', LichessIcons.die_six),
  antichess('Antichess', 'Antichess', LichessIcons.antichess),
  kingOfTheHill('King Of The Hill', 'KotH', LichessIcons.flag),
  threeCheck('Three-check', '3check', LichessIcons.three_check),
  atomic('Atomic', 'Atomic', LichessIcons.atom),
  horde('Horde', 'Horde', LichessIcons.horde),
  racingKings('Racing Kings', 'Racing', LichessIcons.racing_kings),
  crazyhouse('Crazyhouse', 'Crazy', LichessIcons.h_square),
  puzzle('Puzzle', 'Puzzle', LichessIcons.target),
  storm('Storm', 'Storm', LichessIcons.storm);

  const Perf(this.title, this.shortTitle, this.icon);

  final String title;
  final String shortTitle;
  final IconData icon;

  factory Perf.fromVariantAndSpeed(Variant variant, Speed speed) {
    switch (variant) {
      case Variant.standard:
        switch (speed) {
          case Speed.ultraBullet:
            return Perf.ultraBullet;
          case Speed.bullet:
            return Perf.bullet;
          case Speed.blitz:
            return Perf.blitz;
          case Speed.rapid:
            return Perf.rapid;
          case Speed.classical:
            return Perf.classical;
          case Speed.correspondence:
            return Perf.correspondence;
        }
      case Variant.chess960:
        return Perf.chess960;
      case Variant.fromPosition:
        return Perf.fromPosition;
      case Variant.antichess:
        return Perf.antichess;
      case Variant.kingOfTheHill:
        return Perf.kingOfTheHill;
      case Variant.threeCheck:
        return Perf.threeCheck;
      case Variant.atomic:
        return Perf.atomic;
      case Variant.horde:
        return Perf.horde;
      case Variant.racingKings:
        return Perf.racingKings;
      case Variant.crazyhouse:
        return Perf.crazyhouse;
    }
  }

  static IMap<String, Perf> nameMap = IMap(Perf.values.asNameMap());
}

extension PerfExtension on Pick {
  Perf asPerfOrThrow() {
    final value = this.required().value;
    if (value is Perf) {
      return value;
    }
    if (value is String) {
      if (Perf.nameMap.containsKey(value)) {
        return Perf.nameMap[value]!;
      }
    } else if (value is Map<String, dynamic>) {
      final perf = Perf.nameMap[value['key'] as String];
      if (perf != null) {
        return perf;
      }
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to Perf",
    );
  }

  Perf? asPerfOrNull() {
    if (value == null) return null;
    try {
      return asPerfOrThrow();
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:deep_pick/deep_pick.dart';

import 'package:lichess_mobile/src/model/common/time_increment.dart';

/// Represents a lichess rating Speed item
enum Speed {
  ultraBullet(LichessIcons.ultrabullet),
  bullet(LichessIcons.bullet),
  blitz(LichessIcons.blitz),
  rapid(LichessIcons.rapid),
  classical(LichessIcons.classical),
  correspondence(LichessIcons.correspondence);

  const Speed(this.icon);

  final IconData icon;

  factory Speed.fromTimeIncrement(TimeIncrement t) {
    switch (t.duration.inSeconds) {
      case >= 1 && <= 29:
        return Speed.ultraBullet;
      case >= 30 && <= 179:
        return Speed.bullet;
      case >= 180 && <= 479:
        return Speed.blitz;
      case >= 480 && <= 1499:
        return Speed.rapid;
      case >= 1500 && <= 21599:
        return Speed.classical;
      default:
        return Speed.correspondence;
    }
  }
}

final IMap<String, Speed> speedNameMap = IMap(Speed.values.asNameMap());

extension SpeedExtension on Pick {
  Speed asSpeedOrThrow() {
    final value = this.required().value;
    if (value is Speed) {
      return value;
    }
    if (value is String) {
      final speed = speedNameMap[value];
      if (speed != null) return speed;
    }
    throw PickException(
      "value $value at $debugParsingExit can't be casted to Speed",
    );
  }

  Speed? asSpeedOrNull() {
    if (value == null) return null;
    try {
      return asSpeedOrThrow();
    } catch (_) {
      return null;
    }
  }
}

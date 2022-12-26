import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:deep_pick/deep_pick.dart';

import 'package:lichess_mobile/src/common/lichess_icons.dart';
import 'package:lichess_mobile/src/utils/json.dart';

part 'user.freezed.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    String? title,
    bool? patron,
    required DateTime createdAt,
    required DateTime seenAt,
    required Map<Perf, UserPerf> perfs,
    PlayTime? playTime,
    Profile? profile,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      User.fromPick(pick(json).required());

  factory User.fromPick(RequiredPick pick) {
    final perfsMap = pick('perfs').asMapOrThrow<String, Map<String, dynamic>>();
    return User(
      id: pick('id').asStringOrThrow(),
      username: pick('username').asStringOrThrow(),
      title: pick('title').asStringOrNull(),
      patron: pick('patron').asBoolOrNull(),
      createdAt: pick('createdAt').asDateTimeFromMillisecondsOrThrow(),
      seenAt: pick('seenAt').asDateTimeFromMillisecondsOrThrow(),
      playTime: pick('playTime').letOrNull(PlayTime.fromPick),
      profile: pick('profile').letOrNull(Profile.fromPick),
      perfs: Map.unmodifiable({
        for (final entry in perfsMap.entries)
          if (entry.key != 'storm')
            Perf.values.byName(entry.key): UserPerf.fromJson(entry.value)
      }),
    );
  }
}

@freezed
class PlayTime with _$PlayTime {
  const factory PlayTime({
    required Duration total,
    required Duration tv,
  }) = _PlayTime;
  factory PlayTime.fromJson(Map<String, dynamic> json) =>
      PlayTime.fromPick(pick(json).required());

  factory PlayTime.fromPick(RequiredPick pick) {
    return PlayTime(
        total: pick('total').asDurationFromSecondsOrThrow(),
        tv: pick('tv').asDurationFromSecondsOrThrow());
  }
}

@freezed
class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    String? country,
    String? location,
    String? bio,
    String? firstName,
    String? lastName,
    int? fideRating,
    String? links,
  }) = _Profile;

  String? get fullName => firstName != null && lastName != null
      ? '$firstName $lastName'
      : firstName ?? lastName;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile.fromPick(pick(json).required());
  }

  factory Profile.fromPick(RequiredPick pick) => Profile(
        country: pick('country').asStringOrNull(),
        location: pick('location').asStringOrNull(),
        bio: pick('bio').asStringOrNull(),
        firstName: pick('firstName').asStringOrNull(),
        lastName: pick('lastName').asStringOrNull(),
        fideRating: pick('fideRating').asIntOrNull(),
        links: pick('links').asStringOrNull(),
      );
}

@freezed
class UserPerf with _$UserPerf {
  const factory UserPerf({
    required int rating,
    required int ratingDeviation,
    required int progression,
    required int numberOfGames,
    bool? provisional,
  }) = _UserPerf;

  factory UserPerf.fromJson(Map<String, dynamic> json) =>
      UserPerf.fromPick(pick(json).required());

  factory UserPerf.fromPick(RequiredPick pick) => UserPerf(
        rating: pick('rating').asIntOrThrow(),
        ratingDeviation: pick('rd').asIntOrThrow(),
        progression: pick('prog').asIntOrThrow(),
        numberOfGames: pick('games').asIntOrThrow(),
        provisional: pick('prov').asBoolOrNull(),
      );
}

@freezed
class UserStatus with _$UserStatus {
  const factory UserStatus({
    required String id,
    required String name,
    bool? online,
    bool? playing,
  }) = _UserStatus;

  factory UserStatus.fromJson(Map<String, dynamic> json) =>
      UserStatus.fromPick(pick(json).required());

  factory UserStatus.fromPick(RequiredPick pick) => UserStatus(
        id: pick('id').asStringOrThrow(),
        name: pick('name').asStringOrThrow(),
        online: pick('online').asBoolOrNull(),
        playing: pick('playing').asBoolOrNull(),
      );
}

enum Perf {
  ultraBullet('UltraBullet', 'Ultra'),
  bullet('Bullet', 'Bullet'),
  blitz('Blitz', 'Blitz'),
  rapid('Rapid', 'Rapid'),
  classical('Classical', 'Classical'),
  correspondence('Correspondence', 'Corresp.'),
  chess960('Chess 960', '960'),
  antichess('Antichess', 'Antichess'),
  kingOfTheHill('King Of The Hill', 'KotH'),
  threeCheck('Three-check', '3check'),
  atomic('Atomic', 'Atomic'),
  horde('Horde', 'Horde'),
  racingKings('Racing Kings', 'Racing'),
  crazyhouse('Crazyhouse', 'Crazy'),
  puzzle('Puzzle', 'Puzzle'),
  storm('Storm', 'Storm');

  const Perf(this.name, this.shortName);

  final String name;
  final String shortName;

  IconData get icon {
    switch (this) {
      case ultraBullet:
        return LichessIcons.ultrabullet;
      case bullet:
        return LichessIcons.bullet;
      case blitz:
        return LichessIcons.blitz;
      case rapid:
        return LichessIcons.rapid;
      case classical:
        return LichessIcons.classical;
      case correspondence:
        return LichessIcons.correspondence;
      case chess960:
        return LichessIcons.die_six;
      case antichess:
        return LichessIcons.antichess;
      case kingOfTheHill:
        return LichessIcons.flag;
      case threeCheck:
        return LichessIcons.three_check;
      case atomic:
        return LichessIcons.atom;
      case horde:
        return LichessIcons.horde;
      case crazyhouse:
        return LichessIcons.h_square;
      case puzzle:
        return LichessIcons.target;
      case storm:
        return LichessIcons.storm;
      default:
        debugPrint('SEVERE at ${DateTime.now()} perf $this icon not found');
        return LichessIcons.chess_king;
    }
  }
}

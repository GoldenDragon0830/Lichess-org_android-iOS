import 'package:deep_pick/deep_pick.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/common/models.dart';
import 'package:lichess_mobile/src/utils/json.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@Freezed(fromJson: true, toJson: true)
class LightUser with _$LightUser {
  const factory LightUser({
    required UserId id,
    required String name,
    String? title,
    bool? isPatron,
  }) = _LightUser;

  factory LightUser.fromJson(Map<String, dynamic> json) =>
      _$LightUserFromJson(json);
}

@freezed
class User with _$User {
  const User._();

  const factory User({
    required UserId id,
    required String username,
    String? title,
    bool? isPatron,
    required DateTime createdAt,
    required DateTime seenAt,
    required IMap<Perf, UserPerf> perfs,
    PlayTime? playTime,
    Profile? profile,
  }) = _User;

  LightUser get lightUser =>
      LightUser(id: id, name: username, title: title, isPatron: isPatron);

  factory User.fromJson(Map<String, dynamic> json) =>
      User.fromPick(pick(json).required());

  factory User.fromPick(RequiredPick pick) {
    final receivedPerfsMap =
        pick('perfs').asMapOrEmpty<String, Map<String, dynamic>>();
    return User(
      id: pick('id').asUserIdOrThrow(),
      username: pick('username').asStringOrThrow(),
      title: pick('title').asStringOrNull(),
      isPatron: pick('patron').asBoolOrNull(),
      createdAt: pick('createdAt').asDateTimeFromMillisecondsOrThrow(),
      seenAt: pick('seenAt').asDateTimeFromMillisecondsOrThrow(),
      playTime: pick('playTime').letOrNull(PlayTime.fromPick),
      profile: pick('profile').letOrNull(Profile.fromPick),
      perfs: IMap({
        for (final entry in receivedPerfsMap.entries)
          if (perfNameMap.containsKey(entry.key) && entry.key != 'storm')
            perfNameMap.get(entry.key)!: UserPerf.fromJson(entry.value)
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
      tv: pick('tv').asDurationFromSecondsOrThrow(),
    );
  }
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    String? country,
    String? location,
    String? bio,
    String? firstName,
    String? lastName,
    int? fideRating,
    String? links,
  }) = _Profile;

  const Profile._();

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
    required UserId id,
    required String name,
    bool? online,
    bool? playing,
  }) = _UserStatus;

  factory UserStatus.fromJson(Map<String, dynamic> json) =>
      UserStatus.fromPick(pick(json).required());

  factory UserStatus.fromPick(RequiredPick pick) => UserStatus(
        id: pick('id').asUserIdOrThrow(),
        name: pick('name').asStringOrThrow(),
        online: pick('online').asBoolOrNull(),
        playing: pick('playing').asBoolOrNull(),
      );
}

@freezed
class UserActivityTournament with _$UserActivityTournament {
  const factory UserActivityTournament({
    required String id,
    required String name,
    required int nbGames,
    required int score,
    required int rank,
    required int rankPercent,
  }) = _UserActivityTournament;

  factory UserActivityTournament.fromJson(Map<String, dynamic> json) =>
      UserActivityTournament.fromPick(pick(json).required());

  factory UserActivityTournament.fromPick(RequiredPick pick) =>
      UserActivityTournament(
        id: pick('tournament', 'id').asStringOrThrow(),
        name: pick('tournament', 'name').asStringOrThrow(),
        nbGames: pick('nbGames').asIntOrThrow(),
        score: pick('score').asIntOrThrow(),
        rank: pick('rank').asIntOrThrow(),
        rankPercent: pick('rankPercent').asIntOrThrow(),
      );
}

@freezed
class UserActivityGameScore with _$UserActivityGameScore {
  const factory UserActivityGameScore({
    required int win,
    required int loss,
    required int draw,
    required int rpBefore,
    required int rpAfter,
  }) = _UserActivityGameScore;

  factory UserActivityGameScore.fromJson(Map<String, dynamic> json) =>
      UserActivityGameScore.fromPick(pick(json).required());

  factory UserActivityGameScore.fromPick(RequiredPick pick) =>
      UserActivityGameScore(
        win: pick('win').asIntOrThrow(),
        loss: pick('loss').asIntOrThrow(),
        draw: pick('draw').asIntOrThrow(),
        rpBefore: pick('rp', 'before').asIntOrThrow(),
        rpAfter: pick('rp', 'after').asIntOrThrow(),
      );
}

@freezed
class UserActivity with _$UserActivity {
  const factory UserActivity({
    required DateTime startTime,
    required DateTime endTime,
    IMap<Perf, UserActivityGameScore>? games,
    IList<String?>? followIn,
    int? followInNb,
    IList<String?>? followOut,
    int? followOutNb,
    IList<UserActivityTournament?>? tournament,
    int? tournamentNb,
    UserActivityGameScore? puzzle,
    UserActivityGameScore? correspondenceEnds,
    int? correspondenceMovesNb,
  }) = _UserActivity;
}

@freezed
class UserPerfStats with _$UserPerfStats {
  const factory UserPerfStats({
    required double rating,
    required double deviation,
    bool? provisional,
    required int totalGames,
    required int progress,
    int? rank,
    double? percentile,
    required int berserkGames,
    required int tournamentGames,
    required int ratedGames,
    required int wonGames,
    required int lostGames,
    required int drawnGames,
    required int disconnections,
    double? avgOpponent,
    required Duration timePlayed,
    int? lowestRating,
    UserPerfGame? lowestRatingGame,
    int? highestRating,
    UserPerfGame? highestRatingGame,
    UserStreak? curWinStreak,
    UserStreak? maxWinStreak,
    UserStreak? curLossStreak,
    UserStreak? maxLossStreak,
    UserStreak? curPlayStreak,
    UserStreak? maxPlayStreak,
    UserStreak? curTimeStreak,
    UserStreak? maxTimeStreak,
    IList<UserPerfGame>? worstLosses,
    IList<UserPerfGame>? bestWins,
  }) = _UserPerfStats;
}

@freezed
class UserStreak with _$UserStreak {
  const factory UserStreak.gameStreak({
    required int gamesPlayed,
    required bool isValueEmpty,
    required UserPerfGame? startGame,
    required UserPerfGame? endGame,
  }) = UserGameStreak;

  const factory UserStreak.timeStreak({
    required Duration timePlayed,
    required bool isValueEmpty,
    required UserPerfGame? startGame,
    required UserPerfGame? endGame,
  }) = UserTimeStreak;
}

@freezed
class UserPerfGame with _$UserPerfGame {
  const factory UserPerfGame({
    required DateTime finishedAt,
    required GameId gameId,
    int? opponentRating,
    String? opponentId,
    String? opponentName,
    String? opponentTitle,
  }) = _UserPerfGame;
}

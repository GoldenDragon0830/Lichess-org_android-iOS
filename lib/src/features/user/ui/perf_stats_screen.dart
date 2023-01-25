import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lichess_mobile/src/common/lichess_colors.dart';
import 'package:lichess_mobile/src/common/lichess_icons.dart';
import 'package:lichess_mobile/src/common/models.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/features/user/data/user_repository.dart';
import 'package:lichess_mobile/src/features/user/model/user.dart';
import 'package:lichess_mobile/src/utils/duration.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/utils/style.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';

final perfStatsProvider = FutureProvider.autoDispose
    .family<UserPerfStats, UserPerfStatsParameters>((ref, perfParams) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final either = await userRepo
      .getUserPerfStatsTask(
        perfParams.username,
        perfParams.perf,
      )
      .run();

  return either.match((error) => throw error, (data) {
    ref.keepAlive();
    return data;
  });
});

const _customOpacity = 0.6;
const _defaultStatFontSize = 12.0;
const _defaultValueFontSize = 18.0;
const _titleFontSize = 18.0;
const _mainValueStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 30);

class PerfStatsScreen extends ConsumerWidget {
  const PerfStatsScreen(
      {required this.username,
      required this.perf,
      required this.loggedInUser,
      super.key});

  final String username;
  final Perf perf;
  final User? loggedInUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConsumerPlatformWidget(
        ref: ref, androidBuilder: _androidBuilder, iosBuilder: _iosBuilder);
  }

  Widget _androidBuilder(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(perf.icon),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.l10n.perfStats('$username ${perf.title}'),
                    style: const TextStyle(fontSize: _titleFontSize),
                  ),
                ),
              ),
              const SizedBox(width: 5)
            ],
          ),
        ),
        body: _buildBody(context, ref));
  }

  Widget _iosBuilder(BuildContext context, WidgetRef ref) {
    // TODO: Add perf icon to title.
    return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(),
        child: _buildBody(context, ref));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final perfStats = ref.watch(perfStatsProvider(
        UserPerfStatsParameters(username: username, perf: perf)));

    const statGroupSpace = SizedBox(height: 15.0);

    return perfStats.when(
      data: (data) {
        return SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5.0),
          child: ListView(scrollDirection: Axis.vertical, children: [
            _CustomPlatformCard(context.l10n.rating,
                child: _MainRatingWidget(
                  data.rating,
                  data.deviation,
                  data.percentile,
                  username,
                  perf.title,
                  loggedInUser,
                  provisional: data.provisional,
                )),
            // The number '12' here is not arbitrary, since the API returns the progression for the last 12 games (as far as I know).
            _CustomPlatformCard(
                context.l10n.progressOverLastXGames('12').replaceAll(':', ''),
                child: _ProgressionWidget(data.progress)),
            _CustomPlatformCardRow([
              _CustomPlatformCard(context.l10n.rank,
                  value: data.rank == null
                      ? '?'
                      : NumberFormat.decimalPattern(Intl.getCurrentLocale())
                          .format(data.rank)),
              _CustomPlatformCard(
                  context.l10n.ratingDeviation('').replaceAll(': .', ''),
                  value: data.deviation.toStringAsFixed(2))
            ]),
            _CustomPlatformCardRow([
              _CustomPlatformCard(
                  context.l10n.highestRating('').replaceAll(':', ''),
                  child: _RatingWidget(data.highestRating,
                      data.highestRatingGame, LichessColors.good)),
              _CustomPlatformCard(
                  context.l10n.lowestRating('').replaceAll(':', ''),
                  child: _RatingWidget(data.lowestRating, data.lowestRatingGame,
                      LichessColors.red)),
            ]),
            statGroupSpace,
            _CustomPlatformCard(context.l10n.totalGames,
                value: data.totalGames.toString(), styleValue: _mainValueStyle),
            _CustomPlatformCardRow([
              _CustomPlatformCard(context.l10n.wins,
                  child: _PercentageValueWidget(data.wonGames, data.totalGames,
                      color: LichessColors.good)),
              _CustomPlatformCard(context.l10n.draws,
                  child: _PercentageValueWidget(
                      data.drawnGames, data.totalGames,
                      color: textShade(context, _customOpacity),
                      isShaded: true)),
              _CustomPlatformCard(context.l10n.losses,
                  child: _PercentageValueWidget(data.lostGames, data.totalGames,
                      color: LichessColors.red)),
            ]),
            _CustomPlatformCardRow([
              _CustomPlatformCard(context.l10n.rated,
                  child:
                      _PercentageValueWidget(data.ratedGames, data.totalGames)),
              _CustomPlatformCard(context.l10n.tournament,
                  child: _PercentageValueWidget(
                      data.tournamentGames, data.totalGames)),
              _CustomPlatformCard(
                  context.l10n.berserkedGames
                      .replaceAll(' ${context.l10n.games.toLowerCase()}', ''),
                  child: _PercentageValueWidget(
                      data.berserkGames, data.totalGames)),
              _CustomPlatformCard(context.l10n.disconnections,
                  child: _PercentageValueWidget(
                      data.disconnections, data.totalGames)),
            ]),
            _CustomPlatformCardRow([
              _CustomPlatformCard(context.l10n.averageOpponent,
                  value: data.avgOpponent == null
                      ? '?'
                      : data.avgOpponent.toString()),
              _CustomPlatformCard(context.l10n.timeSpentPlaying,
                  value: data.timePlayed.toDaysHoursMinutes(context)),
            ]),
            statGroupSpace,
            _CustomPlatformCard(
              context.l10n.winningStreak,
              child: _StreakWidget(data.maxWinStreak, data.curWinStreak,
                  color: LichessColors.good),
            ),
            _CustomPlatformCard(
              context.l10n.losingStreak,
              child: _StreakWidget(data.maxLossStreak, data.curLossStreak,
                  color: LichessColors.red),
            ),
            _CustomPlatformCard(
              context.l10n.gamesInARow,
              child: _StreakWidget(data.maxPlayStreak, data.curPlayStreak),
            ),
            _CustomPlatformCard(
              context.l10n.maxTimePlaying,
              child: _StreakWidget(data.maxTimeStreak, data.curTimeStreak),
            ),
            statGroupSpace,
            _CustomPlatformCard(context.l10n.bestRated,
                child: _GameListWidget(data.bestWins)),
            _CustomPlatformCard(context.l10n.worstRated,
                child: _GameListWidget(data.worstLosses))
          ]),
        ));
      },
      error: (error, stackTrace) {
        debugPrint(
            'SEVERE: [PerfStatsScreen] could not load user games; ${error.toString()}\n$stackTrace');
        return const Center(child: Text('Could not load user stats.'));
      },
      loading: () => const CenterLoadingIndicator(),
    );
  }
}

class _CustomPlatformCard extends StatelessWidget {
  final String stat;
  final Widget? child;
  final String? value;
  final TextStyle? styleValue;

  const _CustomPlatformCard(this.stat,
      {this.child, this.value, this.styleValue});

  @override
  Widget build(BuildContext context) {
    final defaultStatStyle = TextStyle(
      color: textShade(context, _customOpacity),
      fontSize: _defaultStatFontSize,
    );

    const defaultValueStyle = TextStyle(fontSize: _defaultValueFontSize);

    final TextStyle trueValueStyle = styleValue ?? defaultValueStyle;

    return PlatformCard(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FittedBox(
              alignment: Alignment.center,
              fit: BoxFit.scaleDown,
              child: Text(stat,
                  style: defaultStatStyle, textAlign: TextAlign.center)),
          if (value != null)
            Text(value!, style: trueValueStyle, textAlign: TextAlign.center)
          else if (child != null)
            child!
          else
            Text('?', style: trueValueStyle)
        ],
      ),
    ));
  }
}

class _CustomPlatformCardRow extends StatelessWidget {
  final List<_CustomPlatformCard> cards;

  const _CustomPlatformCardRow(this.cards);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final card in cards) Expanded(child: card)]),
    );
  }
}

class _MainRatingWidget extends StatelessWidget {
  final double rating;
  final double deviation;
  final double? percentile;
  final String username;
  final String perfTitle;
  final bool? provisional;
  final User? loggedInUser;

  const _MainRatingWidget(this.rating, this.deviation, this.percentile,
      this.username, this.perfTitle, this.loggedInUser,
      {this.provisional});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(
          '${rating.toStringAsFixed(2)}${provisional == true || deviation > kProvisionalDeviation ? '?' : ''}',
          style: _mainValueStyle),
      if (percentile != null)
        Text(
            (loggedInUser != null && loggedInUser!.username == username)
                ? context.l10n.youAreBetterThanPercentOfPerfTypePlayers(
                    '${percentile!.toStringAsFixed(2)}%', perfTitle)
                : context.l10n.userIsBetterThanPercentOfPerfTypePlayers(
                    username, '${percentile!.toStringAsFixed(2)}%', perfTitle),
            style: TextStyle(
                fontSize: _defaultStatFontSize,
                color: textShade(context, _customOpacity)),
            textAlign: TextAlign.center)
    ]);
  }
}

class _ProgressionWidget extends StatelessWidget {
  final int progress;

  const _ProgressionWidget(this.progress);

  @override
  Widget build(BuildContext context) {
    const progressionFontSize = 20.0;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (progress != 0) ...[
        Icon(
          progress > 0
              ? LichessIcons.arrow_full_upperright
              : LichessIcons.arrow_full_lowerright,
          color: progress > 0 ? LichessColors.good : LichessColors.red,
        ),
        Text(progress.abs().toString(),
            style: TextStyle(
                color: progress > 0 ? LichessColors.good : LichessColors.red,
                fontSize: progressionFontSize)),
      ] else
        Text('0',
            style: TextStyle(
                color: textShade(context, _customOpacity),
                fontSize: progressionFontSize))
    ]);
  }
}

class _UserGameWidget extends StatelessWidget {
  final UserPerfGame? game;

  const _UserGameWidget(this.game);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement functionality to view game on tap.
    // (Return a button? Wrap with InkWell?)
    const defaultDateFontSize = 16.0;
    const defaultDateStyle =
        TextStyle(color: LichessColors.primary, fontSize: defaultDateFontSize);

    final dateFormatter = DateFormat.yMMMd(Intl.getCurrentLocale());

    return game == null
        ? const Text('?', style: defaultDateStyle)
        : Text(dateFormatter.format(game!.finishedAt), style: defaultDateStyle);
  }
}

class _RatingWidget extends StatelessWidget {
  final int? rating;
  final UserPerfGame? game;
  final Color color;

  const _RatingWidget(this.rating, this.game, this.color);

  @override
  Widget build(BuildContext context) {
    return (rating == null)
        ? const Text('?', style: TextStyle(fontSize: _defaultValueFontSize))
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rating.toString(),
                  style:
                      TextStyle(fontSize: _defaultValueFontSize, color: color)),
              _UserGameWidget(game)
            ],
          );
  }
}

class _PercentageValueWidget extends StatelessWidget {
  final int value;
  final int denominator;
  final Color? color;
  final bool isShaded;

  const _PercentageValueWidget(this.value, this.denominator,
      {this.color, this.isShaded = false});

  String _getPercentageString(num numerator, num denominator) {
    return '${((numerator / denominator) * 100).round().toString()}%';
  }

  @override
  Widget build(BuildContext context) {
    final trueColor = color ?? DefaultTextStyle.of(context).style.color;

    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value.toString(),
          style: TextStyle(fontSize: _defaultValueFontSize, color: trueColor)),
      Text(_getPercentageString(value, denominator),
          style: TextStyle(
              fontSize: _defaultValueFontSize,
              color: isShaded
                  ? trueColor!.withOpacity(_customOpacity / 2)
                  : trueColor!.withOpacity(_customOpacity)))
    ]);
  }
}

class _StreakWidget extends StatelessWidget {
  final UserStreak? maxStreak;
  final UserStreak? curStreak;
  final Color? color;

  const _StreakWidget(this.maxStreak, this.curStreak, {this.color});

  @override
  Widget build(BuildContext context) {
    final trueColor = color ?? DefaultTextStyle.of(context).style.color;
    final valueStyle =
        TextStyle(color: trueColor, fontSize: _defaultValueFontSize);

    final streakTitleStyle = TextStyle(
        fontSize: _defaultStatFontSize,
        color: textShade(context, _customOpacity));

    final List<Widget> streakWidgets = List.empty(growable: true);
    final longestStreakStr = context.l10n.longestStreak('').replaceAll(':', '');
    final currentStreakStr = context.l10n.currentStreak('').replaceAll(':', '');
    // This variable may seem useless, why not check (streak == maxStreak)?
    // Because this avoids the rare case where maxStreak == curStreak and the same title is shown twice.
    bool inFirstLoop = true;

    for (final streak in [maxStreak, curStreak]) {
      final streakTitle = Text(
          inFirstLoop ? longestStreakStr : currentStreakStr,
          style: streakTitleStyle);

      if (streak == null || streak.isValueZero()) {
        streakWidgets.add(Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              streakTitle,
              const Text('-', style: TextStyle(fontSize: _defaultValueFontSize))
            ],
          ),
        ));
      } else {
        streakWidgets.add(Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            streakTitle,
            if (streak is UserTimeStreak)
              Text(streak.timePlayed.toDaysHoursMinutes(context),
                  style: valueStyle, textAlign: TextAlign.center)
            else if (streak is UserGameStreak)
              Text(context.l10n.nbGames(streak.gamesPlayed),
                  style: valueStyle, textAlign: TextAlign.center),
            if (!(streak.startGame == null && streak.endGame == null))
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 5.0),
                  _UserGameWidget(streak.startGame),
                  Icon(Icons.arrow_downward_rounded,
                      color: textShade(context, _customOpacity)),
                  _UserGameWidget(streak.endGame)
                ],
              )
          ]),
        ));
      }
      inFirstLoop = false;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 5.0),
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: streakWidgets)
      ],
    );
  }
}

class _GameListWidget extends StatelessWidget {
  final List<UserPerfGame>? games;

  const _GameListWidget(this.games);

  @override
  Widget build(BuildContext context) {
    final List<Widget> gameWidgets = List.empty(growable: true);

    const gameWidgetSeparation = 5.0;
    const opRatingFontSize = 16.0;

    if (games == null || games!.isEmpty) {
      gameWidgets.add(const Text('?'));
    } else {
      for (final game in games!) {
        gameWidgets.add(
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(game.opponentName ?? '?',
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
          ),
          Expanded(
            child: Align(
                alignment: Alignment.center,
                child: Text(
                    game.opponentRating == null
                        ? '?'
                        : game.opponentRating.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: opRatingFontSize))),
          ),
          Expanded(
            child: Align(
                alignment: Alignment.centerRight, child: _UserGameWidget(game)),
          )
        ]));
        gameWidgets.add(const SizedBox(height: gameWidgetSeparation));
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: gameWidgets,
    );
  }
}

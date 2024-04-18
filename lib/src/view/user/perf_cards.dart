import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/common/perf.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/view/account/rating_pref_aware.dart';
import 'package:lichess_mobile/src/view/puzzle/dashboard_screen.dart';
import 'package:lichess_mobile/src/view/puzzle/storm_dashboard.dart';
import 'package:lichess_mobile/src/view/user/perf_stats_screen.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/rating.dart';

class PerfCards extends StatelessWidget {
  const PerfCards({required this.user, required this.isMe, super.key});

  final User user;

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    List<Perf> userPerfs = Perf.values.where((element) {
      final p = user.perfs[element];
      return p != null &&
          p.numberOfGames > 0 &&
          p.ratingDeviation < kClueLessDeviation;
    }).toList(growable: false);

    userPerfs.sort(
      (p1, p2) => user.perfs[p1]!.numberOfGames
          .compareTo(user.perfs[p2]!.numberOfGames),
    );
    userPerfs = userPerfs.reversed.toList();

    if (userPerfs.isEmpty) {
      return const SizedBox.shrink();
    }

    return RatingPrefAware(
      child: Padding(
        padding: Styles.bodySectionPadding,
        child: SizedBox(
          height: 106,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            scrollDirection: Axis.horizontal,
            itemCount: userPerfs.length,
            itemBuilder: (context, index) {
              final perf = userPerfs[index];
              final userPerf = user.perfs[perf]!;
              final bool isPerfWithoutStats = Perf.streak == perf;
              return SizedBox(
                height: 100,
                width: 100,
                child: PlatformCard(
                  child: AdaptiveInkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: isPerfWithoutStats
                        ? null
                        : () => _handlePerfCardTap(context, perf),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            perf.shortTitle,
                            style: TextStyle(color: textShade(context, 0.7)),
                          ),
                          Icon(perf.icon, color: textShade(context, 0.6)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              RatingWidget(
                                rating: userPerf.rating,
                                deviation: userPerf.ratingDeviation,
                                provisional: userPerf.provisional,
                                style: Styles.bold,
                              ),
                              const SizedBox(width: 3),
                              if (userPerf.progression != 0) ...[
                                Icon(
                                  userPerf.progression > 0
                                      ? LichessIcons.arrow_full_upperright
                                      : LichessIcons.arrow_full_lowerright,
                                  color: userPerf.progression > 0
                                      ? context.lichessColors.good
                                      : context.lichessColors.error,
                                  size: 12,
                                ),
                                Text(
                                  userPerf.progression.abs().toString(),
                                  style: TextStyle(
                                    color: userPerf.progression > 0
                                        ? context.lichessColors.good
                                        : context.lichessColors.error,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 10),
          ),
        ),
      ),
    );
  }

  void _handlePerfCardTap(BuildContext context, Perf perf) {
    pushPlatformRoute(
      context,
      builder: (context) {
        switch (perf) {
          case Perf.storm:
            return StormDashboardModal(user: user.lightUser);
          default:
            return PerfStatsScreen(
              user: user,
              perf: perf,
            );
        }
      },
    );
  }
}

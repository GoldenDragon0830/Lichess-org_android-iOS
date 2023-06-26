import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:lichess_mobile/src/model/game/material_diff.dart';

import 'package:lichess_mobile/src/styles/lichess_colors.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/game/player.dart';
import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/ui/user/user_screen.dart';
import './countdown_clock.dart';

/// A widget to display player information above/below the chess board.
///
/// It shows the full player name with title and rating and the clock if relevant.

class BoardPlayer extends StatelessWidget {
  const BoardPlayer({
    required this.player,
    this.active,
    this.clock,
    this.materialDiff,
    super.key,
  });

  final Player player;
  final Duration? clock;
  final bool? active;
  final MaterialDiffSide? materialDiff;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final playerFontSize =
        screenHeight < kSmallHeightScreenThreshold ? 14.0 : 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: player.lightUser != null
                    ? () {
                        pushPlatformRoute(
                          context,
                          builder: (context) =>
                              UserScreen(user: player.lightUser!),
                        );
                      }
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (player.title != null) ...[
                          Text(
                            player.title!,
                            style: TextStyle(
                              fontSize: playerFontSize,
                              fontWeight: FontWeight.bold,
                              color: LichessColors.brag,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            player.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: playerFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (player.rating != null)
                          Text.rich(
                            TextSpan(
                              text:
                                  '${player.rating}${player.provisional == true ? '?' : ''}',
                              children: [
                                if (player.ratingDiff != null)
                                  TextSpan(
                                    text:
                                        ' ${player.ratingDiff! > 0 ? '+' : ''}${player.ratingDiff}',
                                    style: TextStyle(
                                      color: player.ratingDiff! > 0
                                          ? LichessColors.green
                                          : LichessColors.red,
                                    ),
                                  ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: textShade(context, 0.7),
                            ),
                          ),
                      ],
                    ),
                    if (materialDiff != null)
                      Row(
                        children: [
                          for (final role in Role.values)
                            for (int i = 0;
                                i < materialDiff!.pieces[role]!;
                                i++)
                              Icon(
                                _iconByRole[role],
                                size: 13,
                                color: Colors.grey,
                              ),
                          const SizedBox(width: 3),
                          Text(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            materialDiff != null && materialDiff!.score > 0
                                ? '+${materialDiff!.score}'
                                : '',
                          )
                        ],
                      )
                    else
                      const Text('', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          if (clock != null)
            CountdownClock(
              duration: clock!,
              active: active == true,
            ),
        ],
      ),
    );
  }
}

class PlayerRating extends StatelessWidget {
  const PlayerRating({
    required this.rating,
    required this.deviation,
    this.provisional,
    this.style,
    super.key,
  });

  final num rating;
  final num deviation;
  final bool? provisional;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final ratingStr =
        rating is double ? rating.toStringAsFixed(2) : rating.toString();
    return Text(
      '$ratingStr${provisional == true || deviation > kProvisionalDeviation ? '?' : ''}',
      style: style,
    );
  }
}

/// Displays a player's name and title with an optional rating.
class PlayerTitle extends StatelessWidget {
  const PlayerTitle({
    required this.userName,
    this.title,
    this.rating,
    this.style,
    super.key,
  });

  final String userName;
  final String? title;
  final int? rating;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final nameAndRating = userName + (rating != null ? ' ($rating)' : '');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: (style ?? const TextStyle()).copyWith(
              color: title == 'BOT' ? LichessColors.fancy : LichessColors.brag,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5)
        ],
        Flexible(
          child: Text(
            nameAndRating,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

const Map<Role, IconData> _iconByRole = {
  Role.king: LichessIcons.chess_king,
  Role.queen: LichessIcons.chess_queen,
  Role.rook: LichessIcons.chess_rook,
  Role.bishop: LichessIcons.chess_bishop,
  Role.knight: LichessIcons.chess_knight,
  Role.pawn: LichessIcons.chess_pawn,
};

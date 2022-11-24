import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chessground/chessground.dart';

import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/widgets/player.dart';

import './tv_feed.dart';
import './tv_screen_controller.dart';

class TvScreen extends ConsumerWidget {
  const TvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final tvFeed = ref.watch(tvFeedProvider);
    final tvState = ref.watch(tvFeedStateNotifierProvider);
    final isMuted = ref.watch(tvScreenControllerProvier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lichess TV'),
        actions: [
          IconButton(
              icon: isMuted
                  ? const Icon(Icons.volume_off)
                  : const Icon(Icons.volume_up),
              onPressed: () =>
                  ref.read(tvScreenControllerProvier.notifier).toggleSound())
        ],
      ),
      body: Center(
        child: tvFeed.when(
          data: (tvEvent) {
            final topPlayer = tvState != null
                ? tvState.orientation == Side.white
                    ? tvState.black
                    : tvState.white
                : null;
            final bottomPlayer = tvState != null
                ? tvState.orientation == Side.white
                    ? tvState.white
                    : tvState.black
                : null;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                topPlayer != null
                    ? Player(
                        name: topPlayer.name,
                        title: topPlayer.title,
                        rating: topPlayer.rating,
                        clock: Duration(seconds: topPlayer.seconds),
                        active: tvEvent.isGameOngoing &&
                            tvEvent.turn == topPlayer.side)
                    : const SizedBox.shrink(),
                Board(
                  interactableSide: InteractableSide.none,
                  settings: const Settings(animationDuration: Duration.zero),
                  size: screenWidth,
                  orientation: tvState?.orientation ?? Side.white,
                  fen: tvEvent.fen,
                  lastMove: tvEvent.lastMove,
                ),
                bottomPlayer != null
                    ? Player(
                        name: bottomPlayer.name,
                        title: bottomPlayer.title,
                        rating: bottomPlayer.rating,
                        clock: Duration(seconds: bottomPlayer.seconds),
                        active: tvEvent.isGameOngoing &&
                            tvEvent.turn == bottomPlayer.side)
                    : const SizedBox.shrink(),
              ],
            );
          },
          loading: () => Board(
            interactableSide: InteractableSide.none,
            size: screenWidth,
            orientation: Side.white,
            fen: kEmptyFen,
          ),
          error: (err, __) {
            debugPrint(
                'SEVERE: [TvScreen] could not load stream; ${err.toString()}');
            return const Text('Could not load TV stream.');
          },
        ),
      ),
    );
  }
}

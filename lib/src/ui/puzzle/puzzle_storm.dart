import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chessground/chessground.dart' as cg;
import 'package:dartchess/dartchess.dart';

import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_providers.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_repository.dart';
import 'package:lichess_mobile/src/model/puzzle/puzzle_storm.dart';
import 'package:lichess_mobile/src/styles/lichess_colors.dart';
import 'package:lichess_mobile/src/styles/lichess_icons.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/widgets/adaptive_dialog.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/utils/chessground_compat.dart';
import "package:lichess_mobile/src/utils/l10n_context.dart";
import 'package:lichess_mobile/src/widgets/list.dart';

import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/ui/settings/toggle_sound_button.dart';
import 'package:lichess_mobile/src/widgets/table_board_layout.dart';

// TODO: Dialog with puzzle end result

class PuzzleStormScreen extends StatelessWidget {
  const PuzzleStormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _androidBuilder,
      iosBuilder: _iosBuilder,
    );
  }

  Widget _androidBuilder(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [ToggleSoundButton()],
        title: const Text('Puzzle Storm'),
      ),
      body: const _Load(),
    );
  }

  Widget _iosBuilder(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Puzzle Storm'),
        trailing: ToggleSoundButton(),
      ),
      child: const _Load(),
    );
  }
}

class _Load extends ConsumerWidget {
  const _Load();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storm = ref.watch(stormProvider);
    return storm.when(
      data: (data) {
        return _Body(data: data);
      },
      loading: () => const CenterLoadingIndicator(),
      error: (e, s) {
        debugPrint(
          'SEVERE: [PuzzleStreakScreen] could not load streak; $e\n$s',
        );
        return Center(
          child: TableBoardLayout(
            topTable: kEmptyWidget,
            bottomTable: kEmptyWidget,
            boardData: const cg.BoardData(
              fen: kEmptyFen,
              interactableSide: cg.InteractableSide.none,
              orientation: cg.Side.white,
            ),
            errorMessage: e.toString(),
          ),
        );
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});
  final PuzzleStormResponse data;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stormCtrlProvier = StormCtrlProvider(data.puzzles);
    final puzzleState = ref.watch(stormCtrlProvier);

    puzzleState.clock.timeStream.listen((e) async {
      if (e.$1.inSeconds == 0 && puzzleState.clock.endAt == null) {
        ref.read(stormCtrlProvier.notifier).end();
        showDialog<void>(
          context: context,
          builder: (context) => _RunStats(ref.watch(stormCtrlProvier).stats!),
        );
      }
    });
    final content = Column(
      children: [
        Expanded(
          child: Center(
            child: SafeArea(
              child: TableBoardLayout(
                boardData: cg.BoardData(
                  onMove: (move, {isPremove}) => ref
                      .read(stormCtrlProvier.notifier)
                      .onUserMove(Move.fromUci(move.uci)!),
                  orientation: puzzleState.pov.cg,
                  interactableSide: puzzleState.clock.endAt != null ||
                          puzzleState.position.isGameOver
                      ? cg.InteractableSide.none
                      : puzzleState.pov == Side.white
                          ? cg.InteractableSide.white
                          : cg.InteractableSide.black,
                  fen: puzzleState.position.fen,
                  isCheck: puzzleState.position.isCheck,
                  lastMove: puzzleState.lastMove?.cg,
                  sideToMove: puzzleState.position.turn.cg,
                  validMoves: puzzleState.validMoves,
                ),
                topTable: _TopBar(
                  pov: ref.read(stormCtrlProvier.select((state) => state.pov)),
                  clock:
                      ref.read(stormCtrlProvier.select((state) => state.clock)),
                ),
                bottomTable: _Combo(stormCtrlProvier),
              ),
            ),
          ),
        ),
        _BottomBar(stormCtrlProvier),
      ],
    );

    return !puzzleState.clock.isActive
        ? content
        : WillPopScope(
            child: content,
            onWillPop: () async {
              final result = await showAdaptiveDialog<bool>(
                context: context,
                builder: (context) => YesNoDialog(
                  title: const Text('Are you sure?'),
                  content: const Text(
                    'Do you want to end this run?',
                  ),
                  onYes: () {
                    ref.read(stormCtrlProvier.notifier).endNow();
                    return Navigator.of(context).pop(true);
                  },
                  onNo: () => Navigator.of(context).pop(false),
                ),
              );
              return result ?? false;
            },
          );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.pov,
    required this.clock,
  });

  final Side pov;
  final StormClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultFontSize = DefaultTextStyle.of(context).style.fontSize;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(LichessIcons.chess_king, size: 36, color: Colors.grey),
          const SizedBox(width: 18),
          DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: defaultFontSize != null ? defaultFontSize * 1.2 : null,
              fontWeight: FontWeight.bold,
            ),
            child: Text(
              pov == Side.white
                  ? context.l10n.puzzleFindTheBestMoveForWhite
                  : context.l10n.puzzleFindTheBestMoveForBlack,
            ),
          ),
          const Spacer(),
          StreamBuilder<(Duration, int?)>(
            stream: clock.timeStream,
            builder: (context, snapshot) {
              final (time, _) = snapshot.data ?? (clock.timeLeft, null);
              final minutes =
                  time.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds =
                  time.inSeconds.remainder(60).toString().padLeft(2, '0');
              return Text(
                '$minutes:$seconds',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: time.inSeconds < 20 ? LichessColors.red : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Combo extends ConsumerWidget {
  const _Combo(this.ctrl);

  final StormCtrlProvider ctrl;

  static const levels = [3, 5, 7, 10];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combo = ref.watch(ctrl.select((state) => state.combo));
    final lvl = combo.level();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: combo.current.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '\nCombo')
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 25,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: LinearProgressIndicator(
                        value: combo.percent() / 100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).indicatorColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: levels.mapIndexed((index, level) {
                      final isCurrentLevel = index < lvl;
                      return Text(
                        '${level}s',
                        style: TextStyle(
                          shadows: isCurrentLevel
                              ? [
                                  Shadow(
                                    color: Theme.of(context).indicatorColor,
                                    blurRadius: 10.0,
                                  )
                                ]
                              : null,
                          color: isCurrentLevel
                              ? Theme.of(context).indicatorColor
                              : Colors.grey,
                          fontWeight: isCurrentLevel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar(this.ctrl);

  final StormCtrlProvider ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleState = ref.watch(ctrl);
    return Container(
      padding: Styles.horizontalBodyPadding,
      color: defaultTargetPlatform == TargetPlatform.iOS
          ? CupertinoTheme.of(context).barBackgroundColor
          : Theme.of(context).bottomAppBarTheme.color,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomBarButton(
              icon: LichessIcons.cancel,
              label: context.l10n.stormNewRun,
              shortLabel: 'New Run',
              highlighted: puzzleState.clock.startAt != null,
              showAndroidShortLabel: true,
              onTap: () => ref.invalidate(stormProvider),
            ),
            BottomBarButton(
              icon: LichessIcons.flag,
              label: context.l10n.stormEndRun,
              highlighted: puzzleState.clock.startAt != null,
              shortLabel: 'End Run',
              showAndroidShortLabel: true,
              onTap: () {
                if (puzzleState.clock.startAt != null) {
                  ref.read(ctrl.notifier).end();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RunStats extends StatelessWidget {
  const _RunStats(this.stats);
  final StormRunStats stats;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListSection(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              header: const Text('Run Result'),
              headerTrailing: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
              children: [
                RowData(
                  '${stats.history.length} Puzzles Solved',
                  null,
                ),
                RowData('Moves:', stats.moves.toString()),
                RowData(
                  'Accuracy:',
                  (stats.errors ~/ stats.moves).toString(),
                ),
                RowData('Combo:', stats.comboBest.toString()),
                RowData('Time:', stats.time.inSeconds.toString()),
                RowData('Highest Solved:', stats.highest.toString()),
              ],
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Handle 'Play Again' button tap
              },
              child: const Text('Play Again'),
            ),
            const SizedBox(height: 16.0),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ListTile(title: Text('Item 1')),
                ListTile(title: Text('Item 2')),
                ListTile(title: Text('Item 3')),
                ListTile(title: Text('Item 4')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
                ListTile(title: Text('Item 5')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RowData extends StatelessWidget {
  final String label;
  final String? value;

  const RowData(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (value != null) Text(value!),
        ],
      ),
    );
  }
}

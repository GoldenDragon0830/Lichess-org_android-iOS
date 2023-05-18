import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lichess_mobile/src/widgets/countdown_clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
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
import 'package:lichess_mobile/src/widgets/board_preview.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/utils/chessground_compat.dart';
import "package:lichess_mobile/src/utils/l10n_context.dart";
import 'package:lichess_mobile/src/widgets/list.dart';

import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/ui/settings/toggle_sound_button.dart';
import 'package:lichess_mobile/src/widgets/table_board_layout.dart';

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

    puzzleState.clock.timeStream.listen((e) {
      if (e.$1 == Duration.zero && puzzleState.clock.endAt == null) {
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
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize:
                    defaultFontSize != null ? defaultFontSize * 1.2 : null,
                fontWeight: FontWeight.bold,
              ),
              child: Text(
                maxLines: 2,
                pov == Side.white
                    ? context.l10n.stormYouPlayTheWhitePiecesInAllPuzzles
                    : context.l10n.stormYouPlayTheBlackPiecesInAllPuzzles,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          StreamBuilder<(Duration, int?)>(
            stream: clock.timeStream,
            builder: (context, snapshot) {
              final (time, bonus) = snapshot.data ?? (clock.timeLeft, null);
              final minutes =
                  time.inMinutes.remainder(60).toString().padLeft(2, '0');
              final seconds =
                  time.inSeconds.remainder(60).toString().padLeft(2, '0');
              return StormClockWidget(
                minutes: minutes,
                seconds: seconds,
                bonus: bonus,
                time: time,
                isActive: clock.isActive,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Combo extends ConsumerStatefulWidget {
  const _Combo(this.ctrl);

  final StormCtrlProvider ctrl;

  @override
  ConsumerState<_Combo> createState() => _ComboState();
}

class _ComboState extends ConsumerState<_Combo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StormCombo combo = StormCombo();

  static const levels = [3, 5, 7, 10];
  @override
  void initState() {
    super.initState();
    combo = ref.read(widget.ctrl.select((value) => value.combo));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: combo.percent() / 100,
    );
  }

  @override
  void didUpdateWidget(covariant _Combo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ctrl != widget.ctrl) {
      combo = StormCombo();
    }
    final newVal = combo.percent() / 100;
    if (_controller.value != newVal) {
      // next lvl reached
      if (_controller.value > newVal && combo.current != 0) {
        _controller.animateTo(1.0, curve: Curves.easeInOut).then(
              (value) => _controller.value = 0,
            );
        return;
      }
      _controller.animateTo(newVal, curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lvl = combo.level();
    final indicatorColor = defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoTheme.of(context).primaryColor
        : Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Padding(
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: defaultTargetPlatform == TargetPlatform.iOS
                          ? CupertinoTheme.of(context).textTheme.textStyle.color
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  TextSpan(
                    text: '\nCombo',
                    style: TextStyle(
                      color: defaultTargetPlatform == TargetPlatform.iOS
                          ? CupertinoTheme.of(context).textTheme.textStyle.color
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  )
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
                        backgroundColor:
                            defaultTargetPlatform == TargetPlatform.iOS
                                ? CupertinoTheme.of(context).barBackgroundColor
                                : null,
                        value: _controller.value,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(indicatorColor),
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
                                    color: indicatorColor,
                                    blurRadius: 13.0,
                                  )
                                ]
                              : null,
                          color: isCurrentLevel ? indicatorColor : Colors.grey,
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
                  puzzleState.clock.sendEnd();
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
    return defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoPopupSurface(
            child: CupertinoPageScaffold(child: _DialogBody(stats)),
          )
        : Dialog(
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.background,
                width: 4.0,
                strokeAlign: 0.6,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            ),
            child: Scaffold(body: _DialogBody(stats)),
          );
  }
}

class _DialogBody extends ConsumerWidget {
  const _DialogBody(this.stats);

  final StormRunStats stats;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListSection(
            header: Text(context.l10n.stormRaceComplete),
            headerTrailing: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
            children: [
              _RowData(
                '${stats.history.length} ${context.l10n.stormPuzzlesSolved}',
                null,
              ),
              _RowData(context.l10n.stormRuns, stats.moves.toString()),
              _RowData(
                context.l10n.accuracy,
                '${(((stats.moves - stats.errors) / stats.moves) * 100).toStringAsFixed(2)}%',
              ),
              _RowData(context.l10n.stormCombo, stats.comboBest.toString()),
              _RowData(context.l10n.stormTime, '${stats.time.inSeconds}s'),
              _RowData(
                context.l10n.stormHighestSolved,
                stats.highest.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          FatButton(
            semanticsLabel: "Play Again",
            onPressed: () {
              ref.invalidate(stormProvider);
              Navigator.of(context).pop();
            },
            child: Text(context.l10n.stormPlayAgain),
          ),
          ListSection(
            header: Text(context.l10n.stormPuzzlesPlayed),
            children: [
              LayoutBuilder(
                builder: (context, constrains) {
                  final boardWidth = constrains.maxWidth / 2;
                  final footerHeight = calculateFooterHeight(context);
                  return LayoutGrid(
                    columnSizes: List.generate(2, (_) => 1.fr),
                    rowSizes: List.generate(
                      (stats.history.length / 2).ceil(),
                      (_) => auto,
                    ),
                    children: stats.history.map((e) {
                      final (side, fen, lastMove) = e.$1.preview();
                      return SizedBox(
                        width: boardWidth,
                        height: boardWidth + footerHeight,
                        child: BoardPreview(
                          orientation: side.cg,
                          fen: fen,
                          lastMove: lastMove.cg,
                          footer: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                ColoredBox(
                                  color: e.$2
                                      ? LichessColors.good
                                      : LichessColors.red,
                                  child: Row(
                                    children: [
                                      if (e.$2)
                                        const Icon(
                                          color: Colors.white,
                                          Icons.done,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      Text(
                                        '${e.$3.inSeconds}s',
                                        overflow: TextOverflow.fade,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(e.$1.rating.toString()),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  double calculateFooterHeight(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: Theme.of(context).textTheme.bodySmall?.fontSize ?? 14.0,
    ); // Adjust the font size as needed
    final timeTextPainter = TextPainter(
      text: TextSpan(text: "100s", style: textStyle),
      textDirection: TextDirection.ltr,
    );
    timeTextPainter.layout();

    // Calculate the total height needed for the footer content
    return (timeTextPainter.height) * MediaQuery.of(context).textScaleFactor +
        17.0;
  }
}

class _RowData extends StatelessWidget {
  final String label;
  final String? value;

  const _RowData(this.label, this.value);

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

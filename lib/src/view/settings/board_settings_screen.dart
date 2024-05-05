import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/settings/board_preferences.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/settings.dart';

class BoardSettingsScreen extends StatelessWidget {
  const BoardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _androidBuilder,
      iosBuilder: _iosBuilder,
    );
  }

  Widget _androidBuilder(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.preferencesGameBehavior)),
      body: const _Body(),
    );
  }

  Widget _iosBuilder(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(),
      child: _Body(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardPrefs = ref.watch(boardPreferencesProvider);

    return SafeArea(
      child: ListView(
        children: [
          ListSection(
            hasLeading: false,
            showDivider: false,
            children: [
              SwitchSettingTile(
                title: const Text('Haptic feedback'),
                value: boardPrefs.hapticFeedback,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .toggleHapticFeedback();
                },
              ),
              SwitchSettingTile(
                title: Text(
                  context.l10n.preferencesPieceDestinations,
                ),
                value: boardPrefs.showLegalMoves,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .toggleShowLegalMoves();
                },
              ),
              SwitchSettingTile(
                title: Text(
                  context.l10n.preferencesBoardHighlights,
                ),
                value: boardPrefs.boardHighlights,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .toggleBoardHighlights();
                },
              ),
              SwitchSettingTile(
                title: Text(
                  context.l10n.preferencesBoardCoordinates,
                ),
                value: boardPrefs.coordinates,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .toggleCoordinates();
                },
              ),
              SwitchSettingTile(
                title: Text(
                  context.l10n.preferencesPieceAnimation,
                ),
                value: boardPrefs.pieceAnimation,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .togglePieceAnimation();
                },
              ),
              SwitchSettingTile(
                title: Text(
                  context.l10n.preferencesMaterialDifference,
                ),
                value: boardPrefs.showMaterialDifference,
                onChanged: (value) {
                  ref
                      .read(boardPreferencesProvider.notifier)
                      .toggleShowMaterialDifference();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

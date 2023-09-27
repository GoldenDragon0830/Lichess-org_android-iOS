import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/settings.dart';
import 'package:lichess_mobile/src/widgets/adaptive_choice_picker.dart';
import 'package:lichess_mobile/src/model/account/account_preferences.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';

class GameBehaviorSettingsScreen extends StatelessWidget {
  const GameBehaviorSettingsScreen({super.key});

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
    final accountPrefs = ref.watch(accountPreferencesProvider);

    return accountPrefs.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('You must be logged in to view this page.'),
          );
        }
        return SafeArea(
          child: ListView(
            children: [
              ListSection(
                hasLeading: false,
                children: [
                  SwitchSettingTile(
                    title: Text(
                      context.l10n.preferencesPremovesPlayingDuringOpponentTurn,
                      maxLines: 2,
                    ),
                    value: data.premove.value,
                    onChanged: (value) {
                      ref
                          .read(accountPreferencesProvider.notifier)
                          .setPremove(BooleanPref(value));
                    },
                  ),
                  SwitchSettingTile(
                    title: Text(
                      context.l10n.preferencesConfirmResignationAndDrawOffers,
                      maxLines: 2,
                    ),
                    value: data.confirmResign.value,
                    onChanged: (value) {
                      ref
                          .read(accountPreferencesProvider.notifier)
                          .setConfirmResign(BooleanPref(value));
                    },
                  ),
                  SettingsListTile(
                    settingsLabel: Text(
                      context.l10n.preferencesTakebacksWithOpponentApproval,
                      maxLines: 2,
                    ),
                    settingsValue: data.takeback.label(context),
                    showCupertinoTrailingValue: false,
                    onTap: () {
                      if (defaultTargetPlatform == TargetPlatform.android) {
                        showChoicePicker(
                          context,
                          choices: Takeback.values,
                          selectedItem: data.takeback,
                          labelBuilder: (t) => Text(t.label(context)),
                          onSelectedItemChanged: (Takeback? value) {
                            ref
                                .read(accountPreferencesProvider.notifier)
                                .setTakeback(value ?? data.takeback);
                          },
                        );
                      } else {
                        pushPlatformRoute(
                          context,
                          title: context
                              .l10n.preferencesTakebacksWithOpponentApproval,
                          builder: (context) => const TakebackSettingsScreen(),
                        );
                      }
                    },
                  ),
                  SettingsListTile(
                    settingsLabel: Text(
                      context.l10n.preferencesPromoteToQueenAutomatically,
                      maxLines: 2,
                    ),
                    settingsValue: data.autoQueen.label(context),
                    showCupertinoTrailingValue: false,
                    onTap: () {
                      if (defaultTargetPlatform == TargetPlatform.android) {
                        showChoicePicker(
                          context,
                          choices: AutoQueen.values,
                          selectedItem: data.autoQueen,
                          labelBuilder: (t) => Text(t.label(context)),
                          onSelectedItemChanged: (AutoQueen? value) {
                            ref
                                .read(accountPreferencesProvider.notifier)
                                .setAutoQueen(value ?? data.autoQueen);
                          },
                        );
                      } else {
                        pushPlatformRoute(
                          context,
                          title: context
                              .l10n.preferencesPromoteToQueenAutomatically,
                          builder: (context) => const AutoQueenSettingsScreen(),
                        );
                      }
                    },
                  ),
                  SettingsListTile(
                    settingsLabel: Text(
                      context.l10n
                          .preferencesClaimDrawOnThreefoldRepetitionAutomatically,
                      maxLines: 2,
                    ),
                    settingsValue: data.autoThreefold.label(context),
                    showCupertinoTrailingValue: false,
                    onTap: () {
                      if (defaultTargetPlatform == TargetPlatform.android) {
                        showChoicePicker(
                          context,
                          choices: AutoThreefold.values,
                          selectedItem: data.autoThreefold,
                          labelBuilder: (t) => Text(t.label(context)),
                          onSelectedItemChanged: (AutoThreefold? value) {
                            ref
                                .read(accountPreferencesProvider.notifier)
                                .setAutoThreefold(value ?? data.autoThreefold);
                          },
                        );
                      } else {
                        pushPlatformRoute(
                          context,
                          title: context.l10n
                              .preferencesClaimDrawOnThreefoldRepetitionAutomatically,
                          builder: (context) =>
                              const AutoThreefoldSettingsScreen(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(err.toString())),
    );
  }
}

class TakebackSettingsScreen extends ConsumerWidget {
  const TakebackSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPrefs = ref.watch(accountPreferencesProvider);
    return accountPrefs.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('You must be logged in to view this page.'),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: ListView(
              children: [
                ChoicePicker(
                  choices: Takeback.values,
                  selectedItem: data.takeback,
                  titleBuilder: (t) => Text(t.label(context)),
                  onSelectedItemChanged: (Takeback? v) {
                    ref
                        .read(accountPreferencesProvider.notifier)
                        .setTakeback(v ?? data.takeback);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(err.toString())),
    );
  }
}

class AutoQueenSettingsScreen extends ConsumerWidget {
  const AutoQueenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPrefs = ref.watch(accountPreferencesProvider);
    return accountPrefs.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('You must be logged in to view this page.'),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: ListView(
              children: [
                ChoicePicker(
                  choices: AutoQueen.values,
                  selectedItem: data.autoQueen,
                  titleBuilder: (t) => Text(t.label(context)),
                  onSelectedItemChanged: (AutoQueen? v) {
                    ref
                        .read(accountPreferencesProvider.notifier)
                        .setAutoQueen(v ?? data.autoQueen);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(err.toString())),
    );
  }
}

class AutoThreefoldSettingsScreen extends ConsumerWidget {
  const AutoThreefoldSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPrefs = ref.watch(accountPreferencesProvider);
    return accountPrefs.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('You must be logged in to view this page.'),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: ListView(
              children: [
                ChoicePicker(
                  choices: AutoThreefold.values,
                  selectedItem: data.autoThreefold,
                  titleBuilder: (t) => Text(t.label(context)),
                  onSelectedItemChanged: (AutoThreefold? v) {
                    ref
                        .read(accountPreferencesProvider.notifier)
                        .setAutoThreefold(v ?? data.autoThreefold);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(err.toString())),
    );
  }
}

class MoretimeSettingsScreen extends ConsumerWidget {
  const MoretimeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountPrefs = ref.watch(accountPreferencesProvider);
    return accountPrefs.when(
      data: (data) {
        if (data == null) {
          return const Center(
            child: Text('You must be logged in to view this page.'),
          );
        }

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(),
          child: SafeArea(
            child: ListView(
              children: [
                ChoicePicker(
                  choices: Moretime.values,
                  selectedItem: data.moretime,
                  titleBuilder: (t) => Text(t.label(context)),
                  onSelectedItemChanged: (Moretime? v) {
                    ref
                        .read(accountPreferencesProvider.notifier)
                        .setMoretime(v ?? data.moretime);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text(err.toString())),
    );
  }
}

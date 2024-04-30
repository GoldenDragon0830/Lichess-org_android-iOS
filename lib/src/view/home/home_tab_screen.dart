import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart'
    hide CupertinoPageScaffold, CupertinoSliverNavigationBar;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lichess_mobile/src/model/account/account_repository.dart';
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/correspondence/correspondence_game_storage.dart';
import 'package:lichess_mobile/src/navigation.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/connectivity.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/utils/layout.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/view/account/profile_screen.dart';
import 'package:lichess_mobile/src/view/home/create_a_game_screen.dart';
import 'package:lichess_mobile/src/view/home/create_game_options.dart';
import 'package:lichess_mobile/src/view/home/quick_game_button.dart';
import 'package:lichess_mobile/src/view/play/offline_correspondence_games_screen.dart';
import 'package:lichess_mobile/src/view/play/ongoing_games_screen.dart';
import 'package:lichess_mobile/src/view/settings/settings_button.dart';
import 'package:lichess_mobile/src/view/user/player_screen.dart';
import 'package:lichess_mobile/src/view/user/recent_games.dart';
import 'package:lichess_mobile/src/widgets/buttons.dart';
import 'package:lichess_mobile/src/widgets/cupertino.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/user_full_name.dart';

class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeTabScreen> {
  final _androidRefreshKey = GlobalKey<RefreshIndicatorState>();

  bool wasOnline = true;
  bool hasRefreshed = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(connectivityChangesProvider, (_, connectivity) {
      // Refresh the data only once if it was offline and is now online
      if (!connectivity.isRefreshing && connectivity.hasValue) {
        final isNowOnline = connectivity.value!.isOnline;

        if (!hasRefreshed && !wasOnline && isNowOnline) {
          hasRefreshed = true;
          _refreshData();
        }

        wasOnline = isNowOnline;
      }
    });

    return PlatformWidget(
      androidBuilder: _androidBuilder,
      iosBuilder: _iosBuilder,
    );
  }

  Widget _androidBuilder(BuildContext context) {
    final isLoggedIn = ref.watch(authSessionProvider) != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('lichess.org'),
        leading: isLoggedIn ? const _ProfileButton() : null,
        actions: const [
          SettingsButton(),
          _PlayerScreenButton(),
        ],
      ),
      body: RefreshIndicator(
        key: _androidRefreshKey,
        onRefresh: () => _refreshData(),
        child: const Column(
          children: [
            ConnectivityBanner(),
            Expanded(child: _HomeBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          pushPlatformRoute(
            context,
            builder: (_) => const CreateAGameScreen(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.createAGame),
      ),
    );
  }

  Widget _iosBuilder(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            controller: homeScrollController,
            slivers: [
              CupertinoSliverNavigationBar(
                padding: const EdgeInsetsDirectional.only(
                  start: 16.0,
                  end: 8.0,
                ),
                leading: session == null ? null : const _ProfileButton(),
                largeTitle: Text(context.l10n.play),
                trailing: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsButton(),
                    _PlayerScreenButton(),
                  ],
                ),
              ),
              CupertinoSliverRefreshControl(
                onRefresh: () => _refreshData(),
              ),
              const SliverToBoxAdapter(child: ConnectivityBanner()),
              const _HomeBody(),
            ],
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 4.0,
                      blurRadius: 16.0,
                    ),
                  ],
                ),
                child: FatButton(
                  semanticsLabel: context.l10n.createAGame,
                  onPressed: () {
                    pushPlatformRoute(
                      context,
                      builder: (_) => const CreateAGameScreen(),
                    );
                  },
                  child: Text(
                    context.l10n.createAGame,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() {
    return Future.wait([
      ref.refresh(accountRecentGamesProvider.future),
      ref.refresh(ongoingGamesProvider.future),
    ]);
  }
}

class _ProfileButton extends ConsumerWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onPressed() {
      ref.invalidate(accountProvider);
      ref.invalidate(accountActivityProvider);
      pushPlatformRoute(
        context,
        title: context.l10n.profile,
        builder: (_) => const ProfileScreen(),
      );
    }

    return PlatformWidget(
      androidBuilder: (context) => IconButton(
        icon: const Icon(Icons.account_circle),
        tooltip: context.l10n.profile,
        onPressed: onPressed,
      ),
      iosBuilder: (context) => AppBarTextButton(
        onPressed: onPressed,
        child: Text(context.l10n.profile),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityChangesProvider);
    return connectivity.when(
      data: (data) {
        final isTablet = getScreenType(context) == ScreenType.tablet;
        if (data.isOnline) {
          final onlineWidgets = _onlineWidgets(context, isTablet);

          return Theme.of(context).platform == TargetPlatform.android
              ? ListView(
                  controller: homeScrollController,
                  children: onlineWidgets,
                )
              : SliverList(
                  delegate: SliverChildListDelegate(onlineWidgets),
                );
        } else {
          final offlineWidgets = _offlineWidgets(isTablet);
          return Theme.of(context).platform == TargetPlatform.android
              ? ListView(
                  controller: homeScrollController,
                  children: offlineWidgets,
                )
              : SliverList(
                  delegate: SliverChildListDelegate.fixed(offlineWidgets),
                );
        }
      },
      loading: () {
        const child = CenterLoadingIndicator();
        return Theme.of(context).platform == TargetPlatform.android
            ? child
            : const SliverFillRemaining(child: child);
      },
      error: (error, stack) {
        const child = SizedBox.shrink();
        return Theme.of(context).platform == TargetPlatform.android
            ? child
            : const SliverFillRemaining(child: child);
      },
    );
  }

  List<Widget> _onlineWidgets(BuildContext context, bool isTablet) {
    if (isTablet) {
      return [
        const _HelloWidget(),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 8.0),
                  _CreateAGameSection(),
                  _OngoingGamesPreview(maxGamesToShow: 5),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0),
                  RecentGames(),
                ],
              ),
            ),
          ],
        ),
      ];
    } else {
      return [
        const _HelloWidget(),
        // const _CreateAGameSection(),
        const _OngoingGamesPreview(maxGamesToShow: 5),
        const SafeArea(top: false, child: RecentGames()),
        const SizedBox(height: 54.0),
      ];
    }
  }

  List<Widget> _offlineWidgets(bool isTablet) {
    if (isTablet) {
      return const [
        _HelloWidget(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: 8.0),
                  _OfflineCorrespondencePreview(maxGamesToShow: 5),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 8.0),
                ],
              ),
            ),
          ],
        ),
      ];
    } else {
      return const [
        SizedBox(height: 8.0),
        _HelloWidget(),
        _OfflineCorrespondencePreview(maxGamesToShow: 5),
      ];
    }
  }
}

class _HelloWidget extends ConsumerWidget {
  const _HelloWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    const style = TextStyle(fontSize: 22);

    // fetch the account user to be sure we have the latest data (flair, etc.)
    final accountUser = ref.watch(accountProvider).maybeWhen(
          data: (data) => data?.lightUser,
          orElse: () => null,
        );

    return session != null
        ? Padding(
            padding: Styles.bodyPadding,
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  size: 28,
                  color: context.lichessColors.brag,
                ),
                const SizedBox(width: 5.0),
                const Text(
                  'Hello, ',
                  style: style,
                ),
                UserFullNameWidget(
                  user: accountUser ?? session.user,
                  style: style,
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}

class _CreateAGameSection extends StatelessWidget {
  const _CreateAGameSection();

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Styles.horizontalBodyPadding,
            child: Text(context.l10n.createAGame, style: Styles.sectionTitle),
          ),
          const QuickGameButton(),
          const CreateGameOptions(),
        ],
      ),
    );
  }
}

class _OngoingGamesPreview extends ConsumerWidget {
  const _OngoingGamesPreview({required this.maxGamesToShow});

  final int maxGamesToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongoingGames = ref.watch(ongoingGamesProvider);
    return ongoingGames.maybeWhen(
      data: (data) {
        return _GamePreview(
          list: data,
          maxGamesToShow: maxGamesToShow,
          builder: (el) => OngoingGamePreview(game: el),
          moreScreenBuilder: (_) => const OngoingGamesScreen(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _OfflineCorrespondencePreview extends ConsumerWidget {
  const _OfflineCorrespondencePreview({required this.maxGamesToShow});

  final int maxGamesToShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineCorresGames =
        ref.watch(offlineOngoingCorrespondenceGamesProvider);
    return offlineCorresGames.maybeWhen(
      data: (data) {
        return _GamePreview(
          list: data,
          maxGamesToShow: maxGamesToShow,
          builder: (el) => OfflineCorrespondenceGamePreview(
            game: el.$2,
            lastModified: el.$1,
          ),
          moreScreenBuilder: (_) => const OfflineCorrespondenceGamesScreen(),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _GamePreview<T> extends StatelessWidget {
  const _GamePreview({
    required this.list,
    required this.builder,
    required this.moreScreenBuilder,
    required this.maxGamesToShow,
  });
  final IList<T> list;
  final Widget Function(T data) builder;
  final Widget Function(BuildContext) moreScreenBuilder;
  final int maxGamesToShow;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: Styles.horizontalBodyPadding.add(
            const EdgeInsets.only(top: 16.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context.l10n.nbGamesInPlay(list.length),
                  style: Styles.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (list.length > maxGamesToShow) ...[
                const SizedBox(width: 6.0),
                NoPaddingTextButton(
                  onPressed: () {
                    pushPlatformRoute(
                      context,
                      title: context.l10n.nbGamesInPlay(list.length),
                      builder: moreScreenBuilder,
                    );
                  },
                  child: Text(context.l10n.more),
                ),
              ],
            ],
          ),
        ),
        for (final data in list.take(maxGamesToShow)) builder(data),
      ],
    );
  }
}

class _PlayerScreenButton extends ConsumerWidget {
  const _PlayerScreenButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBarIconButton(
      icon: const Icon(Icons.group),
      semanticsLabel: context.l10n.players,
      onPressed: () {
        pushPlatformRoute(
          context,
          title: context.l10n.players,
          builder: (_) => const PlayerScreen(),
        );
      },
    );
  }
}

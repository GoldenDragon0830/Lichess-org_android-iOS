import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:lichess_mobile/src/model/auth/auth_session.dart';
import 'package:lichess_mobile/src/model/common/http.dart';
import 'package:lichess_mobile/src/model/relation/relation_repository.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:lichess_mobile/src/model/user/user_repository_providers.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/utils/navigation.dart';
import 'package:lichess_mobile/src/view/play/challenge_screen.dart';
import 'package:lichess_mobile/src/view/user/recent_games.dart';
import 'package:lichess_mobile/src/widgets/feedback.dart';
import 'package:lichess_mobile/src/widgets/list.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/widgets/user_full_name.dart';
import 'package:url_launcher/url_launcher.dart';

import 'perf_cards.dart';
import 'user_activity.dart';
import 'user_profile.dart';

class UserScreen extends ConsumerStatefulWidget {
  const UserScreen({required this.user, super.key});

  final LightUser user;

  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ConsumerPlatformWidget(
      ref: ref,
      androidBuilder: _buildAndroid,
      iosBuilder: _buildIos,
    );
  }

  void setIsLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Widget _buildAndroid(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userAndStatusProvider(id: widget.user.id));
    final updatedLightUser = asyncUser.maybeWhen(
      data: (data) => data.$1.lightUser.copyWith(isOnline: data.$2.online),
      orElse: () => null,
    );
    return Scaffold(
      appBar: AppBar(
        title: UserFullNameWidget(
          user: updatedLightUser ?? widget.user,
          shouldShowOnline: updatedLightUser != null,
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                height: 24,
                width: 24,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
      body: asyncUser.when(
        data: (data) => _UserProfileListView(data.$1, isLoading, setIsLoading),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is ClientException && error.message.contains('404')) {
            return Center(
              child: Text(
                textAlign: TextAlign.center,
                context.l10n.usernameNotFound(widget.user.name),
                style: Styles.bold,
              ),
            );
          }
          return FullScreenRetryRequest(
            onRetry: () => ref.invalidate(userProvider(id: widget.user.id)),
          );
        },
      ),
    );
  }

  Widget _buildIos(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userAndStatusProvider(id: widget.user.id));
    final updatedLightUser = asyncUser.maybeWhen(
      data: (data) => data.$1.lightUser.copyWith(isOnline: data.$2.online),
      orElse: () => null,
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: UserFullNameWidget(
          user: updatedLightUser ?? widget.user,
          shouldShowOnline: updatedLightUser != null,
        ),
        trailing: isLoading ? const CircularProgressIndicator.adaptive() : null,
      ),
      child: asyncUser.when(
        data: (data) => SafeArea(
          child: _UserProfileListView(data.$1, isLoading, setIsLoading),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) {
          if (error is ClientException && error.message.contains('404')) {
            return Center(
              child: Text(
                textAlign: TextAlign.center,
                context.l10n.usernameNotFound(widget.user.name),
                style: Styles.bold,
              ),
            );
          }
          return FullScreenRetryRequest(
            onRetry: () => ref.invalidate(userProvider(id: widget.user.id)),
          );
        },
      ),
    );
  }
}

class _UserProfileListView extends ConsumerWidget {
  const _UserProfileListView(this.user, this.isLoading, this.setIsLoading);
  final User user;
  final bool isLoading;

  final void Function(bool value) setIsLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    if (user.disabled == true) {
      return Center(
        child: Text(
          context.l10n.settingsThisAccountIsClosed,
          style: Styles.bold,
        ),
      );
    }

    Future<void> userAction(
      Future<void> Function(LichessClient client) action,
    ) async {
      setIsLoading(true);
      try {
        await ref.withClient(action).then(
              (_) => ref.invalidate(userAndStatusProvider(id: user.id)),
            );
      } finally {
        setIsLoading(false);
      }
    }

    return ListView(
      children: [
        UserProfileWidget(user: user),
        PerfCards(user: user, isMe: false),
        if (session != null)
          ListSection(
            hasLeading: true,
            children: [
              PlatformListTile(
                title: Text(context.l10n.challengeChallengeToPlay),
                leading: const Icon(Icons.play_arrow),
                onTap: () {
                  pushPlatformRoute(
                    context,
                    builder: (context) => ChallengeScreen(user.lightUser),
                  );
                },
              ),
              if (user.followable == true && user.following != true)
                PlatformListTile(
                  leading: const Icon(Icons.person_add),
                  title: Text(context.l10n.follow),
                  onTap: isLoading
                      ? null
                      : () => userAction(
                            (client) =>
                                RelationRepository(client).follow(user.id),
                          ),
                )
              else if (user.following == true)
                PlatformListTile(
                  leading: const Icon(Icons.person_remove),
                  title: Text(context.l10n.unfollow),
                  onTap: isLoading
                      ? null
                      : () => userAction(
                            (client) =>
                                RelationRepository(client).unfollow(user.id),
                          ),
                ),
              if (user.following != true && user.blocking != true)
                PlatformListTile(
                  leading: const Icon(Icons.block),
                  title: Text(context.l10n.block),
                  onTap: isLoading
                      ? null
                      : () => userAction(
                            (client) =>
                                RelationRepository(client).block(user.id),
                          ),
                )
              else if (user.blocking == true)
                PlatformListTile(
                  leading: const Icon(Icons.block),
                  title: Text(context.l10n.unblock),
                  onTap: isLoading
                      ? null
                      : () => userAction(
                            (client) =>
                                RelationRepository(client).unblock(user.id),
                          ),
                ),
              PlatformListTile(
                leading: const Icon(Icons.report_problem),
                title: Text(context.l10n.reportXToModerators(user.username)),
                onTap: () {
                  launchUrl(
                    lichessUri('/report', {'username': user.id}),
                  );
                },
              ),
            ],
          ),
        UserActivityWidget(user: user),
        RecentGamesWidget(user: user.lightUser),
      ],
    );
  }
}

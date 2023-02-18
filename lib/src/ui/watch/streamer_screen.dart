import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:lichess_mobile/src/model/tv/streamer.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';
import 'package:lichess_mobile/src/common/lichess_colors.dart';
import 'package:lichess_mobile/src/common/social_icons.dart';
import 'package:lichess_mobile/src/widgets/list.dart';

class StreamerScreen extends StatelessWidget {
  const StreamerScreen({required this.streamers});

  final IList<Streamer> streamers;

  @override
  Widget build(BuildContext build) {
    return PlatformWidget(androidBuilder: _buildAndroid, iosBuilder: _buildIos);
  }

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streamers'),
      ),
      body: ListView(
        children: [
          ListSection(
            showDividerBetweenTiles: true,
            children: streamers
                .map(
                  (e) => StreamerListTile(
                    streamer: e,
                    showSubtitle: true,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildIos(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Lichess TV',
        middle: Text('Live Streamers'),
      ),
      child: CustomScrollView(
        slivers: [
          SliverSafeArea(
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ListSection(
                  children: streamers
                      .map(
                        (e) => StreamerListTile(
                          streamer: e,
                          showSubtitle: true,
                        ),
                      )
                      .toList(),
                )
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamerListTile extends StatelessWidget {
  const StreamerListTile({required this.streamer, this.showSubtitle = false});

  final Streamer streamer;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return PlatformListTile(
      onTap: () async {
        final url = streamer.streamService == 'twitch'
            ? streamer.twitch
            : streamer.youTube;
        if (!await launchUrl(
          Uri.parse(url!),
          mode: LaunchMode.externalApplication,
        )) {
          debugPrint('ERROR: [StreamerWidget] Could not launch $url');
        }
      },
      leading: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Image.network(streamer.image),
      ),
      title: Padding(
        padding: const EdgeInsets.only(right: 5.0),
        child: Row(
          children: [
            if (streamer.title != null) ...[
              Text(
                streamer.title!,
                style: const TextStyle(
                  color: LichessColors.brag,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5)
            ],
            Flexible(
              child: Text(streamer.username, overflow: TextOverflow.ellipsis),
            )
          ],
        ),
      ),
      subtitle: showSubtitle == true ? Text(streamer.streamerHeadline) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (streamer.streamService == 'twitch') ...{
            const Icon(SocialIcons.twitch)
          } else ...{
            const Icon(SocialIcons.youtube)
          },
          if (streamer.lang.isNotEmpty) Text(streamer.lang),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lichess_mobile/src/model/broadcast/broadcast.dart';
import 'package:lichess_mobile/src/styles/styles.dart';
import 'package:lichess_mobile/src/utils/l10n_context.dart';
import 'package:lichess_mobile/src/widgets/platform.dart';

class DescriptionScreen extends StatelessWidget {
  final Broadcast broadcast;

  const DescriptionScreen({super.key, required this.broadcast});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _androidBuilder,
      iosBuilder: _iosBuilder,
    );
  }

  Widget _androidBuilder(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.broadcastBroadcasts),
      ),
      body: _Body(broadcast: broadcast),
    );
  }

  Widget _iosBuilder(
    BuildContext context,
  ) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(context.l10n.broadcastBroadcasts),
      ),
      child: _Body(
        broadcast: broadcast,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Broadcast broadcast;
  const _Body({required this.broadcast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Text(
            broadcast.tour.name,
            style: Styles.title,
          ),
          const SizedBox(height: 10),
          Text(
            broadcast.tour.description,
            style: Styles.subtitle,
          ),
          const SizedBox(height: 10),
          Text(
            '${context.l10n.broadcastStartDate}: ${broadcast.rounds.first.startsAt}',
            style: Styles.subtitle,
          ),
        ],
      ),
    );
  }
}

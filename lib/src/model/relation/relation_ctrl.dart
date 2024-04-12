import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/common/socket.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relation_ctrl.freezed.dart';
part 'relation_ctrl.g.dart';

@riverpod
class RelationCtrl extends _$RelationCtrl {
  StreamSubscription<SocketEvent>? _socketSubscription;
  StreamSubscription<void>? _socketOpenSubscription;

  late SocketClient _socketClient;

  @override
  Future<RelationCtrlState> build() async {
    _socketClient = _socketPool.open(Uri(path: kDefaultSocketRoute));

    final state = _socketClient.stream
        .firstWhere((e) => e.topic == 'following_onlines')
        .then(
          (event) => RelationCtrlState(
            followingOnlines: _parseFriendsList(event.data as List<dynamic>),
          ),
        );

    await _socketClient.firstConnection;

    // Request the list of online friends once the socket is connected.
    _socketClient.send('following_onlines', null);

    // Start watching for online friends.
    _socketSubscription = _socketClient.stream.listen(_handleSocketTopic);

    _socketOpenSubscription?.cancel();
    // Request again the list of online friends every time the socket is reconnected.
    _socketOpenSubscription = _socketClient.connectedStream.listen((_) {
      _socketClient.send('following_onlines', null);
    });

    ref.onDispose(() {
      _socketSubscription?.cancel();
      _socketOpenSubscription?.cancel();
    });

    return state;
  }

  void startWatchingFriends() {
    _socketSubscription?.cancel();
    _socketSubscription = _socketClient.stream.listen(_handleSocketTopic);
    _socketOpenSubscription?.cancel();
    _socketOpenSubscription = _socketClient.connectedStream.listen((_) {
      _socketClient.send('following_onlines', null);
    });
    if (!_socketClient.isActive) {
      _socketClient.connect();
    }
  }

  void stopWatchingFriends() {
    _socketSubscription?.cancel();
    _socketOpenSubscription?.cancel();
  }

  void _handleSocketTopic(SocketEvent event) {
    if (!state.hasValue) return;

    switch (event.topic) {
      case 'following_onlines':
        state = AsyncValue.data(
          RelationCtrlState(
            followingOnlines: _parseFriendsList(event.data as List<dynamic>),
          ),
        );

      case 'following_enters':
        final data = _parseFriend(event.data.toString());
        state = AsyncValue.data(
          state.requireValue.copyWith(
            followingOnlines: state.requireValue.followingOnlines.add(data),
          ),
        );

      case 'following_leaves':
        final data = _parseFriend(event.data.toString());
        state = AsyncValue.data(
          state.requireValue.copyWith(
            followingOnlines: state.requireValue.followingOnlines
                .removeWhere((v) => v.id == data.id),
          ),
        );
    }
  }

  SocketPool get _socketPool => ref.read(socketPoolProvider);

  LightUser _parseFriend(String friend) {
    final splitted = friend.split(' ');
    final name = splitted.length > 1 ? splitted[1] : splitted[0];
    final title = splitted.length > 1 ? splitted[0] : null;
    return LightUser(
      id: UserId.fromUserName(name),
      name: name,
      title: title,
    );
  }

  IList<LightUser> _parseFriendsList(List<dynamic> friends) {
    return friends.map((v) => _parseFriend(v.toString())).toIList();
  }
}

@freezed
class RelationCtrlState with _$RelationCtrlState {
  const RelationCtrlState._();

  const factory RelationCtrlState({
    required IList<LightUser> followingOnlines,
  }) = _RelationCtrlState;
}

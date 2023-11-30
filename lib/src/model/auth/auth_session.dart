import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lichess_mobile/src/app_dependencies.dart';
import 'package:lichess_mobile/src/model/user/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'session_storage.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

@Riverpod(keepAlive: true)
class AuthSession extends _$AuthSession {
  @override
  AuthSessionState? build() {
    // requireValue is possible because appDependenciesProvider is loaded before
    // anything. See: lib/src/app.dart
    return ref.watch(
      appDependenciesProvider.select((data) => data.requireValue.userSession),
    );
  }

  Future<void> update(AuthSessionState session) async {
    final sessionStorage = ref.read(sessionStorageProvider);
    await sessionStorage.write(session);
    state = session;
  }

  Future<void> delete() async {
    final sessionStorage = ref.read(sessionStorageProvider);
    await sessionStorage.delete();
    state = null;
  }
}

@Freezed(fromJson: true, toJson: true)
class AuthSessionState with _$AuthSessionState {
  const factory AuthSessionState({
    required LightUser user,
    required String token,
  }) = _AuthSessionState;

  factory AuthSessionState.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionStateFromJson(json);
}

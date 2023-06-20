import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:soundpool/soundpool.dart';
import 'package:path/path.dart' as p;
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/constants.dart';
import 'package:lichess_mobile/src/http_client.dart';
import 'package:lichess_mobile/src/db/database.dart';
import 'package:lichess_mobile/src/model/common/service/sound_service.dart';
import 'package:lichess_mobile/src/model/auth/auth_client.dart';
import 'package:lichess_mobile/src/model/auth/bearer.dart';
import 'package:lichess_mobile/src/model/auth/session_storage.dart';
import 'package:lichess_mobile/src/model/auth/user_session.dart';
import 'package:lichess_mobile/src/model/settings/general_preferences.dart';

part 'app_dependencies.freezed.dart';
part 'app_dependencies.g.dart';

@Riverpod(keepAlive: true)
Future<AppDependencies> appDependencies(
  AppDependenciesRef ref,
) async {
  final sessionStorage = ref.watch(sessionStorageProvider);
  final pInfo = await PackageInfo.fromPlatform();
  final prefs = await SharedPreferences.getInstance();
  final soundTheme = GeneralPreferences.fetchFromStorage(prefs).soundTheme;
  final soundPool = await ref.watch(soundPoolProvider(soundTheme).future);
  final client = ref.read(httpClientProvider);

  // Clear secure storage on first run because it is not deleted on app uninstall
  if (prefs.getBool('first_run') ?? true) {
    const storage = FlutterSecureStorage();

    await storage.deleteAll();

    await prefs.setBool('first_run', false);
  }

  final storedSession = await sessionStorage.read();

  if (storedSession != null) {
    try {
      final response = await client.get(
        Uri.parse('$kLichessHost/api/account'),
        headers: {
          'Authorization': 'Bearer ${signBearerToken(storedSession.token)}',
          'user-agent': AuthClient.userAgent(pInfo, storedSession.user),
        },
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 401) {
        await sessionStorage.delete();
      }
    } catch (e) {
      debugPrint('WARNING: [AppDependencies] Error while checking session: $e');
    }
  }

  final dbPath = p.join(await getDatabasesPath(), 'lichess_mobile.db');
  final db = await openDb(databaseFactory, dbPath);

  return AppDependencies(
    packageInfo: pInfo,
    sharedPreferences: prefs,
    soundPool: soundPool,
    userSession: await sessionStorage.read(),
    database: db,
  );
}

@freezed
class AppDependencies with _$AppDependencies {
  const factory AppDependencies({
    required PackageInfo packageInfo,
    required SharedPreferences sharedPreferences,
    required (Soundpool, IMap<Sound, int>) soundPool,
    required UserSession? userSession,
    required Database database,
  }) = _AppDependencies;
}

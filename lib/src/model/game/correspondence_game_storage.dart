import 'dart:convert';

import 'package:lichess_mobile/src/db/database.dart';
import 'package:lichess_mobile/src/model/common/id.dart';
import 'package:lichess_mobile/src/model/game/correspondence_game.dart';
import 'package:sqflite/sqflite.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'correspondence_game_storage.g.dart';

@Riverpod(keepAlive: true)
CorrespondenceGameStorage correspondenceGameStorage(
  CorrespondenceGameStorageRef ref,
) {
  final db = ref.watch(databaseProvider);
  return CorrespondenceGameStorage(db);
}

const _tableName = 'correspondence_game';

class CorrespondenceGameStorage {
  const CorrespondenceGameStorage(this._db);
  final Database _db;

  Future<CorrespondenceGame?> fetch({
    required GameId gameId,
  }) async {
    final list = await _db.query(
      _tableName,
      where: 'gameId = ?',
      whereArgs: [gameId.toString()],
    );

    final raw = list.firstOrNull?['data'] as String?;

    if (raw != null) {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        throw const FormatException(
          '[CorrespondenceGameStorage] cannot fetch game: expected an object',
        );
      }
      return CorrespondenceGame.fromJson(json);
    }
    return null;
  }

  Future<void> save({
    required CorrespondenceGame game,
  }) async {
    await _db.insert(
      _tableName,
      {
        'gameId': game.id.toString(),
        'lastModified': DateTime.now().toIso8601String(),
        'data': jsonEncode(game.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

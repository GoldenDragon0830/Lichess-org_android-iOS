import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lichess_mobile/src/model/challenge/challenge.dart';
import 'package:lichess_mobile/src/model/challenge/challenge_repository.dart';
import 'package:lichess_mobile/src/model/common/http.dart';

import '../../test_container.dart';
import '../../test_utils.dart';

void main() {
  group('ChallengeRepository', () {
    test('list', () async {
      final mockClient = MockClient((request) {
        if (request.url.path == '/api/challenge') {
          return mockResponse(
            challengesList,
            200,
          );
        }
        return mockResponse('', 404);
      });

      final container = await lichessClientContainer(mockClient);
      final client = container.read(lichessClientProvider);
      final repo = ChallengeRepository(client);
      final result = await repo.list();

      expect(result.inward, isA<IList<Challenge>>());
      expect(result.outward, isA<IList<Challenge>>());
      expect(result.inward.length, 1);
      expect(result.outward.length, 1);
    });
  });
}

const challengesList = '''
{"in": [ { "id": "H9fIRZUk", "url": "https://lichess.org/H9fIRZUk", "status": "created", "challenger": { "id": "bot1", "name": "Bot1", "rating": 1500, "title": "BOT", "provisional": true, "online": true, "lag": 4 }, "destUser": { "id": "bobby", "name": "Bobby", "rating": 1635, "title": "GM", "provisional": true, "online": true, "lag": 4 }, "variant": { "key": "standard", "name": "Standard", "short": "Std" }, "rated": true, "speed": "rapid", "timeControl": { "type": "clock", "limit": 600, "increment": 0, "show": "10+0" }, "color": "random", "finalColor": "black", "perf": { "icon": "", "name": "Rapid" }, "direction": "out" } ], "out": [ { "id": "H9fIRZUk", "url": "https://lichess.org/H9fIRZUk", "status": "created", "challenger": { "id": "bot1", "name": "Bot1", "rating": 1500, "title": "BOT", "provisional": true, "online": true, "lag": 4 }, "destUser": { "id": "bobby", "name": "Bobby", "rating": 1635, "title": "GM", "provisional": true, "online": true, "lag": 4 }, "variant": { "key": "standard", "name": "Standard", "short": "Std" }, "rated": true, "speed": "rapid", "timeControl": { "type": "clock", "limit": 600, "increment": 0, "show": "10+0" }, "color": "random", "finalColor": "black", "perf": { "icon": "", "name": "Rapid" }, "direction": "out" } ] }
''';

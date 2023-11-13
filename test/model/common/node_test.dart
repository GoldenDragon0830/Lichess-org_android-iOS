import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/model/common/uci.dart';
import 'package:lichess_mobile/src/model/common/eval.dart';
import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/node.dart';

void main() {
  group('Node', () {
    test('Root.fromPgnMoves', () {
      final root = Root.fromPgnMoves('e4 e5');
      expect(root.position, equals(Chess.initial));
      expect(root.children.length, equals(1));
      final child = root.children.first;
      expect(child.id, equals(UciCharPair.fromMove(Move.fromUci('e2e4')!)));
      expect(child.sanMove, equals(SanMove('e4', Move.fromUci('e2e4')!)));
      expect(
        child.position.fen,
        equals('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1'),
      );
      expect(
        child.position,
        equals(Chess.initial.playUnchecked(Move.fromUci('e2e4')!)),
      );
    });

    test('Root.fromPgnGame, flat', () {
      final pgnGame = PgnGame.parsePgn(fisherSpasskyPgn);
      final root = Root.fromPgnGame(pgnGame);
      expect(root.position, equals(Chess.initial));
      expect(root.children.length, equals(1));
      expect(root.mainline.length, equals(85));
    });

    test('Root.fromPgnGame, with variations', () {
      const pgn = '1. e4 d5 2. exd5 Qxd5 (2... Nf6 3. c4 (3. Nc3)) 3. Nc3';
      final root = Root.fromPgnGame(PgnGame.parsePgn(pgn));
      expect(root.position, equals(Chess.initial));
      expect(root.children.length, equals(1));
      expect(root.mainline.length, equals(5));
      final nodeWithVariation =
          root.nodeAt(UciPath.fromUciMoves(['e2e4', 'd7d5', 'e4d5']));
      expect(nodeWithVariation.children.length, 2);
      expect(nodeWithVariation.children[1].sanMove.san, equals('Nf6'));
      expect(nodeWithVariation.children[1].children.length, 2);
    });

    test('nodesOn, simple', () {
      final root = Root.fromPgnMoves('e4 e5');
      final path = UciPath.fromId(UciCharPair.fromUci('e2e4'));
      final nodeList = root.nodesOn(path);
      expect(nodeList.length, equals(1));
      expect(
        nodeList.first,
        equals(root.nodeAt(path) as Branch),
      );
    });

    test('nodesOn, with variation', () {
      final root = Root.fromPgnMoves('e4 e5 Nf3');
      final move = Move.fromUci('b1c3')!;
      final (newPath, _) = root.addMoveAt(
        UciPath.fromIds(
          [UciCharPair.fromUci('e2e4'), UciCharPair.fromUci('e7e5')].lock,
        ),
        move,
      );
      final newNode = root.nodeAt(newPath!);

      // mainline has not changed
      expect(root.mainline.length, equals(3));
      expect(
        root.mainline.last,
        equals(root.nodeAt(root.mainlinePath) as Branch),
      );

      final nodeList = root.nodesOn(newPath);
      expect(nodeList.length, equals(3));
      expect(nodeList.last, equals(newNode));
    });

    test('mainline', () {
      final root = Root.fromPgnMoves('e4 e5');
      final mainline = root.mainline;

      expect(mainline.length, equals(2));
      final list = mainline.toList();
      expect(list[0].sanMove, equals(SanMove('e4', Move.fromUci('e2e4')!)));
      expect(list[1].sanMove, equals(SanMove('e5', Move.fromUci('e7e5')!)));
    });

    test('add child', () {
      final root = Root(
        position: Chess.initial,
      );
      final child = Branch(
        sanMove: SanMove('e4', Move.fromUci('e2e4')!),
        position: Chess.initial,
      );
      root.addChild(child);
      expect(root.children.length, equals(1));
      expect(root.children.first, equals(child));
    });

    test('prepend child', () {
      final root = Root.fromPgnMoves('e4 e5');
      final child = Branch(
        sanMove: SanMove('d4', Move.fromUci('d2d4')!),
        position: Chess.initial,
      );
      root.prependChild(child);
      expect(root.children.length, equals(2));
      expect(root.children.first, equals(child));
      expect(root.children.last.id, equals(UciCharPair.fromUci('e2e4')));
    });

    test('nodeAt', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = root.nodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(branch, equals(root.children.first));
    });

    test('nodeAtOrNull', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch =
          root.nodeAtOrNull(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(branch, equals(root.children.first));

      final branch2 =
          root.nodeAtOrNull(UciPath.fromId(UciCharPair.fromUci('b1c3')));
      expect(branch2, isNull);
    });

    test('branchAt from root', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = root.branchAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(branch, equals(root.children.first));
    });

    test('branchAt from branch', () {
      final root = Root.fromPgnMoves('e4 e5 Nf3');
      final branch = root.branchAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      final branch2 =
          branch!.branchAt(UciPath.fromId(UciCharPair.fromUci('e7e5')));
      expect(branch2, equals(branch.children.first));
    });

    test('updateAt', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = Branch(
        sanMove: SanMove('Nc6', Move.fromUci('b8c6')!),
        position: Chess.initial,
      );

      final fromPath = UciPath.fromId(UciCharPair.fromUci('e2e4'));
      final (nodePath, _) = root.addNodeAt(fromPath, branch);

      expect(
        root.nodesOn(nodePath!),
        equals([
          root.children.first,
          branch,
        ]),
      );

      final eval = ClientEval(
        position: branch.position,
        maxDepth: 20,
        cp: 100,
        depth: 10,
        nodes: 1000,
        millis: 1000,
        pvs: IList([
          PvData(moves: IList(const ['e2e4'])),
        ]),
        isComputing: false,
      );

      final newNode = root.updateAt(nodePath, (node) {
        node.eval = eval;
      });

      expect(
        root.nodesOn(nodePath),
        equals([
          root.children.first,
          newNode!,
        ]),
      );
    });

    test('addNodeAt', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = Branch(
        sanMove: SanMove('Nc6', Move.fromUci('b8c6')!),
        position: Chess.initial,
      );
      final (newPath, isNewNode) =
          root.addNodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')), branch);

      expect(
        newPath,
        equals(
          UciPath.fromIds(
            IList([UciCharPair.fromUci('e2e4'), UciCharPair.fromUci('b8c6')]),
          ),
        ),
      );

      expect(isNewNode, isTrue);

      final testNode = root.nodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(testNode.children.length, equals(2));
      expect(testNode.children[1], equals(branch));
    });

    test('addNodeAt, prepend', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = Branch(
        sanMove: SanMove('Nc6', Move.fromUci('b8c6')!),
        position: Chess.initial,
      );
      root.addNodeAt(
        UciPath.fromId(UciCharPair.fromUci('e2e4')),
        branch,
        prepend: true,
      );

      final testNode = root.nodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(testNode.children.length, equals(2));
      expect(testNode.children[0], equals(branch));
    });

    test('addNodeAt, with an existing node at path', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = Branch(
        sanMove: SanMove('e5', Move.fromUci('e7e5')!),
        position: Chess.initial,
      );
      final (newPath, isNewNode) =
          root.addNodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')), branch);

      expect(
        newPath,
        equals(
          UciPath.fromIds(
            IList([UciCharPair.fromUci('e2e4'), UciCharPair.fromUci('e7e5')]),
          ),
        ),
      );

      expect(isNewNode, isFalse);

      final testNode = root.nodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));

      // node is not replaced
      expect(testNode.children.length, equals(1));
      expect(testNode.children[0], isNot(branch));
    });

    test('addNodesAt', () {
      final root = Root.fromPgnMoves('e4 e5');
      final branch = Branch(
        sanMove: SanMove('Nc6', Move.fromUci('b8c6')!),
        position: Chess.initial,
      );
      final branch2 = Branch(
        sanMove: SanMove('Na6', Move.fromUci('b8a6')!),
        position: Chess.initial,
      );
      root.addNodesAt(
        UciPath.fromId(UciCharPair.fromUci('e2e4')),
        [branch, branch2],
      );

      final testNode = root.nodeAt(UciPath.fromId(UciCharPair.fromUci('e2e4')));
      expect(testNode.children.length, equals(2));
      expect(testNode.children[1], equals(branch));
      expect(testNode.children[1].children[0], equals(branch2));
    });

    test('addMoveAt', () {
      final root = Root.fromPgnMoves('e4 e5');
      final move = Move.fromUci('b1c3')!;
      final path = UciPath.fromIds(
        [UciCharPair.fromUci('e2e4'), UciCharPair.fromUci('e7e5')].lock,
      );
      final currentPath = root.mainlinePath;
      final (newPath, _) = root.addMoveAt(path, move);
      expect(
        newPath,
        equals(currentPath + UciCharPair.fromMove(move)),
      );
      final newNode = root.branchAt(newPath!);
      expect(newNode?.position.ply, equals(3));
      expect(newNode?.sanMove, equals(SanMove('Nc3', move)));
      expect(
        newNode?.position.fen,
        equals(
          'rnbqkbnr/pppp1ppp/8/4p3/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq - 1 2',
        ),
      );

      final testNode = root.nodeAt(path);
      expect(testNode.children.length, equals(1));
      expect(testNode.children.first.sanMove, equals(SanMove('Nc3', move)));
      expect(
        testNode.children.first.position.fen,
        equals(
          'rnbqkbnr/pppp1ppp/8/4p3/4P3/2N5/PPPP1PPP/R1BQKBNR b KQkq - 1 2',
        ),
      );
    });
  });
}

const fisherSpasskyPgn = '''
[Event "F/S Return Match"]
[Site "Belgrade, Serbia Yugoslavia|JUG"]
[Date "1992.11.04"]
[Round "29"]
[White "Fischer, Robert J."]
[Black "Spassky, Boris V."]
[Result "1/2-1/2"]

1. e4 e5 2. Nf3 Nc6 3. Bb5 {This opening is called the Ruy Lopez.} 3... a6
4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8  10. d4 Nbd7
11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15. Nb1 h6 16. Bh4 c5 17. dxe5
Nxe4 18. Bxe7 Qxe7 19. exd6 Qf6 20. Nbd2 Nxd6 21. Nc4 Nxc4 22. Bxc4 Nb6
23. Ne5 Rae8 24. Bxf7+ Rxf7 25. Nxf7 Rxe1+ 26. Qxe1 Kxf7 27. Qe3 Qg5 28. Qxg5
hxg5 29. b3 Ke6 30. a3 Kd6 31. axb4 cxb4 32. Ra5 Nd5 33. f3 Bc8 34. Kf2 Bf5
35. Ra7 g6 36. Ra6+ Kc5 37. Ke1 Nf4 38. g3 Nxh3 39. Kd2 Kb5 40. Rd6 Kc5 41. Ra6
Nf2 42. g4 Bd3 43. Re6 1/2-1/2''';

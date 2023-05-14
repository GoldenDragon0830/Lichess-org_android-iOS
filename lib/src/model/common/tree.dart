import 'package:collection/collection.dart';
import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'package:lichess_mobile/src/model/common/chess.dart';
import 'package:lichess_mobile/src/model/common/eval.dart';
import 'package:lichess_mobile/src/model/common/uci.dart';

part 'tree.freezed.dart';

abstract class RootOrNode {
  RootOrNode({
    required this.ply,
    required this.fen,
    required this.position,
  });

  final int ply;
  final String fen;
  final Position position;
  final List<Node> children = [];

  /// Adds a child to this node.
  void addChild(Node node) => children.add(node);

  /// Prepends a child to this node.
  void prependChild(Node node) => children.insert(0, node);

  /// Finds the child node with that id.
  Node? childById(UciCharPair id) {
    return children.firstWhereOrNull((node) => node.id == id);
  }

  /// An iterable of all nodes on the mainline.
  Iterable<ViewNode> get mainline sync* {
    RootOrNode current = this;
    while (current.children.isNotEmpty) {
      final child = current.children.first;
      yield ViewNode.fromNode(child);
      current = child;
    }
  }

  /// Selects all nodes on that path.
  Iterable<ViewNode> nodesOn(UciPath path) sync* {
    UciPath currentPath = path;

    Node? pickChild(RootOrNode node) {
      final id = currentPath.head;
      if (id == null) {
        return null;
      }
      return node.childById(id);
    }

    RootOrNode current = this;
    Node? child;

    while ((child = pickChild(current)) != null) {
      yield ViewNode.fromNode(child!);
      current = child;
      currentPath = currentPath.tail;
    }
  }

  /// Gets the path of the mainline.
  UciPath get mainlinePath => UciPath.fromNodeList(mainline);

  /// Updates the node at the given path.
  ///
  /// Returns the updated node, or null if the node was not found.
  Node? updateAt(UciPath path, void Function(Node node) update) {
    final node = nodeAtOrNull(path);
    if (node != null && node is Node) {
      update(node);
      return node;
    }
    return null;
  }

  /// Adds a new node at the given path and returns the new path.
  ///
  /// If the node already exists, it is not added again.
  UciPath? addNodeAt(UciPath path, Node newNode, {bool prepend = false}) {
    final newPath = path + newNode.id;
    final node = nodeAtOrNull(path);
    if (node != null) {
      final existing = nodeAtOrNull(newPath) != null;
      if (!existing) {
        if (prepend) {
          node.prependChild(newNode);
        } else {
          node.addChild(newNode);
        }
      }
      return newPath;
    } else {
      return null;
    }
  }

  /// Adds a list of nodes at the given path and returns the new path.
  UciPath? addNodesAt(
    UciPath path,
    Iterable<Node> newNodes, {
    bool prepend = false,
  }) {
    final node = newNodes.elementAtOrNull(0);
    if (node == null) return path;
    final newPath = addNodeAt(path, node, prepend: prepend);
    return newPath != null
        ? addNodesAt(newPath, newNodes.skip(1), prepend: prepend)
        : null;
  }

  /// Adds a new node with that [Move] at the given path.
  ///
  /// Returns the new path and the new node.
  /// If the node already exists, it is not added again.
  (UciPath?, Node?) addMoveAt(
    UciPath path,
    Move move, {
    bool prepend = false,
  }) {
    final pos = nodeAt(path).position;
    final (newPos, newSan) = pos.playToSan(move);
    final newNode = Node(
      id: UciCharPair.fromMove(move),
      ply: 2 * (newPos.fullmoves - 1) + (newPos.turn == Side.white ? 0 : 1),
      sanMove: SanMove(newSan, move),
      fen: newPos.fen,
      position: newPos,
    );
    final newPath = addNodeAt(path, newNode, prepend: prepend);
    return (newPath, newPath != null ? newNode : null);
  }

  /// Gets the node at the given path.
  RootOrNode nodeAt(UciPath path) {
    if (path.isEmpty) return this;
    final child = childById(path.head!);
    if (child != null) {
      return child.nodeAt(path.tail);
    } else {
      return this;
    }
  }

  /// Gets the node at the given path, or null if it does not exist.
  RootOrNode? nodeAtOrNull(UciPath path) {
    if (path.isEmpty) return this;
    final child = childById(path.head!);
    if (child != null) {
      return child.nodeAtOrNull(path.tail);
    } else {
      return null;
    }
  }
}

class Node extends RootOrNode {
  Node({
    required this.id,
    required super.ply,
    required super.fen,
    required super.position,
    required this.sanMove,
    this.eval,
  });

  final UciCharPair id;

  final SanMove sanMove;

  ClientEval? eval;

  @override
  String toString() {
    return 'Node(id: $id, ply: $ply, fen: $fen, sanMove: $sanMove, eval: $eval, children: $children)';
  }
}

class Root extends RootOrNode {
  Root({
    required super.ply,
    required super.fen,
    required super.position,
  });

  /// Creates a game tree from a PGN string.
  ///
  /// Assumes that the PGN string is valid and that the moves are legal.
  factory Root.fromPgn(String pgn) {
    int ply = 0;
    Position position = Chess.initial;
    final root = Root(
      ply: ply,
      fen: kInitialFEN,
      position: position,
    );
    RootOrNode current = root;
    final moves = pgn.split(' ');
    for (final san in moves) {
      ply++;
      final move = position.parseSan(san);
      position = position.playUnchecked(move!);
      final nextNode = Node(
        id: UciCharPair.fromMove(move),
        ply: ply,
        sanMove: SanMove(san, move),
        fen: position.fen,
        position: position,
      );
      current.addChild(nextNode);
      current = nextNode;
    }
    return root;
  }
}

/// An immutable view of a [Node].
@freezed
class ViewNode with _$ViewNode {
  const ViewNode._();

  const factory ViewNode({
    required UciCharPair id,
    required int ply,
    required String fen,
    required Position position,
    required SanMove sanMove,
    required IList<ViewNode> children,
    ClientEval? eval,
  }) = _ViewNode;

  factory ViewNode.fromNode(Node node) {
    return ViewNode(
      id: node.id,
      ply: node.ply,
      fen: node.fen,
      position: node.position,
      sanMove: node.sanMove,
      eval: node.eval,
      children: node.children.map(ViewNode.fromNode).toIList(),
    );
  }
}

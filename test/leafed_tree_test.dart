import 'package:flutter_test/flutter_test.dart';
import 'package:voronoi/structs/leafedTree.dart';

main() {
  group("Queue size", () {
    test("Newly created tree is empty", () {
      LeafedTree t = LeafedTree();
      expect(t.isEmpty, isTrue);
      expect(t.isNotEmpty, isFalse);
    });

    test("Populated queue is not empty", () {
      LeafedTree t = LeafedTree();
      t.root = TestInternalNode(0.0);
      expect(t.isEmpty, isFalse);
      expect(t.isNotEmpty, isTrue);
    });

    test("Cleared list is empty", () {
      LeafedTree t = LeafedTree();
      t.root = TestInternalNode(0.0);
      t.clear();
      expect(t.isEmpty, isTrue);
    });
  });

  group("Functionality", () {});

  group("Error checking", () {});
}

class TestInternalNode extends TreeInternalNode {
  double val;
  TestInternalNode(this.val);
}

class TestLeaf extends TreeLeaf {
  double val;
  TestLeaf(this.val);
}

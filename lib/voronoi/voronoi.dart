library voronoi;

import "dart:math";
import 'dart:ui';
import "package:voronoi/structs/priorityQueue.dart";
import "package:voronoi/geometry/geometry.dart";
import 'package:voronoi/structs/leafedTree.dart';

part "doublyConnectedEdgeList.dart";
part "beachLine.dart";

class Voronoi {
  static double epsilon = 0.0001;

  PriorityQueue<VoronoiEvent> _queue;
  BeachLine _beach;
  DoublyConnectedEdgeList _d;

  List<VoronoiSite> _sites;
  double sweep = 0.0;

  List<Vector2> get sites => _sites.map((VoronoiSite s) => s.pos).toList();
  List<Vector2> get vertices => _d.vertices.map((Vertex v) => v.p).toList();
  List<HalfEdge> get edges => _d.edges;
  List<Face> get faces => _d.faces;
  DoublyConnectedEdgeList get dcel => _d;

  Rectangle<double> boundingBox;

  Voronoi(List<Vector2> pts, Rect rect, {start = true}) {
    boundingBox = Rectangle(rect.left, rect.top, rect.width, rect.height);

    if (pts.length == 0)
      throw ArgumentError("Voronoi diagram must contain at least 1 site");

    // init structures
    _queue = PriorityQueue();
    _beach = BeachLine();
    _d = DoublyConnectedEdgeList();
    _sites = pts.map((Vector2 pt) => VoronoiSite(pt, _d)).toList();

    // add each point to event queue based on y coord
    _sites.forEach((VoronoiSite s) => _queue.push(VoronoiSiteEvent(s)));

    // start processing events
    if (start) generate();
  }

  // Processes all events, then clean up and builds the proximity search
  void generate() {
    while (_queue.isNotEmpty) {
      nextEvent();
    }
    _clean();
  }

  // Cleans up the diagram, adding a bounding box and removing redundant vertices/halfedges
  void _clean() {
    // stretch halfedges still inside box to the outside
    _beach.tree.internalNodes
        .cast<BeachInternalNode>()
        .forEach((BeachInternalNode node) {
      HalfEdge e = node.edge;
      // add vertices for infinite edges
      Vector2 p = _beach.calculateBreakpoint(node.a, node.b, sweep);
      double ratio = 1.0;
      while (boundingBox.containsPoint((p * ratio).asPoint)) {
        // extend to outside the box arbitrarily, we will clip it back later
        ratio *= 2;
      }
      _d.removeVertex(e.twin.o);
      e.twin.o = _d.newVertex(p * ratio);
    });
    // add bounding box to diagram
    _d.bindTo(boundingBox);
  }

  void nextEvent() {
    if (_queue.isNotEmpty) {
      _handleEvent(_queue.pop);
    }
  }

  void _handleEvent(VoronoiEvent e) {
    sweep = e.y;
    if (e is VoronoiSiteEvent)
      _handleSiteEvent(e.s);
    else if (e is VoronoiCircleEvent) _handleCircleEvent(e);
  }

  void _handleSiteEvent(VoronoiSite s) {
    if (_beach.isEmpty) {
      _beach.tree.root = BeachLeaf(s);
    } else {
      BeachLeaf closest = _beach.findLeaf(s.x, sweep);

      // if circle has an event, mark it as a false alarm
      _checkFalseAlarm(closest);

      // grow the tree
      BeachInternalNode newTree = BeachInternalNode();
      BeachInternalNode newSubTree = BeachInternalNode();
      BeachLeaf leafL = closest.clone();
      BeachLeaf leafM = BeachLeaf(s);
      BeachLeaf leafR = closest.clone();

      newTree.l = leafL;
      newTree.r = newSubTree;
      newTree.a = closest.site;
      newTree.b = s;
      newSubTree.l = leafM;
      newSubTree.r = leafR;
      newSubTree.a = s;
      newSubTree.b = closest.site;

      if (closest.parent == null) {
        _beach.tree.root = newTree;
      } else if (closest.parent.l == closest) {
        closest.parent.l = newTree;
      } else {
        closest.parent.r = newTree;
      }

      // update voronoi structure
      HalfEdge e1 = _d.newEdge();
      HalfEdge e2 = _d.newTwinEdgeForFace(e1, s.face);
      closest.site.face.edge = e1;
      newTree.edge = e2;
      newSubTree.edge = e1;

      // check new trips
      _checkTriple(leafL.leftLeaf, leafL, leafM);
      _checkTriple(leafM, leafR, leafR.rightLeaf);
    }
  }

  void _handleCircleEvent(VoronoiCircleEvent e) {
    //check for false alarm
    if (e.isFalseAlarm) return;

    BeachLeaf leaf = e.arc;
    BeachInternalNode oldNode = leaf.parent;
    BeachInternalNode brokenNode = _beach.findInternalNode(e.c.o.x, sweep);

    // TODO: can this be done with a numerical comparison?
    bool oldLeftOfBroken = oldNode.isInLeftSubtreeOf(brokenNode);

    // events
    BeachLeaf leafL = leaf.leftLeaf;
    BeachLeaf leafR = leaf.rightLeaf;
    _checkFalseAlarm(leafL);
    _checkFalseAlarm(leafR);

    // remove intersection node
    if (oldNode.parent.l == oldNode) {
      oldNode.parent.l = leaf.brother;
    } else {
      oldNode.parent.r = leaf.brother;
    }

    // update node referencing old arc (fix broken node)
    brokenNode.a = (brokenNode.l.rightMostLeaf as BeachLeaf).site;
    brokenNode.b = (brokenNode.r.leftMostLeaf as BeachLeaf).site;

    // diagram
    Vertex v = _d.newVertex(e.c.o);
    HalfEdge edge = _d.newFullEdge();

    // connect structure
    if (oldLeftOfBroken) {
      edge.face = brokenNode.edge.face;
      edge.twin.face = oldNode.edge.twin.face;

      brokenNode.edge.next = edge;
      edge.twin.next = oldNode.edge.twin;
      oldNode.edge.next = brokenNode.edge.twin;
    } else {
      edge.twin.face = brokenNode.edge.twin.face;
      edge.face = oldNode.edge.face;

      oldNode.edge.next = edge;
      edge.twin.next = brokenNode.edge.twin;
      brokenNode.edge.next = oldNode.edge.twin;
    }

    // attach new edge to vertex
    edge.o = v;

    // attach old node edges to this vertex
    oldNode.edge.twin.o = v;
    brokenNode.edge.twin.o = v;

    // update edge of new fixed node
    brokenNode.edge = edge;

    _checkTriple(leafL.leftLeaf, leafL, leafL.rightLeaf);
    _checkTriple(leafR.leftLeaf, leafR, leafR.rightLeaf);
  }

  void _checkFalseAlarm(BeachLeaf leaf) {
    if (leaf.hasEvent) {
      leaf.event.isFalseAlarm = true;
    }
  }

  void _checkTriple(BeachLeaf a, BeachLeaf b, BeachLeaf c) {
    if (a == null || b == null || c == null) return;

    double syden = 2 * ((a.y - b.y) * (b.x - c.x) - (b.y - c.y) * (a.x - b.x));
    if (syden < 0) {
      //if the circle converges
      // calculate intersection
      double synum =
          (c.x * c.x + c.y * c.y - b.x * b.x - b.y * b.y) * (a.x - b.x) -
              (b.x * b.x + b.y * b.y - a.x * a.x - a.y * a.y) * (b.x - c.x);
      double sy = synum / syden;
      double sx = ((c.x * c.x + c.y * c.y - b.x * b.x - b.y * b.y) *
                  (a.y - b.y) -
              (b.x * b.x + b.y * b.y - a.x * a.x - a.y * a.y) * (b.y - c.y)) /
          -syden;
      Vector2 o = Vector2(sx, sy);

      // set the new event
      Circle cir = Circle(o, (a.pos - o).magnitude);
      VoronoiCircleEvent e = VoronoiCircleEvent(cir);
      _queue.push(e);
      b.event = e;
      e.arc = b;
    }
  }
}

abstract class VoronoiEvent implements Comparable {
  double get y;

  int compareTo(dynamic other) {
    return -y.compareTo(other.y);
  }
}

class VoronoiSiteEvent extends VoronoiEvent {
  VoronoiSite s;

  double get y => s.y;

  VoronoiSiteEvent(this.s);
}

class VoronoiCircleEvent extends VoronoiEvent {
  Circle c;
  BeachLeaf arc;
  bool isFalseAlarm = false;

  double get y => c.bottom;

  VoronoiCircleEvent(this.c);
}

class VoronoiNullEvent extends VoronoiEvent {
  double y;

  VoronoiNullEvent(this.y);
}

class VoronoiSite {
  Vector2 pos;
  HalfEdge edge;
  Face face;

  get x => pos.x;
  get y => pos.y;

  VoronoiSite(this.pos, DoublyConnectedEdgeList d) {
    this.face = d.newFace(this.pos);
  }

  bool operator ==(Object other) =>
      other is VoronoiSite && other.x == this.x && other.y == this.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:voronoi/voronoi/voronoi.dart';
import 'package:voronoi/geometry/geometry.dart';

main() {
  group("Structure", () {
    test("Number of faces is the same as the number of sites", () {
      var pts = [
        Vector2(100.0, 100.0),
        Vector2(105.0, 200.0),
        Vector2(150.0, 130.0),
        Vector2(85.0, 287.0),
        Vector2(153.0, 321.0)
      ];

      var v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 500.0, 500.0));
      expect(v.faces.length, equals(pts.length));
    });

    test("Each face has an associated edge", () {
      var pts = [
        Vector2(100.0, 100.0),
        Vector2(105.0, 200.0),
        Vector2(150.0, 130.0),
        Vector2(85.0, 287.0),
        Vector2(153.0, 321.0)
      ];
      var v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 500.0, 500.0));
      v.faces.forEach((Face f) {
        expect(f.edge, isNotNull);
      });
    });

    test("All edges form a loop", () {
      var pts = [
        Vector2(100.0, 100.0),
        Vector2(310.0, 412.0),
        Vector2(105.0, 200.0),
        Vector2(150.0, 130.0),
        Vector2(85.0, 287.0),
        Vector2(153.0, 321.0)
      ];

      var v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 500.0, 500.0));
      v.edges.forEach((HalfEdge e) {
        HalfEdge next = e.next;
        while (next != null && next != e) {
          next = next.next;
        }

        if (next != null) {
          expect(next, isNotNull);
          expect(next, equals(e));
        }
      });
    });

    test("Each edge has an associated face", () {
      List<Vector2> pts = [
        Vector2(432.0, 86.0),
        Vector2(100.0, 100.0),
        Vector2(310.0, 412.0),
        Vector2(105.0, 200.0),
        Vector2(150.0, 130.0),
        Vector2(85.0, 287.0),
        Vector2(153.0, 321.0)
      ];
      Voronoi v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 500.0, 500.0));
      v.edges.forEach((HalfEdge e) {
        expect(e.face, isNotNull);
      });
    });

    test("Each edge loop has the same associated face", () {
      List<Vector2> pts = [
        Vector2(432.0, 86.0),
        Vector2(100.0, 100.0),
        Vector2(12.2, 99.3),
        Vector2(310.0, 412.0),
        Vector2(105.0, 200.0),
        Vector2(150.0, 130.0),
        Vector2(85.0, 287.0),
        Vector2(153.0, 321.0)
      ];
      Voronoi v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 500.0, 500.0));
      v.faces.forEach((Face f) {
        HalfEdge start = f.edge;
        HalfEdge curr = start;
        do {
          expect(curr.face, equals(start.face));
          curr = curr.next;
        } while (curr != start);
      });
    });
  });

  group("Edge cases", () {
    test("No input points throws an error", () {
      expect(() => Voronoi([], Rect.fromLTWH(0.0, 0.0, 200.0, 200.0)),
          throwsArgumentError);
    });

    test("A single point produces one face", () {
      var pts = [Vector2(100.0, 100.0)];
      Voronoi v = Voronoi(pts, Rect.fromLTWH(0.0, 0.0, 200.0, 200.0));
      expect(v.faces.length, equals(1));
    });
  });

  group("Error checking", () {
    test("Creating diagram with no input sites throws an error", () {
      expect(() => Voronoi([], Rect.fromLTWH(0.0, 0.0, 500.0, 500.0)),
          throwsArgumentError);
    });
  });

  /*group("Performance", () {
    test("Perf under 10s", () {
      final stopwatch = Stopwatch()..start();

      var area = Rectangle(0.0, 0.0, 5000.0, 5000.0);
      var sampler = new PoissonDiskSampler(area);
      var numPoints = 1000;
      var attempts = 50;

      for (int i = 0; i < attempts; i++) {
        var v = Voronoi(sampler.generatePoints(numPoints), area);
      }

      var elapsedMs = stopwatch.elapsedMilliseconds;
      var timePerLoop = elapsedMs / attempts;
      int i = 0;
    });
  });*/
}

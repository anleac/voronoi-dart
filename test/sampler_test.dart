import 'package:flutter_test/flutter_test.dart';
import 'package:voronoi/sampler/sampler.dart';
import 'dart:math';
import 'package:voronoi/geometry/geometry.dart';

const int RNG_SEED = 9428502843;

main() {
  Rectangle r = Rectangle(100, 100, 500, 500);
  Random rng;

  setUp(() => rng = Random(RNG_SEED));

  group("Approximately the correct amount of points are generated", () {
    test("20+/-5", () {
      PoissonDiskSampler s = PoissonDiskSampler.withRng(r, rng);
      int numRuns = 500;
      for (int i = 0; i < numRuns; i++) {
        List<Vector2> pts = s.generatePoints(20);
        expect(pts.length, inInclusiveRange(15, 25));
      }
    });

    test("200+/-20", () {
      PoissonDiskSampler s = PoissonDiskSampler.withRng(r, rng);
      int numRuns = 200;
      for (int i = 0; i < numRuns; i++) {
        List<Vector2> pts = s.generatePoints(200);
        expect(pts.length, inInclusiveRange(180, 220));
      }
    });

    test("1000+/-30", () {
      PoissonDiskSampler s = PoissonDiskSampler.withRng(r, rng);
      int numRuns = 100;
      for (int i = 0; i < numRuns; i++) {
        List<Vector2> pts = s.generatePoints(1000);
        expect(pts.length, inInclusiveRange(970, 1030));
      }
    });

    test("10000+/-150", () {
      PoissonDiskSampler s = PoissonDiskSampler.withRng(r, rng);
      int numRuns = 20;
      for (int i = 0; i < numRuns; i++) {
        List<Vector2> pts = s.generatePoints(10000);
        expect(pts.length, inInclusiveRange(9850, 10150));
      }
    });
  });

  group("All points are inside the bounding rectangle", () {
    test("10000 points in a square", () {
      PoissonDiskSampler s = PoissonDiskSampler.withRng(r, rng);
      s.generatePoints(10000).forEach((Vector2 v) {
        expect(r.containsPoint(v.asPoint), isTrue);
      });
    });

    test("10000 points in a thin rectangle", () {
      Rectangle rect = Rectangle(0, 100, 20, 5000);
      PoissonDiskSampler s = PoissonDiskSampler.withRng(rect, rng);
      s.generatePoints(10000).forEach((Vector2 v) {
        expect(rect.containsPoint(v.asPoint), isTrue);
      });
    });
  });

  group("Random generation is consistent", () {
    test("1000 points with seed 123", () {
      Rectangle rect = Rectangle(0, 0, 500, 500);
      List<Vector2> pts1 =
          PoissonDiskSampler.withRng(rect, Random(123)).generatePoints(1000);
      List<Vector2> pts2 =
          PoissonDiskSampler.withRng(rect, Random(123)).generatePoints(1000);
      expect(pts1, equals(pts2));
    });
  });
}

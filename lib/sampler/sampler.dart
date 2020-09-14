library sampler;

import 'package:flutter/material.dart';
import 'package:voronoi/geometry/geometry.dart';
import 'dart:math';

part "uniformSampler.dart";
part "poissonDiskSampler.dart";
part "jitteredGridSampler.dart";

abstract class Sampler {
  Random _rng;
  Rect _rect;

  Sampler(this._rect) {
    _rng = Random();
  }

  Sampler.withRng(this._rect, this._rng);

  set rng(Random rng) => _rng = rng;
  set seed(int seed) => _rng = Random(seed);

  List<Vector2> generatePoints(int numPoints);
}

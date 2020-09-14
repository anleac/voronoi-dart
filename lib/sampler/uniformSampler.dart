part of sampler;

class UniformSampler extends Sampler {
  UniformSampler(Rect r) : super(r);
  UniformSampler.withRng(Rect r, Random rng) : super.withRng(r, rng);

  Vector2 generatePoint() {
    return Vector2(_rect.left + _rng.nextDouble() * _rect.width,
        _rect.top + _rng.nextDouble() * _rect.height);
  }

  List<Vector2> generatePoints(int numPoints) {
    List<Vector2> ps = List();
    for (int i = 0; i < numPoints; i++) {
      ps.add(generatePoint());
    }
    return ps;
  }

  Vector2 generateAnnulusPoint(Vector2 o, double r) {
    double angle = _rng.nextDouble() * 2 * pi;
    double length = _rng.nextDouble() * r + r;
    Vector2 p = Vector2(o.x + length * sin(angle), o.y + length * cos(angle));
    if (_rect.contains(Offset(p.x, p.y)))
      return p;
    else
      return generateAnnulusPoint(o, r);
  }
}

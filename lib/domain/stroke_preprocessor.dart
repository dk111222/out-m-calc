import 'dart:math' as math;

/// One sample from a pen-down stroke.
///
/// [timestamp] is microseconds, and it only has to increase along the
/// stroke. Recognition reads x and y; the time is kept so a resampled
/// point stays between the samples it came from.
class StrokePoint {
  const StrokePoint(this.x, this.y, this.timestamp);

  final double x;
  final double y;
  final int timestamp;
}

/// Cleans finger ink before it reaches the recognizer.
///
/// The steps follow a handwriting keyboard: drop specks, calm jitter,
/// even out the point spacing, then fit the whole expression into one
/// square without stretching it. Each inner list is one pen-down stroke,
/// so a fraction bar stays a separate stroke from the digits around it.
///
/// The same cleaning runs on every stroke of the expression together.
/// Scaling one stroke at a time would pull a numerator, a bar, and a
/// denominator apart.
class StrokePreprocessor {
  const StrokePreprocessor._();

  /// Shortest path, in pad pixels, that still counts as ink.
  ///
  /// A decimal dot in this pad is only a few pixels across (the bundled
  /// examples are about 4–6). Anything shorter is a palm speck or a
  /// resting finger. Digits and fraction bars are many times longer.
  static const double minStrokeLength = 4;

  /// Centered moving-average window. 3 calms jitter and leaves the
  /// corner of a 4, the hook of a 2, and a thin fraction bar in place.
  static const int smoothWindow = 3;

  /// Distance between samples after resampling, in pad pixels.
  /// Fast strokes are filled in and slow strokes are thinned to this.
  static const double resampleDistance = 4;

  /// Long side of the square the expression is fitted into.
  static const double targetSize = 220;

  /// Inset from the edge of [targetSize]. The long side of the ink
  /// lands in `[padding, targetSize - padding]`.
  static const double padding = 10;

  /// A mark needs this many distinct samples. One or two samples is a tap.
  static const int minPointCount = 3;

  /// Points closer than this are the same sample repeated by the touch
  /// screen, not a new part of the stroke.
  static const double _samePoint = 0.5;

  /// Returns cleaned strokes in the original pen order.
  ///
  /// An empty list means there is nothing to recognize.
  static List<List<StrokePoint>> process(List<List<StrokePoint>> rawStrokes) {
    // 1. Noise filter: stray taps, repeated samples, and specks.
    final filtered = _filterNoise(rawStrokes);
    if (filtered.isEmpty) return const [];

    // 2. Smooth each stroke. Endpoints stay put, so a short dot or a
    // straight fraction bar does not shrink toward its middle.
    final smoothed = <List<StrokePoint>>[
      for (final stroke in filtered) _smooth(stroke),
    ];

    // 3. Resample so every stroke has the same point spacing. Stroke
    // order and the time order inside each stroke stay as drawn.
    final resampled = <List<StrokePoint>>[
      for (final stroke in smoothed) _resample(stroke, resampleDistance),
    ];

    final alive = <List<StrokePoint>>[
      for (final stroke in resampled)
        if (stroke.length >= 2) stroke,
    ];
    if (alive.isEmpty) return const [];

    // 4. Move the whole expression to the origin and scale it uniformly
    // into the target square, with a margin on the long side.
    final normalized = _normalize(alive);

    // 5. No usable ink left: the caller skips recognition.
    if (normalized.isEmpty) return const [];
    return normalized;
  }

  static List<List<StrokePoint>> _filterNoise(List<List<StrokePoint>> raw) {
    final kept = <List<StrokePoint>>[];
    for (final stroke in raw) {
      final clean = _dropStrayPoints(stroke);
      if (clean.length < minPointCount) continue;
      if (_length(clean) < minStrokeLength) continue;
      kept.add(clean);
    }
    return kept;
  }

  /// Drops a one-sample tap and extra copies of a point the finger
  /// was already sitting on.
  static List<StrokePoint> _dropStrayPoints(List<StrokePoint> stroke) {
    if (stroke.isEmpty) return const [];
    final kept = <StrokePoint>[stroke.first];
    for (var i = 1; i < stroke.length; i++) {
      final point = stroke[i];
      if (_distance(kept.last, point) < _samePoint) continue;
      kept.add(point);
    }
    return kept;
  }

  static List<StrokePoint> _smooth(List<StrokePoint> stroke) {
    if (smoothWindow < 3 || stroke.length < 3) {
      return List<StrokePoint>.of(stroke);
    }
    final radius = smoothWindow ~/ 2;
    final smoothed = List<StrokePoint>.of(stroke);
    for (var i = 1; i < stroke.length - 1; i++) {
      var sumX = 0.0;
      var sumY = 0.0;
      var count = 0;
      final from = math.max(0, i - radius);
      final to = math.min(stroke.length - 1, i + radius);
      for (var j = from; j <= to; j++) {
        sumX += stroke[j].x;
        sumY += stroke[j].y;
        count++;
      }
      final point = stroke[i];
      smoothed[i] = StrokePoint(sumX / count, sumY / count, point.timestamp);
    }
    return smoothed;
  }

  /// Walks the polyline and emits a point every [spacing] pixels.
  /// The first and last samples stay, so the stroke keeps its length.
  /// Each step moves forward along the current segment, so the walk ends.
  static List<StrokePoint> _resample(List<StrokePoint> stroke, double spacing) {
    if (stroke.length < 2 || spacing <= 0) {
      return List<StrokePoint>.of(stroke);
    }
    final out = <StrokePoint>[stroke.first];
    var accumulated = 0.0;
    for (var i = 1; i < stroke.length; i++) {
      final start = stroke[i - 1];
      final end = stroke[i];
      final segment = _distance(start, end);
      if (segment == 0) continue;
      if (accumulated + segment < spacing) {
        accumulated += segment;
        continue;
      }
      var t = (spacing - accumulated) / segment;
      final step = spacing / segment;
      while (t <= 1) {
        final time = _lerpTime(start.timestamp, end.timestamp, t);
        final previousTime = out.last.timestamp;
        final candidate = StrokePoint(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
          time < previousTime ? previousTime : time,
        );
        if (_distance(out.last, candidate) >= _samePoint) out.add(candidate);
        t += step;
      }
      final placed = t - step;
      accumulated = (1 - placed) * segment;
    }
    final end = stroke.last;
    if (_distance(out.last, end) > _samePoint) out.add(end);
    return out;
  }

  static List<List<StrokePoint>> _normalize(List<List<StrokePoint>> strokes) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final stroke in strokes) {
      for (final point in stroke) {
        if (point.x < minX) minX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.x > maxX) maxX = point.x;
        if (point.y > maxY) maxY = point.y;
      }
    }
    final width = math.max(maxX - minX, 1e-3);
    final height = math.max(maxY - minY, 1e-3);
    final inner = math.max(targetSize - 2 * padding, 1);
    final scale = inner / math.max(width, height);
    return [
      for (final stroke in strokes)
        [
          for (final point in stroke)
            StrokePoint(
              (point.x - minX) * scale + padding,
              (point.y - minY) * scale + padding,
              point.timestamp,
            ),
        ],
    ];
  }

  static double _length(List<StrokePoint> stroke) {
    var length = 0.0;
    for (var i = 1; i < stroke.length; i++) {
      length += _distance(stroke[i - 1], stroke[i]);
    }
    return length;
  }

  static double _distance(StrokePoint a, StrokePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static int _lerpTime(int a, int b, double t) {
    final time = a + ((b - a) * t).round();
    if (b >= a) {
      if (time < a) return a;
      if (time > b) return b;
    }
    return time;
  }
}

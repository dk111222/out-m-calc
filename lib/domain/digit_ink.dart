import 'dart:math' as math;
import 'dart:typed_data';

import 'core.dart';

/// One sample from a finger stroke, in the pad's own coordinates.
class InkPoint {
  const InkPoint(this.x, this.y);

  final double x;
  final double y;
}

enum InkKind { digit, dot, minus, slash }

/// One piece of a written answer, in reading order.
class InkGlyph {
  const InkGlyph({required this.strokes, required this.kind, required this.x});

  final List<List<InkPoint>> strokes;
  final InkKind kind;
  final double x;
}

/// Bundled 28×28 digit classifier. Weights ship inside the app.
class DigitNet {
  DigitNet._({
    required this.hidden,
    required this.w1,
    required this.b1,
    required this.w2,
    required this.b2,
  });

  final int hidden;
  final Float32List w1;
  final Float32List b1;
  final Float32List w2;
  final Float32List b2;

  static const side = 28;
  static const input = side * side;

  factory DigitNet.fromBytes(Uint8List bytes) {
    if (bytes.length < 12) {
      throw const FormatException('digit model');
    }
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic != 'DGT1') throw const FormatException('digit model');
    final data = ByteData.sublistView(bytes);
    final hidden = data.getUint16(4, Endian.little);
    final width = data.getUint16(6, Endian.little);
    final outputs = data.getUint16(8, Endian.little);
    if (hidden <= 0 || width != input || outputs != 10) {
      throw const FormatException('digit model');
    }
    final count = hidden * width + hidden + outputs * hidden + outputs;
    if (bytes.length < 12 + count * 4) {
      throw const FormatException('digit model');
    }
    final weights = Float32List(count);
    for (var i = 0; i < count; i++) {
      weights[i] = data.getFloat32(12 + i * 4, Endian.little);
    }
    var cursor = 0;
    Float32List take(int n) {
      final part = Float32List.sublistView(weights, cursor, cursor + n);
      cursor += n;
      return part;
    }

    return DigitNet._(
      hidden: hidden,
      w1: take(hidden * width),
      b1: take(hidden),
      w2: take(outputs * hidden),
      b2: take(outputs),
    );
  }

  DigitScore classify(Float32List image) {
    final activated = Float32List(hidden);
    for (var unit = 0; unit < hidden; unit++) {
      var sum = b1[unit];
      final row = unit * input;
      for (var pixel = 0; pixel < input; pixel++) {
        sum += w1[row + pixel] * image[pixel];
      }
      activated[unit] = sum > 0 ? sum : 0;
    }
    final logits = Float32List(10);
    var peak = -double.infinity;
    for (var digit = 0; digit < 10; digit++) {
      var sum = b2[digit];
      final row = digit * hidden;
      for (var unit = 0; unit < hidden; unit++) {
        sum += w2[row + unit] * activated[unit];
      }
      logits[digit] = sum;
      if (sum > peak) peak = sum;
    }
    var total = 0.0;
    final probs = Float32List(10);
    for (var digit = 0; digit < 10; digit++) {
      final value = math.exp(logits[digit] - peak);
      probs[digit] = value;
      total += value;
    }
    var best = 0;
    for (var digit = 1; digit < 10; digit++) {
      if (probs[digit] > probs[best]) best = digit;
    }
    return DigitScore(best, probs[best] / total);
  }
}

class DigitScore {
  const DigitScore(this.digit, this.probability);

  final int digit;
  final double probability;
}

const _content = 20;
const _brush = 1.35;
const _step = 0.4;

/// Splits writing into digits, a minus, a decimal point, or a fraction bar.
List<InkGlyph> segmentInk(List<List<InkPoint>> strokes) {
  final usable = <_Mark>[];
  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    usable.add(_Mark(stroke, _bounds(stroke)));
  }
  if (usable.isEmpty) return const [];
  final maxHeight = usable.map((mark) => mark.box.height).reduce(math.max);
  final tall = usable.where((mark) => mark.box.height >= maxHeight * 0.5);
  final scaleFrom = tall.isEmpty ? usable : tall.toList();
  final medianHeight = math.max(
    _median(scaleFrom.map((mark) => mark.box.height)),
    1.0,
  );
  final dotLimit = medianHeight * 0.38;
  final dots = <_Mark>[];
  final body = <_Mark>[];
  for (final mark in usable) {
    final small = mark.box.width <= dotLimit && mark.box.height <= dotLimit;
    if (small) {
      dots.add(mark);
    } else {
      body.add(mark);
    }
  }
  if (body.isEmpty) return const [];
  final symbols = <_Mark>[];
  final letters = <_Mark>[];
  for (final mark in body) {
    final overlaps = body.any(
      (other) =>
          !identical(other, mark) &&
          other.box.left < mark.box.right &&
          mark.box.left < other.box.right,
    );
    if (!overlaps &&
        (_flat(mark, medianHeight) || _slash(mark, medianHeight))) {
      symbols.add(mark);
    } else {
      letters.add(mark);
    }
  }
  final gapLimit = medianHeight * 0.22;
  final glyphs = <InkGlyph>[];
  final digitBoxes = <_Box>[];
  for (final mark in symbols) {
    final kind = _flat(mark, medianHeight) ? InkKind.minus : InkKind.slash;
    glyphs.add(
      InkGlyph(strokes: [mark.points], kind: kind, x: mark.box.centerX),
    );
  }
  for (final cluster in _cluster(letters, gapLimit)) {
    _emitCluster(cluster, glyphs, digitBoxes, medianHeight, gapLimit);
  }
  if (digitBoxes.isEmpty && glyphs.isEmpty) return const [];
  final lineTop = body.map((mark) => mark.box.top).reduce(math.min);
  final lineBottom = body.map((mark) => mark.box.bottom).reduce(math.max);
  final baseline = lineTop + (lineBottom - lineTop) * 0.55;
  for (final dot in dots) {
    final inside = digitBoxes.any(
      (box) => dot.box.centerX >= box.left && dot.box.centerX <= box.right,
    );
    if (inside || dot.box.centerY < baseline) continue;
    glyphs.add(
      InkGlyph(strokes: [dot.points], kind: InkKind.dot, x: dot.box.centerX),
    );
  }
  glyphs.sort((a, b) => a.x.compareTo(b.x));
  return glyphs;
}

List<List<_Mark>> _cluster(List<_Mark> marks, double gapLimit) {
  if (marks.isEmpty) return const [];
  final sorted = [...marks]..sort((a, b) => a.box.left.compareTo(b.box.left));
  final clusters = <List<_Mark>>[];
  var current = <_Mark>[sorted.first];
  var right = sorted.first.box.right;
  for (final mark in sorted.skip(1)) {
    if (mark.box.left <= right + gapLimit) {
      current.add(mark);
      if (mark.box.right > right) right = mark.box.right;
    } else {
      clusters.add(current);
      current = [mark];
      right = mark.box.right;
    }
  }
  clusters.add(current);
  return clusters;
}

void _emitCluster(
  List<_Mark> cluster,
  List<InkGlyph> glyphs,
  List<_Box> digitBoxes,
  double medianHeight,
  double gapLimit,
) {
  final flat = cluster.where((mark) => _flat(mark, medianHeight)).toList();
  if (flat.length == 1) {
    final bar = flat.first;
    final others = cluster.where((mark) => !identical(mark, bar));
    final crosses = others.any(
      (mark) =>
          mark.box.bottom >= bar.box.top && mark.box.top <= bar.box.bottom,
    );
    final above = others
        .where((mark) => mark.box.bottom < bar.box.top)
        .toList();
    final below = others
        .where((mark) => mark.box.top > bar.box.bottom)
        .toList();
    if (!crosses && above.isNotEmpty && below.isNotEmpty) {
      final x = _union([bar]).centerX;
      _emitDigits(above, glyphs, digitBoxes, gapLimit, x, before: true);
      glyphs.add(InkGlyph(strokes: [bar.points], kind: InkKind.slash, x: x));
      _emitDigits(below, glyphs, digitBoxes, gapLimit, x, before: false);
      return;
    }
  }
  if (cluster.length == 1) {
    final mark = cluster.first;
    final box = mark.box;
    if (_flat(mark, medianHeight)) {
      glyphs.add(
        InkGlyph(strokes: [mark.points], kind: InkKind.minus, x: box.centerX),
      );
      return;
    }
    if (_slash(mark, medianHeight)) {
      glyphs.add(
        InkGlyph(strokes: [mark.points], kind: InkKind.slash, x: box.centerX),
      );
      return;
    }
  }
  final box = _union(cluster);
  digitBoxes.add(box);
  glyphs.add(
    InkGlyph(
      strokes: [for (final mark in cluster) mark.points],
      kind: InkKind.digit,
      x: box.centerX,
    ),
  );
}

void _emitDigits(
  List<_Mark> marks,
  List<InkGlyph> glyphs,
  List<_Box> digitBoxes,
  double gapLimit,
  double anchor, {
  required bool before,
}) {
  final clusters = _cluster(marks, gapLimit);
  for (var i = 0; i < clusters.length; i++) {
    final box = _union(clusters[i]);
    digitBoxes.add(box);
    final slot = before ? clusters.length - i : i + 1;
    glyphs.add(
      InkGlyph(
        strokes: [for (final mark in clusters[i]) mark.points],
        kind: InkKind.digit,
        x: before ? anchor - slot * 0.01 : anchor + slot * 0.01,
      ),
    );
  }
}

bool _flat(_Mark mark, double medianHeight) {
  final box = mark.box;
  return _straight(mark.points) &&
      box.height <= medianHeight * 0.42 &&
      box.width >= box.height * 1.8 &&
      box.width >= medianHeight * 0.35;
}

bool _slash(_Mark mark, double medianHeight) {
  final box = mark.box;
  if (box.height < medianHeight * 0.55) return false;
  final ratio = box.width / math.max(box.height, 1e-3);
  return ratio >= 0.4 && ratio <= 1.45 && _straight(mark.points);
}

bool _straight(List<InkPoint> points) {
  if (points.length < 2) return false;
  final start = points.first;
  final end = points.last;
  final dx = end.x - start.x;
  final dy = end.y - start.y;
  final chord = math.sqrt(dx * dx + dy * dy);
  if (chord < 1) return false;
  var length = 0.0;
  var off = 0.0;
  for (var i = 1; i < points.length; i++) {
    final sx = points[i].x - points[i - 1].x;
    final sy = points[i].y - points[i - 1].y;
    length += math.sqrt(sx * sx + sy * sy);
    final dist =
        ((points[i].x - start.x) * dy - (points[i].y - start.y) * dx).abs() /
        chord;
    if (dist > off) off = dist;
  }
  return length <= chord * 1.45 && off <= chord * 0.22;
}

/// Draws one glyph the same way the bundled model was trained.
Float32List rasterizeGlyph(List<List<InkPoint>> strokes) {
  final points = [for (final stroke in strokes) ...stroke];
  final image = Float32List(DigitNet.input);
  if (points.length < 2) return image;
  final box = _bounds(points);
  final width = math.max(box.width, 1e-3);
  final height = math.max(box.height, 1e-3);
  final scale = _content / math.max(width, height);
  final ox = (DigitNet.side - width * scale) / 2;
  final oy = (DigitNet.side - height * scale) / 2;
  final mapped = <List<InkPoint>>[];
  for (final stroke in strokes) {
    if (stroke.length < 2) continue;
    mapped.add([
      for (final point in stroke)
        InkPoint(
          (point.x - box.left) * scale + ox,
          (point.y - box.top) * scale + oy,
        ),
    ]);
  }
  for (final stroke in mapped) {
    for (var i = 1; i < stroke.length; i++) {
      _paint(image, stroke[i - 1].x, stroke[i - 1].y, stroke[i].x, stroke[i].y);
    }
  }
  return _centerMass(image);
}

/// Reads a small integer, a negative, a decimal, or a fraction.
///
/// A doubtful digit becomes null. The minus, dot, and fraction bar are
/// read from the stroke shape. Digits go through the bundled model.
String? recognizeInk(List<List<InkPoint>> strokes, DigitNet net) {
  final glyphs = segmentInk(strokes);
  if (glyphs.isEmpty || glyphs.length > 8) return null;
  final buffer = StringBuffer();
  for (final glyph in glyphs) {
    switch (glyph.kind) {
      case InkKind.dot:
        buffer.write('.');
      case InkKind.minus:
        buffer.write('-');
      case InkKind.slash:
        buffer.write('/');
      case InkKind.digit:
        final score = net.classify(rasterizeGlyph(glyph.strokes));
        if (score.probability < 0.5) return null;
        buffer.write(score.digit);
    }
  }
  final answer = readHandAnswer(buffer.toString());
  if (answer.isEmpty || !legalDraft(answer)) return null;
  return answer;
}

class _Box {
  const _Box(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;
}

class _Mark {
  const _Mark(this.points, this.box);

  final List<InkPoint> points;
  final _Box box;
}

_Box _bounds(List<InkPoint> points) {
  var left = points.first.x;
  var right = left;
  var top = points.first.y;
  var bottom = top;
  for (final point in points.skip(1)) {
    if (point.x < left) left = point.x;
    if (point.x > right) right = point.x;
    if (point.y < top) top = point.y;
    if (point.y > bottom) bottom = point.y;
  }
  return _Box(left, top, right, bottom);
}

_Box _union(List<_Mark> marks) {
  var box = marks.first.box;
  for (final mark in marks.skip(1)) {
    box = _Box(
      math.min(box.left, mark.box.left),
      math.min(box.top, mark.box.top),
      math.max(box.right, mark.box.right),
      math.max(box.bottom, mark.box.bottom),
    );
  }
  return box;
}

double _median(Iterable<double> values) {
  final sorted = values.toList()..sort();
  final mid = sorted.length ~/ 2;
  if (sorted.length.isOdd) return sorted[mid];
  return (sorted[mid - 1] + sorted[mid]) / 2;
}

void _paint(Float32List image, double x0, double y0, double x1, double y1) {
  final dist = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
  final steps = math.max(1, (dist / _step).ceil());
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    _stamp(image, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t);
  }
}

void _stamp(Float32List image, double x, double y) {
  final x0 = (x - _brush).floor();
  final x1 = (x + _brush).ceil();
  final y0 = (y - _brush).floor();
  final y1 = (y + _brush).ceil();
  for (var py = y0; py <= y1; py++) {
    for (var px = x0; px <= x1; px++) {
      if (px < 0 || py < 0 || px >= DigitNet.side || py >= DigitNet.side) {
        continue;
      }
      final dx = px + 0.5 - x;
      final dy = py + 0.5 - y;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > _brush) continue;
      final value = 1.0 - 0.25 * (dist / _brush);
      final index = py * DigitNet.side + px;
      if (value > image[index]) image[index] = value;
    }
  }
}

Float32List _centerMass(Float32List image) {
  var mass = 0.0;
  var cx = 0.0;
  var cy = 0.0;
  for (var y = 0; y < DigitNet.side; y++) {
    for (var x = 0; x < DigitNet.side; x++) {
      final value = image[y * DigitNet.side + x];
      mass += value;
      cx += value * x;
      cy += value * y;
    }
  }
  if (mass < 1) return image;
  cx /= mass;
  cy /= mass;
  final dx = (13.5 - cx).round();
  final dy = (13.5 - cy).round();
  if (dx == 0 && dy == 0) return image;
  final shifted = Float32List(DigitNet.input);
  for (var y = 0; y < DigitNet.side; y++) {
    for (var x = 0; x < DigitNet.side; x++) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= DigitNet.side || ny >= DigitNet.side) {
        continue;
      }
      shifted[ny * DigitNet.side + nx] = image[y * DigitNet.side + x];
    }
  }
  return shifted;
}

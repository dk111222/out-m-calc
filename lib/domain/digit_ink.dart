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
  // A gap this small still separates two digits. Strokes of one digit
  // overlap, so they stay together.
  final gapLimit = medianHeight * 0.08;
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
  final split = <InkGlyph>[];
  for (final glyph in glyphs) {
    if (glyph.kind == InkKind.digit) {
      split.addAll(_splitWide(glyph));
    } else {
      split.add(glyph);
    }
  }
  split.sort((a, b) => a.x.compareTo(b.x));
  return split;
}

/// Breaks a wide glyph where the ink itself has a vertical gap, such as
/// "10" written close together. A stroke that crosses the gap, such as the
/// bar of a 4, keeps the glyph whole.
List<InkGlyph> _splitWide(InkGlyph glyph) {
  final strokes = glyph.strokes;
  final points = [for (final stroke in strokes) ...stroke];
  if (points.length < 4 || strokes.isEmpty) return [glyph];
  final box = _bounds(points);
  // A lone 1 is narrower than this. Two digits side by side are not.
  if (box.width < box.height * 0.45) return [glyph];
  final gapMin = math.max(box.height * 0.08, 3.0);
  final span = _widestEmptySpan(strokes, box, gapMin);
  if (span == null) return [glyph];
  final leftStrokes = <List<InkPoint>>[];
  final rightStrokes = <List<InkPoint>>[];
  for (final stroke in strokes) {
    final onLeft = stroke.any((point) => point.x < span.$1);
    final onRight = stroke.any((point) => point.x > span.$2);
    if (onLeft && onRight) return [glyph];
    if (onLeft) leftStrokes.add(stroke);
    if (onRight) rightStrokes.add(stroke);
  }
  if (leftStrokes.isEmpty || rightStrokes.isEmpty) return [glyph];
  InkGlyph side(List<List<InkPoint>> part) {
    final bounds = _bounds([for (final stroke in part) ...stroke]);
    return InkGlyph(strokes: part, kind: InkKind.digit, x: bounds.centerX);
  }

  final leftBox = _bounds([for (final stroke in leftStrokes) ...stroke]);
  final rightBox = _bounds([for (final stroke in rightStrokes) ...stroke]);
  if (leftBox.height < box.height * 0.45 ||
      rightBox.height < box.height * 0.45) {
    return [glyph];
  }
  return [..._splitWide(side(leftStrokes)), ..._splitWide(side(rightStrokes))];
}

/// Widest vertical band inside the ink that no stroke crosses.
(double, double)? _widestEmptySpan(
  List<List<InkPoint>> strokes,
  _Box box,
  double gapMin,
) {
  final occupied = <(double, double)>[];
  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length == 1) {
      occupied.add((stroke.first.x, stroke.first.x));
      continue;
    }
    for (var i = 1; i < stroke.length; i++) {
      final previous = stroke[i - 1].x;
      final next = stroke[i].x;
      occupied.add((math.min(previous, next), math.max(previous, next)));
    }
  }
  if (occupied.isEmpty) return null;
  occupied.sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(double, double)>[occupied.first];
  for (final interval in occupied.skip(1)) {
    final last = merged.last;
    if (interval.$1 <= last.$2 + 0.5) {
      if (interval.$2 > last.$2)
        merged[merged.length - 1] = (last.$1, interval.$2);
    } else {
      merged.add(interval);
    }
  }
  double? bestLeft;
  double? bestRight;
  var best = 0.0;
  for (var i = 0; i < merged.length - 1; i++) {
    final left = merged[i].$2;
    final right = merged[i + 1].$1;
    final width = right - left;
    if (width > best && left > box.left + 1 && right < box.right - 1) {
      best = width;
      bestLeft = left;
      bestRight = right;
    }
  }
  if (best < gapMin || bestLeft == null || bestRight == null) return null;
  return (bestLeft, bestRight);
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
      box.width >= medianHeight * 0.25;
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
  // Finger strokes are thinner than the digits this model learned. One
  // pixel of thickening makes a written 3 or 8 look like those samples.
  return _centerMass(_thicken(image));
}

Float32List _thicken(Float32List image) {
  final source = Float32List.fromList(image);
  for (var y = 0; y < DigitNet.side; y++) {
    for (var x = 0; x < DigitNet.side; x++) {
      var value = source[y * DigitNet.side + x];
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= DigitNet.side || ny >= DigitNet.side) {
            continue;
          }
          final neighbor = source[ny * DigitNet.side + nx];
          if (neighbor > value) value = neighbor;
        }
      }
      image[y * DigitNet.side + x] = value;
    }
  }
  return image;
}

/// Reads an integer, a negative, a decimal, or a fraction from the pad.
///
/// This follows an offline handwriting input: each span of strokes is a
/// character candidate, and a search keeps only the path that is a legal
/// number. The minus, decimal point, and fraction bar come from the stroke
/// shape. Digits go through the bundled model.
String? recognizeInk(List<List<InkPoint>> strokes, DigitNet net) {
  return decodeInk(strokes, (image) => net.classify(image));
}

enum _Slot { start, signed, whole, dotted, decimal, slashed, denom }

class _Hyp {
  const _Hyp(this.char, this.logp);

  final String char;
  final double logp;
}

class _Move {
  const _Move(this.slot, this.text);

  final _Slot slot;
  final String text;
}

class _Best {
  const _Best(this.score, this.text);

  final double score;
  final String text;
}

class _Atom {
  _Atom(this.points, this.box);

  final List<InkPoint> points;
  final _Box box;
  bool bar = false;
}

class _Block {
  _Block(this.atoms, this.x);

  final List<_Atom> atoms;
  final double x;
}

/// Best legal number over a lattice of stroke spans.
///
/// [readDigit] scores one raster the way [DigitNet.classify] does. A result
/// is returned only when the winning path is a complete integer, negative,
/// decimal, or fraction.
String? decodeInk(
  List<List<InkPoint>> strokes,
  DigitScore Function(Float32List image) readDigit,
) {
  final seq = _readingOrder(strokes);
  if (seq.isEmpty || seq.length > 32) return null;
  final median = _inkMedian(seq);
  final body = seq.where((atom) => !_isDot(atom, median));
  final line = body.isEmpty ? seq : body.toList();
  final lineTop = line.map((atom) => atom.box.top).reduce(math.min);
  final lineBottom = line.map((atom) => atom.box.bottom).reduce(math.max);
  final baseline = lineTop + (lineBottom - lineTop) * 0.55;
  final n = seq.length;
  final best = List.generate(n + 1, (_) => <_Slot, _Best>{});
  best[0][_Slot.start] = const _Best(0, '');
  for (var i = 0; i < n; i++) {
    final here = best[i];
    if (here.isEmpty) continue;
    final atom = seq[i];
    if (_isDot(atom, median) && atom.box.centerY < baseline) {
      _skip(here, best[i + 1]);
    }
    final last = math.min(n, i + 5);
    for (var j = i + 1; j <= last; j++) {
      final hyps = _hypotheses(seq.sublist(i, j), median, baseline, readDigit);
      if (hyps.isEmpty) continue;
      for (final entry in here.entries) {
        for (final hyp in hyps) {
          final move = _advance(entry.key, hyp.char, entry.value.text);
          if (move == null || move.text.length > 8) continue;
          final score = entry.value.score + hyp.logp;
          final prior = best[j][move.slot];
          if (prior == null || score > prior.score) {
            best[j][move.slot] = _Best(score, move.text);
          }
        }
      }
    }
  }
  _Best? winner;
  for (final slot in const [_Slot.whole, _Slot.decimal, _Slot.denom]) {
    final item = best[n][slot];
    if (item == null) continue;
    if (winner == null || item.score > winner.score) winner = item;
  }
  if (winner == null) return null;
  final answer = readHandAnswer(winner.text);
  if (answer.isEmpty || !legalDraft(answer)) return null;
  return answer;
}

void _skip(Map<_Slot, _Best> from, Map<_Slot, _Best> to) {
  const penalty = -1.6;
  for (final entry in from.entries) {
    final score = entry.value.score + penalty;
    final prior = to[entry.key];
    if (prior == null || score > prior.score) {
      to[entry.key] = _Best(score, entry.value.text);
    }
  }
}

_Move? _advance(_Slot slot, String char, String text) {
  final digit = char.length == 1 && _isDigitChar(char);
  switch (slot) {
    case _Slot.start:
      if (char == '-') return _Move(_Slot.signed, '-');
      if (char == '.') return const _Move(_Slot.dotted, '0.');
      if (digit) return _Move(_Slot.whole, char);
      return null;
    case _Slot.signed:
      if (char == '.') return const _Move(_Slot.dotted, '-0.');
      if (digit) return _Move(_Slot.whole, '$text$char');
      return null;
    case _Slot.whole:
      if (digit) return _Move(_Slot.whole, '$text$char');
      if (char == '.') return _Move(_Slot.dotted, '$text.');
      if (char == '/') return _Move(_Slot.slashed, '$text/');
      return null;
    case _Slot.dotted:
      if (digit) return _Move(_Slot.decimal, '$text$char');
      return null;
    case _Slot.decimal:
      if (digit) return _Move(_Slot.decimal, '$text$char');
      return null;
    case _Slot.slashed:
      if (digit) return _Move(_Slot.denom, '$text$char');
      return null;
    case _Slot.denom:
      if (digit) return _Move(_Slot.denom, '$text$char');
      return null;
  }
}

bool _isDigitChar(String char) {
  final code = char.codeUnitAt(0);
  return code >= 48 && code <= 57;
}

List<_Hyp> _hypotheses(
  List<_Atom> span,
  double median,
  double baseline,
  DigitScore Function(Float32List image) readDigit,
) {
  final hyps = <_Hyp>[];
  if (span.length == 1) {
    final atom = span.first;
    final mark = _Mark(atom.points, atom.box);
    if (_isDot(atom, median)) {
      if (atom.box.centerY >= baseline) hyps.add(_Hyp('.', math.log(0.99)));
      return hyps;
    }
    if (atom.bar) {
      hyps.add(_Hyp('/', math.log(0.99)));
      return hyps;
    }
    if (_flat(mark, median)) {
      hyps.add(_Hyp('-', math.log(0.99)));
      return hyps;
    }
    if (_slash(mark, median)) {
      hyps.add(_Hyp('/', math.log(0.99)));
      return hyps;
    }
  } else if (span.any((atom) => atom.bar || _isDot(atom, median))) {
    return hyps;
  }
  if (_looseSymbol(span, median)) return hyps;
  final strokes = [for (final atom in span) atom.points];
  if (_spanSplits(strokes)) return hyps;
  var points = 0;
  for (final stroke in strokes) {
    points += stroke.length;
  }
  if (points < 2) return hyps;
  final score = readDigit(rasterizeGlyph(strokes));
  if (score.probability >= 0.5) {
    hyps.add(_Hyp('${score.digit}', math.log(score.probability)));
  }
  return hyps;
}

List<_Atom> _readingOrder(List<List<InkPoint>> strokes) {
  final atoms = <_Atom>[];
  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    atoms.add(_Atom(stroke, _bounds(stroke)));
  }
  if (atoms.isEmpty) return atoms;
  final median = _inkMedian(atoms);
  final bars = <_Atom>[];
  for (final atom in atoms) {
    if (_fractionBar(atom, atoms, median)) {
      atom.bar = true;
      bars.add(atom);
    }
  }
  final used = <_Atom>{};
  final blocks = <_Block>[];
  for (final bar in bars) {
    final above = <_Atom>[];
    final below = <_Atom>[];
    for (final other in atoms) {
      if (identical(other, bar) || other.bar || used.contains(other)) continue;
      if (!_overlapsX(other.box, bar.box)) continue;
      if (other.box.bottom < bar.box.top) {
        above.add(other);
      } else if (other.box.top > bar.box.bottom) {
        below.add(other);
      }
    }
    above.sort((a, b) => a.box.centerX.compareTo(b.box.centerX));
    below.sort((a, b) => a.box.centerX.compareTo(b.box.centerX));
    used.add(bar);
    used.addAll(above);
    used.addAll(below);
    blocks.add(_Block([...above, bar, ...below], bar.box.centerX));
  }
  for (final atom in atoms) {
    if (used.contains(atom)) continue;
    blocks.add(_Block([atom], atom.box.centerX));
  }
  blocks.sort((a, b) => a.x.compareTo(b.x));
  return [for (final block in blocks) ...block.atoms];
}

bool _fractionBar(_Atom atom, List<_Atom> atoms, double median) {
  if (!_flat(_Mark(atom.points, atom.box), median)) return false;
  var above = false;
  var below = false;
  var crosses = false;
  for (final other in atoms) {
    if (identical(other, atom)) continue;
    if (!_overlapsX(atom.box, other.box)) continue;
    if (other.box.bottom >= atom.box.top && other.box.top <= atom.box.bottom) {
      crosses = true;
    } else if (other.box.bottom < atom.box.top) {
      above = true;
    } else if (other.box.top > atom.box.bottom) {
      below = true;
    }
  }
  return !crosses && above && below;
}

/// A flat or diagonal stroke that does not touch the rest of the span is a
/// separate minus or fraction bar, not part of a digit.
bool _looseSymbol(List<_Atom> span, double median) {
  if (span.length < 2) return false;
  for (final atom in span) {
    final mark = _Mark(atom.points, atom.box);
    if (!_flat(mark, median) && !_slash(mark, median)) continue;
    final crosses = span.any(
      (other) =>
          !identical(other, atom) &&
          other.box.left < atom.box.right &&
          atom.box.left < other.box.right &&
          other.box.bottom >= atom.box.top &&
          other.box.top <= atom.box.bottom,
    );
    if (!crosses) return true;
  }
  return false;
}

bool _overlapsX(_Box a, _Box b) => a.left < b.right && b.left < a.right;

bool _isDot(_Atom atom, double median) {
  final limit = median * 0.38;
  final box = atom.box;
  if (box.width > limit || box.height > limit) return false;
  // A short horizontal dash is a minus, not a decimal point.
  if (box.width >= box.height * 1.8 && box.width >= median * 0.22) {
    return false;
  }
  return true;
}

double _inkMedian(List<_Atom> atoms) {
  final maxHeight = atoms.map((atom) => atom.box.height).reduce(math.max);
  final tall = atoms.where((atom) => atom.box.height >= maxHeight * 0.5);
  final scaleFrom = tall.isEmpty ? atoms : tall.toList();
  return math.max(_median(scaleFrom.map((atom) => atom.box.height)), 1.0);
}

bool _spanSplits(List<List<InkPoint>> strokes) {
  if (strokes.length < 2) return false;
  final points = [for (final stroke in strokes) ...stroke];
  if (points.length < 4) return false;
  final box = _bounds(points);
  if (box.width < box.height * 0.45) return false;
  final gapMin = math.max(box.height * 0.08, 3.0);
  final gap = _widestEmptySpan(strokes, box, gapMin);
  if (gap == null) return false;
  final leftPoints = <InkPoint>[];
  final rightPoints = <InkPoint>[];
  for (final stroke in strokes) {
    final onLeft = stroke.any((point) => point.x < gap.$1);
    final onRight = stroke.any((point) => point.x > gap.$2);
    if (onLeft && onRight) return false;
    if (onLeft) leftPoints.addAll(stroke);
    if (onRight) rightPoints.addAll(stroke);
  }
  if (leftPoints.isEmpty || rightPoints.isEmpty) return false;
  final left = _bounds(leftPoints);
  final right = _bounds(rightPoints);
  return left.height >= box.height * 0.45 && right.height >= box.height * 0.45;
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

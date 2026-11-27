import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/domain/digit_ink.dart';
import 'package:stepmath/domain/stroke_preprocessor.dart';

void main() {
  List<StrokePoint> line(
    double x0,
    double y0,
    double x1,
    double y1, {
    int count = 24,
    int time = 0,
  }) {
    return [
      for (var i = 0; i < count; i++)
        StrokePoint(
          x0 + (x1 - x0) * i / (count - 1),
          y0 + (y1 - y0) * i / (count - 1),
          time + i * 1000,
        ),
    ];
  }

  ({double width, double height}) bounds(List<List<StrokePoint>> strokes) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final stroke in strokes) {
      for (final point in stroke) {
        minX = min(minX, point.x);
        minY = min(minY, point.y);
        maxX = max(maxX, point.x);
        maxY = max(maxY, point.y);
      }
    }
    return (width: maxX - minX, height: maxY - minY);
  }

  test('drops taps, short specks, and repeated samples', () {
    final tap = [const StrokePoint(4, 4, 1)];
    final twoPointFlick = [
      const StrokePoint(0, 0, 2),
      const StrokePoint(40, 0, 3),
    ];
    final speck = line(10, 10, 12, 11, count: 6, time: 10);
    final resting = [for (var i = 0; i < 8; i++) const StrokePoint(3, 3, 0)];

    expect(
      StrokePreprocessor.process([tap, twoPointFlick, speck, resting]),
      isEmpty,
    );
  });

  test('thins a slow stroke and fills a fast one to the same spacing', () {
    final slow = [
      for (var i = 0; i <= 400; i++) StrokePoint(i * 0.25, 20, i * 1000),
    ];
    final fast = [
      const StrokePoint(0, 0, 0),
      const StrokePoint(50, 0, 4000),
      const StrokePoint(100, 0, 8000),
    ];

    final slowOut = StrokePreprocessor.process([slow]).single;
    final fastOut = StrokePreprocessor.process([fast]).single;

    expect(slow.length, 401);
    expect(slowOut.length, lessThan(40));
    expect(fastOut.length, greaterThan(fast.length));
    expect(slowOut.length, closeTo(fastOut.length, 2));
  });

  test('smooths jitter without moving the ends of a fraction bar', () {
    final bar = <StrokePoint>[
      for (var i = 0; i <= 20; i++)
        StrokePoint(i * 4.0, i.isEven ? 40 : 48, i * 1000),
    ];
    final out = StrokePreprocessor.process([bar]).single;
    final rawRatio = bounds([bar]).height / bounds([bar]).width;
    final cleaned = bounds([out]);

    expect(out.first.timestamp, bar.first.timestamp);
    expect(out.last.timestamp, lessThanOrEqualTo(bar.last.timestamp));
    expect(cleaned.height / cleaned.width, lessThan(rawRatio));
    for (var i = 1; i < out.length; i++) {
      expect(out[i].timestamp, greaterThanOrEqualTo(out[i - 1].timestamp));
    }
  });

  test('fits the expression in the square and keeps its aspect ratio', () {
    final wide = line(500, 800, 700, 840, count: 30);
    final out = StrokePreprocessor.process([wide]);
    final box = bounds(out);

    expect(box.width / box.height, closeTo(200 / 40, 0.05));
    for (final stroke in out) {
      for (final point in stroke) {
        expect(point.x, inInclusiveRange(StrokePreprocessor.padding, 210));
        expect(point.y, inInclusiveRange(StrokePreprocessor.padding, 210));
      }
    }
    expect(out.first.first.x, closeTo(StrokePreprocessor.padding, 0.01));
    expect(out.first.last.x, closeTo(210, 0.01));
  });

  test('keeps stroke order and stacks a fraction', () {
    final numerator = line(30, 0, 34, 24, time: 0);
    final bar = line(8, 36, 56, 36, time: 100000);
    final denominator = line(30, 48, 34, 84, time: 200000);
    final out = StrokePreprocessor.process([numerator, bar, denominator]);

    expect(out, hasLength(3));
    double midY(List<StrokePoint> stroke) {
      final ys = [for (final point in stroke) point.y];
      return (ys.reduce(min) + ys.reduce(max)) / 2;
    }

    expect(midY(out[0]), lessThan(midY(out[1])));
    expect(midY(out[1]), lessThan(midY(out[2])));
    expect(out[0].first.timestamp, lessThan(out[1].first.timestamp));
    expect(out[1].first.timestamp, lessThan(out[2].first.timestamp));
  });

  test('does not rewrite the ink the pad is drawing', () {
    final stroke = line(0, 0, 80, 30);
    final before = [
      for (final point in stroke) (point.x, point.y, point.timestamp),
    ];
    StrokePreprocessor.process([stroke]);
    expect([
      for (final point in stroke) (point.x, point.y, point.timestamp),
    ], before);
  });

  test('cleaned ink still reads as an integer, decimal, and fraction', () {
    final net = DigitNet.fromBytes(
      File('assets/models/digits.f32').readAsBytesSync(),
    );
    final zero = [
      for (var i = 0; i <= 40; i++)
        InkPoint(
          50 + 32 * cos(2 * pi * i / 40),
          50 + 42 * sin(2 * pi * i / 40),
        ),
    ];
    final one = [_segment(50, 8, 50, 92), _segment(34, 22, 50, 8)];

    String? read(List<List<InkPoint>> strokes) {
      return recognizeInk(_preprocess(strokes), net);
    }

    expect(read([zero]), '0');
    expect(read(one), '1');
    expect(read([_segment(2, 48, 32, 49), ...one]), '-1');
    expect(
      read([
        ...one,
        [InkPoint(78, 78), InkPoint(82, 82)],
        [for (final point in zero) InkPoint(point.x + 70, point.y)],
      ]),
      '1.0',
    );
    expect(
      read([
        zero,
        _segment(96, 12, 128, 88),
        ...one.map(
          (stroke) => [
            for (final point in stroke) InkPoint(point.x + 110, point.y),
          ],
        ),
      ]),
      '0/1',
    );
    expect(
      read([
        [const InkPoint(1, 1)],
        ...one,
      ]),
      '1',
    );
  });
}

List<InkPoint> _segment(double x0, double y0, double x1, double y1) {
  return [InkPoint(x0, y0), InkPoint(x1, y1)];
}

List<List<InkPoint>> _preprocess(List<List<InkPoint>> strokes) {
  var time = 0;
  final raw = <List<StrokePoint>>[];
  for (final stroke in strokes) {
    if (stroke.length >= 8) {
      raw.add([
        for (var i = 0; i < stroke.length; i++)
          StrokePoint(stroke[i].x, stroke[i].y, time + i * 1000),
      ]);
      time += stroke.length * 1000 + 5000;
      continue;
    }
    final dense = <StrokePoint>[];
    for (var segment = 0; segment < stroke.length - 1; segment++) {
      final start = stroke[segment];
      final end = stroke[segment + 1];
      final first = segment == 0 ? 0 : 1;
      for (var i = first; i <= 16; i++) {
        final t = i / 16;
        dense.add(
          StrokePoint(
            start.x + (end.x - start.x) * t,
            start.y + (end.y - start.y) * t,
            time,
          ),
        );
        time += 1000;
      }
    }
    raw.add(dense);
    time += 5000;
  }
  return [
    for (final stroke in StrokePreprocessor.process(raw))
      [for (final point in stroke) InkPoint(point.x, point.y)],
  ];
}

import 'dart:math';

import 'engine.dart';

class ScannedFact {
  const ScannedFact({
    required this.left,
    required this.right,
    required this.operation,
    required this.written,
    required this.markedWrong,
  });

  final int left;
  final int right;
  final String operation;
  final String? written;
  final bool markedWrong;

  String get prompt {
    switch (operation) {
      case 'subtraction':
        return '$left − $right';
      case 'multiplication':
        return '$left × $right';
      case 'division':
        return '$left ÷ $right';
      default:
        return '$left + $right';
    }
  }

  String get computed {
    switch (operation) {
      case 'subtraction':
        return '${left - right}';
      case 'multiplication':
        return '${left * right}';
      case 'division':
        return '${left ~/ right}';
      default:
        return '${left + right}';
    }
  }

  bool get answerMismatch => written != null && written != computed;

  bool get countedWrong => markedWrong || answerMismatch;
}

class ScanTally {
  const ScanTally(this.counts);

  final Map<String, int> counts;

  int get total => counts.values.fold(0, (sum, count) => sum + count);

  String? get focus {
    String? name;
    var best = 0;
    for (final entry in counts.entries) {
      if (entry.value > best) {
        best = entry.value;
        name = entry.key;
      }
    }
    return name;
  }
}

final _item = RegExp(
  r'(\d+)\s*([+\-−–×xX*÷/])\s*(\d+)(?:\s*=\s*(\d+))?',
);
final _mark = RegExp(r'✗|✘|×|wrong|\bx\b', caseSensitive: false);

class SheetPiece {
  const SheetPiece(this.text, this.left, this.top, this.right, this.bottom);

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

class GradedProblem {
  const GradedProblem({
    required this.fact,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final ScannedFact fact;
  final double left;
  final double top;
  final double right;
  final double bottom;

  bool get correct => fact.written != null && fact.written == fact.computed;

  bool get hasBox => right > left && bottom > top;
}

class _LineFact {
  const _LineFact(this.fact, this.start, this.end);

  final ScannedFact fact;
  final int start;
  final int end;
}

List<ScannedFact> parseWorksheet(String raw) {
  final facts = <ScannedFact>[];
  for (final line in raw.split(RegExp(r'[\r\n]+'))) {
    facts.addAll(_factsOnLine(line).map((item) => item.fact));
  }
  return facts;
}

/// Places each problem on the photo using the recognizer's word boxes.
List<GradedProblem> gradeSheet(
  List<({String text, List<SheetPiece> pieces})> lines,
) {
  final graded = <GradedProblem>[];
  for (final line in lines) {
    final spans = _pieceSpans(line.text, line.pieces);
    for (final item in _factsOnLine(line.text)) {
      final box = _union(spans, item.start, item.end);
      graded.add(
        GradedProblem(
          fact: item.fact,
          left: box.$1,
          top: box.$2,
          right: box.$3,
          bottom: box.$4,
        ),
      );
    }
  }
  return graded;
}

List<_LineFact> _factsOnLine(String line) {
  final facts = <_LineFact>[];
  final matches = _item.allMatches(line).toList();
  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final operation = _operation(match.group(2)!);
    if (operation == null) continue;
    final left = int.parse(match.group(1)!);
    final right = int.parse(match.group(3)!);
    if (operation == 'subtraction' && left < right) continue;
    if (operation == 'division' && (right == 0 || left % right != 0)) {
      continue;
    }
    if (left > 999 || right > 999) continue;
    final end = i + 1 < matches.length ? matches[i + 1].start : line.length;
    final tail = line.substring(match.end, end);
    facts.add(
      _LineFact(
        ScannedFact(
          left: left,
          right: right,
          operation: operation,
          written: match.group(4),
          markedWrong: _mark.hasMatch(tail),
        ),
        match.start,
        match.end,
      ),
    );
  }
  return facts;
}

List<({int start, int end, SheetPiece piece})> _pieceSpans(
  String text,
  List<SheetPiece> pieces,
) {
  var cursor = 0;
  final spans = <({int start, int end, SheetPiece piece})>[];
  for (final piece in pieces) {
    if (piece.text.isEmpty) continue;
    final index = text.indexOf(piece.text, cursor);
    if (index < 0) continue;
    spans.add((start: index, end: index + piece.text.length, piece: piece));
    cursor = index + piece.text.length;
  }
  return spans;
}

(double, double, double, double) _union(
  List<({int start, int end, SheetPiece piece})> spans,
  int start,
  int end,
) {
  final hit = spans.where((span) => span.end > start && span.start < end);
  final boxes = hit.isEmpty ? spans : hit;
  if (boxes.isEmpty) return (0, 0, 0, 0);
  var left = boxes.first.piece.left;
  var top = boxes.first.piece.top;
  var right = boxes.first.piece.right;
  var bottom = boxes.first.piece.bottom;
  for (final span in boxes.skip(1)) {
    final piece = span.piece;
    if (piece.left < left) left = piece.left;
    if (piece.top < top) top = piece.top;
    if (piece.right > right) right = piece.right;
    if (piece.bottom > bottom) bottom = piece.bottom;
  }
  return (left, top, right, bottom);
}

String? _operation(String token) {
  switch (token) {
    case '+':
      return 'addition';
    case '-':
    case '−':
    case '–':
      return 'subtraction';
    case '×':
    case 'x':
    case 'X':
    case '*':
      return 'multiplication';
    case '÷':
    case '/':
      return 'division';
    default:
      return null;
  }
}

ScanTally tallyFacts(Iterable<ScannedFact> facts) {
  final counts = <String, int>{};
  for (final fact in facts) {
    if (!fact.countedWrong) continue;
    counts[fact.operation] = (counts[fact.operation] ?? 0) + 1;
  }
  return ScanTally(counts);
}

List<Problem> targetedProblems(
  List<ScannedFact> selected, {
  required Random rng,
  int count = 5,
}) {
  final wrong = selected.where((fact) => fact.countedWrong).toList();
  final focus = tallyFacts(wrong).focus;
  if (focus == null) return const [];
  final group = wrong.where((fact) => fact.operation == focus).toList();
  var hi = 5;
  for (final fact in group) {
    hi = max(hi, max(fact.left, fact.right));
  }
  hi = min(hi, 100);
  final used = group.map((fact) => fact.prompt).toSet();
  final problems = <Problem>[];
  var guard = 0;
  while (problems.length < count && guard < 40) {
    guard += 1;
    final problem = _like(focus, hi, rng);
    if (used.add(problem.prompt) || guard > 30) problems.add(problem);
  }
  return problems;
}

Problem _like(String operation, int hi, Random rng) {
  switch (operation) {
    case 'subtraction':
      final left = rng.nextInt(hi + 1);
      return speedSub(left, rng.nextInt(left + 1));
    case 'multiplication':
      final left = rng.nextInt(min(hi, 12) + 1);
      final right = rng.nextInt(min(hi, 12) + 1);
      return speedMul(left, right);
    case 'division':
      final right = 1 + rng.nextInt(min(9, max(hi, 1)));
      final quotient = rng.nextInt(min(12, max(hi, 1)) + 1);
      return speedDiv(right * quotient, right);
    default:
      final left = rng.nextInt(hi + 1);
      final room = hi - left;
      return speedAdd(left, room <= 0 ? 0 : rng.nextInt(room + 1));
  }
}

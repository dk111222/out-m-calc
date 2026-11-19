import 'dart:convert';

import 'engine.dart';

class LessonStep {
  const LessonStep(this.number, this.title, this.body);

  final int number;
  final String title;
  final String body;
}

class ExamplePiece {
  const ExamplePiece(this.text, this.step);

  final String text;
  final int step;
}

class ExampleNote {
  const ExampleNote(this.step, this.text);

  final int step;
  final String text;
}

class LessonExample {
  const LessonExample(this.prompt, this.pieces, this.notes);

  final String prompt;
  final List<ExamplePiece> pieces;
  final List<ExampleNote> notes;
}

class Trick {
  const Trick({
    required this.id,
    required this.grade,
    required this.operation,
    required this.title,
    required this.appliesWhen,
    required this.notWhen,
    required this.steps,
    required this.example,
    required this.shortRange,
    required this.standardRange,
    required this.ready,
    required this.blockReason,
  });

  final String id;
  final String grade;
  final String operation;
  final String title;
  final String appliesWhen;
  final String notWhen;
  final List<LessonStep> steps;
  final LessonExample example;
  final String shortRange;
  final String standardRange;
  final bool ready;
  final String? blockReason;
}

class Catalog {
  const Catalog(this.tricks);

  final List<Trick> tricks;

  Trick? byId(String id) {
    for (final trick in tricks) {
      if (trick.id == id) return trick;
    }
    return null;
  }

  List<Trick> forGrade(String grade) =>
      tricks.where((trick) => trick.grade == grade).toList();

  static Catalog parse(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final tricks = (decoded['tricks'] as List).map((entry) {
      final json = entry as Map<String, dynamic>;
      final id = json['id'] as String;
      var ready = json['ready'] as bool? ?? false;
      String? reason;
      final acceptance = json['acceptance'] as List? ?? const [];
      if (acceptance.length < 5) {
        ready = false;
        reason = 'This trick is not ready to practice yet.';
      }
      for (final item in acceptance) {
        final row = item as Map<String, dynamic>;
        final args = (row['args'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as int),
        );
        final built = buildFixed(id, args);
        final expectedSteps = (row['steps'] as List).cast<String>();
        final actual = built.steps.map((step) => step.answer).toList();
        if (actual.join('|') != expectedSteps.join('|') ||
            built.finalAnswer != row['final']) {
          ready = false;
          reason = 'This trick is not ready to practice yet.';
        }
      }
      return Trick(
        id: id,
        grade: json['grade'] as String,
        operation: json['operation'] as String,
        title: json['title'] as String,
        appliesWhen: json['appliesWhen'] as String,
        notWhen: json['notWhen'] as String,
        steps: (json['steps'] as List)
            .map(
              (step) => LessonStep(
                step['n'] as int,
                step['title'] as String,
                step['body'] as String,
              ),
            )
            .toList(),
        example: LessonExample(
          json['example']['prompt'] as String,
          (json['example']['pieces'] as List)
              .map((piece) => ExamplePiece(piece['text'] as String, piece['step'] as int))
              .toList(),
          (json['example']['notes'] as List)
              .map((note) => ExampleNote(note['step'] as int, note['text'] as String))
              .toList(),
        ),
        shortRange: json['shortRange'] as String,
        standardRange: json['standardRange'] as String,
        ready: ready,
        blockReason: reason,
      );
    }).toList();
    return Catalog(tricks);
  }
}

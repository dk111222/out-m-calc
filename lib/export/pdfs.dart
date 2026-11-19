import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/catalog.dart';
import '../domain/engine.dart';

Future<Uint8List> buildWorksheet({
  required Trick trick,
  required List<Problem> problems,
  required ByteData regular,
  required ByteData bold,
}) async {
  if (problems.length != 20 ||
      problems.any((problem) => problem.trickId != trick.id)) {
    throw ArgumentError('A worksheet is one trick and 20 problems.');
  }
  final base = pw.Font.ttf(regular);
  final strong = pw.Font.ttf(bold);
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      theme: pw.ThemeData.withFont(base: base, bold: strong),
      build: (context) => [
        pw.Text(trick.title, style: pw.TextStyle(font: strong, fontSize: 22)),
        pw.SizedBox(height: 8),
        pw.Text('Use this when', style: pw.TextStyle(font: strong)),
        pw.Text(trick.appliesWhen),
        pw.SizedBox(height: 6),
        pw.Text('Not for', style: pw.TextStyle(font: strong)),
        pw.Text(trick.notWhen),
        pw.SizedBox(height: 10),
        pw.Text('Steps', style: pw.TextStyle(font: strong, fontSize: 16)),
        ...trick.steps.map(
          (step) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${step.number}. ${step.title}. ${step.body}'),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Problems', style: pw.TextStyle(font: strong, fontSize: 16)),
        ...List.generate(
          problems.length,
          (index) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text('${index + 1}. ${problems[index].prompt}'),
          ),
        ),
      ],
    ),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      theme: pw.ThemeData.withFont(base: base, bold: strong),
      build: (context) => [
        pw.Text('Answers', style: pw.TextStyle(font: strong, fontSize: 18)),
        pw.SizedBox(height: 8),
        ...List.generate(problems.length, (index) {
          final problem = problems[index];
          final steps = problem.steps
              .map((step) => '${step.number}. ${step.answer}')
              .join('   ');
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              '${index + 1}. ${problem.prompt} = ${problem.finalAnswer}\n$steps',
            ),
          );
        }),
      ],
    ),
  );
  return doc.save();
}

Future<Uint8List> buildCertificate({
  required String learnerName,
  required String title,
  required String dateLabel,
  required ByteData regular,
  required ByteData bold,
}) async {
  final base = pw.Font.ttf(regular);
  final strong = pw.Font.ttf(bold);
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter.landscape,
      theme: pw.ThemeData.withFont(base: base, bold: strong),
      build: (context) => pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(32),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 2),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'Certificate',
                style: pw.TextStyle(font: strong, fontSize: 28),
              ),
              pw.SizedBox(height: 16),
              pw.Text(learnerName, style: pw.TextStyle(font: strong, fontSize: 22)),
              pw.SizedBox(height: 12),
              pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 12),
              pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}

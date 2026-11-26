import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/engine.dart';
import '../domain/machines.dart';
import '../domain/scan.dart';
import '../l10n/copy.dart';
import '../ui/kit.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _picker = ImagePicker();
  String? _photoPath;
  int _imageWidth = 0;
  int _imageHeight = 0;
  List<GradedProblem> _grades = const [];
  List<bool> _checked = const [];
  bool _busy = false;
  String? _error;

  List<ScannedFact> get _facts =>
      _grades.map((grade) => grade.fact).toList();

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final recognized = await _read(file.path);
      final bytes = await File(file.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();
      final grades = gradeSheet([
        for (final block in recognized.blocks)
          for (final line in block.lines)
            (
              text: line.text,
              pieces: [
                for (final element in line.elements)
                  SheetPiece(
                    element.text,
                    element.boundingBox.left,
                    element.boundingBox.top,
                    element.boundingBox.right,
                    element.boundingBox.bottom,
                  ),
              ],
            ),
      ]);
      if (!mounted) return;
      setState(() {
        _photoPath = file.path;
        _imageWidth = width;
        _imageHeight = height;
        _grades = grades;
        _checked = grades.map((grade) => grade.fact.countedWrong).toList();
        _busy = false;
        _error = grades.isEmpty
            ? 'Nothing to read. Use a printed page with problems like 8 + 7.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not read that photo. Try a brighter picture.';
      });
    }
  }

  Future<RecognizedText> _read(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return recognizer.processImage(InputImage.fromFilePath(path));
    } finally {
      await recognizer.close();
    }
  }

  List<ScannedFact> get _selected {
    final chosen = <ScannedFact>[];
    for (var i = 0; i < _facts.length; i++) {
      if (_checked[i]) {
        final fact = _facts[i];
        chosen.add(
          ScannedFact(
            left: fact.left,
            right: fact.right,
            operation: fact.operation,
            written: fact.written,
            markedWrong: true,
          ),
        );
      }
    }
    return chosen;
  }

  Future<void> _practice() async {
    final selected = _selected;
    if (selected.isEmpty) return;
    setState(() => _busy = true);
    final app = ref.read(appProvider);
    try {
      for (final fact in selected) {
        await app.recordAttempt(
          AttemptDraft(
            trickId: 'scan:${fact.operation}',
            prompt: fact.prompt,
            userAnswer: fact.written ?? '',
            correctAnswer: fact.computed,
            correct: false,
            failedStep: null,
            mode: 'scan',
            steps: [
              StepAsk(1, 'What is ${fact.prompt}?', fact.computed),
            ],
            reviewSlot: null,
            repairWrongId: null,
          ),
        );
      }
      final drill = targetedProblems(selected, rng: Random());
      await ref.read(practiceProvider).startScanDrill(drill);
      if (!mounted) return;
      final view = ref.read(practiceProvider).view;
      if (view == null) {
        setState(() => _busy = false);
        return;
      }
      context.go('/practice/${view.trickId}/${view.phase}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = Copy.of(context).couldNotSave;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final tally = tallyFacts(_selected);
    return PageFrame(
      title: t.scanPaper,
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.pick(
              '拍一张印好的练习页。识别只在这台设备上进行。照片上，做对的题打对号，做错的题用红色写出正确答案。写错的题会先勾上，你也可以改，再按勾选的运算练五题。',
              'Photograph a printed page. Reading stays on this device. A right answer gets a check on the photo. A wrong answer shows the correct result in red. Then practice five more like the ones you leave checked.',
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: t.takePhoto,
            busy: _busy,
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: t.choosePhoto,
            secondary: true,
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          if (_photoPath != null && _imageWidth > 0 && _imageHeight > 0) ...[
            const SizedBox(height: AppSpace.s16),
            _GradedPhoto(
              path: _photoPath!,
              imageWidth: _imageWidth,
              imageHeight: _imageHeight,
              marks: _grades,
              right: AppColors.of(context).success,
              wrong: AppColors.of(context).danger,
            ),
          ],
          if (_facts.isNotEmpty) ...[
            const SizedBox(height: AppSpace.s24),
            Text(
              tally.total == 0
                  ? t.pick('勾上做错的题。', 'Check the problems that were wrong.')
                  : t.pick(
                      '已勾选 ${tally.total} 题 · ${t.operation(tally.focus ?? 'addition')}',
                      '${tally.total} checked · ${t.operation(tally.focus ?? 'addition')}',
                    ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final entry in tally.counts.entries)
              Text('${t.operation(entry.key)}: ${entry.value}'),
            const SizedBox(height: AppSpace.s8),
            for (var i = 0; i < _facts.length; i++)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _checked[i],
                onChanged: (value) {
                  setState(() => _checked[i] = value ?? false);
                },
                title: Text(_facts[i].prompt),
                subtitle: Text(
                  _facts[i].written == null
                      ? t.pick('答案 ${_facts[i].computed}', 'Answer ${_facts[i].computed}')
                      : t.pick(
                          '卷面写的是 ${_facts[i].written}。答案是 ${_facts[i].computed}。',
                          'Page says ${_facts[i].written}. Answer ${_facts[i].computed}.',
                        ),
                ),
              ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: t.practiceFive,
              busy: _busy,
              onPressed: _selected.isEmpty || _busy ? null : _practice,
            ),
          ],
        ],
      ),
    );
  }
}

class _GradedPhoto extends StatelessWidget {
  const _GradedPhoto({
    required this.path,
    required this.imageWidth,
    required this.imageHeight,
    required this.marks,
    required this.right,
    required this.wrong,
  });

  final String path;
  final int imageWidth;
  final int imageHeight;
  final List<GradedProblem> marks;
  final Color right;
  final Color wrong;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: imageWidth / imageHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.fill, gaplessPlayback: true),
            CustomPaint(
              painter: _GradePainter(
                imageWidth: imageWidth.toDouble(),
                imageHeight: imageHeight.toDouble(),
                marks: marks,
                right: right,
                wrong: wrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradePainter extends CustomPainter {
  _GradePainter({
    required this.imageWidth,
    required this.imageHeight,
    required this.marks,
    required this.right,
    required this.wrong,
  });

  final double imageWidth;
  final double imageHeight;
  final List<GradedProblem> marks;
  final Color right;
  final Color wrong;

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;
    final sx = size.width / imageWidth;
    final sy = size.height / imageHeight;
    for (final mark in marks) {
      if (!mark.hasBox) continue;
      final rect = Rect.fromLTRB(
        mark.left * sx,
        mark.top * sy,
        mark.right * sx,
        mark.bottom * sy,
      );
      if (mark.correct) {
        _check(canvas, size, rect);
      } else {
        _answer(canvas, size, rect, mark.fact.computed);
      }
    }
  }

  void _check(Canvas canvas, Size size, Rect rect) {
    final height = max(16.0, rect.height);
    var x = rect.right + height * 0.15;
    if (x + height > size.width - 4) x = max(4.0, size.width - height - 4);
    final y = rect.center.dy;
    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x + height * 0.32, y + height * 0.30)
      ..lineTo(x + height * 0.82, y - height * 0.32);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white
        ..strokeWidth = max(5, height * 0.28),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = right
        ..strokeWidth = max(2.5, height * 0.14),
    );
  }

  void _answer(Canvas canvas, Size size, Rect rect, String answer) {
    final font = max(14.0, rect.height * 0.85);
    final painter = TextPainter(
      text: TextSpan(
        text: answer,
        style: TextStyle(
          color: wrong,
          fontSize: font,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var x = rect.right + 6;
    if (x + painter.width > size.width - 4) {
      x = max(4.0, size.width - painter.width - 4);
    }
    final y = rect.center.dy - painter.height / 2;
    const pad = 3.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - pad,
          y - pad,
          painter.width + pad * 2,
          painter.height + pad * 2,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xF2FFFFFF),
    );
    painter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _GradePainter old) {
    return old.marks != marks ||
        old.imageWidth != imageWidth ||
        old.imageHeight != imageHeight ||
        old.right != right ||
        old.wrong != wrong;
  }
}

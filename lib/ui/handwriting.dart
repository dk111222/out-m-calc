import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as ml;

import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';

/// Remembered for this process, so the next problem stays on the chosen mode.
bool answerByHandwriting = false;

const _inkLanguage = 'en';

class HandwritingPad extends StatefulWidget {
  const HandwritingPad({
    super.key,
    required this.prompt,
    required this.enabled,
    required this.height,
    required this.onReplace,
  });

  final String prompt;
  final bool enabled;
  final double height;
  final ValueChanged<String> onReplace;

  @override
  State<HandwritingPad> createState() => _HandwritingPadState();
}

class _InkPoint {
  const _InkPoint(this.offset, this.t);

  final Offset offset;
  final int t;
}

class _HandwritingPadState extends State<HandwritingPad> {
  final _canvasKey = GlobalKey();
  final _strokes = <List<_InkPoint>>[];
  ml.DigitalInkRecognizer? _reader;
  Timer? _timer;
  int _generation = 0;
  bool _preparing = true;
  bool _failed = false;
  bool _unclear = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(HandwritingPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prompt != widget.prompt) {
      _timer?.cancel();
      _generation++;
      _strokes.clear();
      _unclear = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _generation++;
    _reader?.close();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _preparing = true;
      _failed = false;
    });
    try {
      final manager = ml.DigitalInkRecognizerModelManager();
      final ready = await manager.isModelDownloaded(_inkLanguage);
      if (!ready) {
        final downloaded = await manager.downloadModel(
          _inkLanguage,
          isWifiRequired: false,
        );
        if (!downloaded) throw StateError('model');
      }
      _reader ??= ml.DigitalInkRecognizer(languageCode: _inkLanguage);
      if (!mounted) return;
      setState(() => _preparing = false);
      if (_strokes.isNotEmpty) _schedule();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _failed = true;
      });
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 450), _recognize);
  }

  Future<void> _recognize() async {
    final reader = _reader;
    if (reader == null || _strokes.isEmpty) return;
    final generation = _generation;
    final ink = ml.Ink()
      ..strokes = [
        for (final stroke in _strokes)
          if (stroke.isNotEmpty)
            ml.Stroke()
              ..points = [
                for (final point in _pointsFor(stroke))
                  ml.StrokePoint(
                    x: point.offset.dx,
                    y: point.offset.dy,
                    t: point.t,
                  ),
              ],
      ];
    if (ink.strokes.isEmpty) return;
    try {
      final size = _canvasKey.currentContext?.size;
      final context = size == null
          ? null
          : ml.DigitalInkRecognitionContext(
              writingArea: ml.WritingArea(
                width: size.width,
                height: size.height,
              ),
            );
      final candidates = await reader.recognize(ink, context: context);
      if (!mounted || generation != _generation) return;
      final ranked = [...candidates]
        ..sort((a, b) => a.score.compareTo(b.score));
      final answer = pickInkAnswer(ranked.map((candidate) => candidate.text));
      if (answer == null) {
        setState(() => _unclear = true);
        return;
      }
      setState(() => _unclear = false);
      widget.onReplace(answer);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _unclear = true);
    }
  }

  List<_InkPoint> _pointsFor(List<_InkPoint> stroke) {
    if (stroke.length > 1) return stroke;
    final point = stroke.first;
    return [point, _InkPoint(point.offset, point.t + 1)];
  }

  void _clear() {
    _timer?.cancel();
    _generation++;
    setState(() {
      _strokes.clear();
      _unclear = false;
    });
    widget.onReplace('');
  }

  void _start(Offset position) {
    if (!widget.enabled) return;
    _generation++;
    _timer?.cancel();
    setState(() {
      _unclear = false;
      _strokes.add([
        _InkPoint(position, DateTime.now().millisecondsSinceEpoch),
      ]);
    });
  }

  void _move(Offset position) {
    if (!widget.enabled || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(
        _InkPoint(position, DateTime.now().millisecondsSinceEpoch),
      );
    });
  }

  void _end() {
    if (!widget.enabled || _strokes.isEmpty) return;
    if (_reader != null) _schedule();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = Copy.of(context);
    final note = _failed
        ? t.handwritingNeedsDownload
        : _strokes.isEmpty && _preparing
        ? t.handwritingPreparing
        : _unclear
        ? t.handwritingUnclear
        : _strokes.isEmpty
        ? t.writeAnswer
        : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sunken,
        borderRadius: BorderRadius.circular(AppSpace.rMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s8),
        child: SizedBox(
          height: widget.height - AppSpace.s16,
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpace.rSm),
                    border: Border.all(color: colors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpace.rSm),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          key: _canvasKey,
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) =>
                              _start(details.localPosition),
                          onPanUpdate: (details) =>
                              _move(details.localPosition),
                          onPanEnd: (_) => _end(),
                          child: CustomPaint(
                            painter: _InkPainter([
                              for (final stroke in _strokes)
                                [for (final point in stroke) point.offset],
                            ], colors.text),
                          ),
                        ),
                        if (note != null)
                          IgnorePointer(
                            ignoring: !_failed,
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpace.s16),
                                child: _failed
                                    ? TextButton(
                                        onPressed: _prepare,
                                        child: Text(
                                          note,
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : Text(
                                        note,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: colors.textMuted),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s8),
              SizedBox(
                height: AppSpace.minTarget,
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.enabled && _strokes.isNotEmpty
                      ? _clear
                      : null,
                  child: Text(t.clearWriting),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes, this.color);

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      if (stroke.length == 1) {
        path.lineTo(stroke.first.dx + 0.1, stroke.first.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}

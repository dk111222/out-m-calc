import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../domain/digit_ink.dart';
import '../domain/stroke_preprocessor.dart';
import '../l10n/copy.dart';

/// Remembered for this process, so the next problem stays on the chosen mode.
bool answerByHandwriting = false;

DigitNet? _net;
Future<void>? _opening;

Future<void> _openReader() {
  final pending = _opening;
  if (pending != null) return pending;
  final run = _createReader();
  _opening = run;
  return run;
}

Future<void> _createReader() async {
  try {
    if (_net != null) return;
    final data = await rootBundle.load('assets/models/digits.f32');
    _net = DigitNet.fromBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } catch (_) {
    _opening = null;
    rethrow;
  }
}

/// Load the bundled digit model when the calculation page opens.
Future<void> warmHandwriting() => _openReader();

class HandwritingPad extends StatefulWidget {
  const HandwritingPad({
    super.key,
    required this.prompt,
    required this.enabled,
    required this.height,
    required this.onReplace,
    required this.onSubmit,
    this.clearTick = 0,
  });

  final String prompt;
  final bool enabled;
  final double height;
  final ValueChanged<String> onReplace;
  final VoidCallback onSubmit;
  final int clearTick;

  @override
  State<HandwritingPad> createState() => _HandwritingPadState();
}

class _InkPoint {
  const _InkPoint(this.offset, this.timestamp);

  final Offset offset;
  final int timestamp;
}

class _HandwritingPadState extends State<HandwritingPad> {
  final _canvasKey = GlobalKey();
  final _strokes = <List<_InkPoint>>[];
  Timer? _timer;
  int _generation = 0;
  int _lastStamp = 0;
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
    if (oldWidget.prompt != widget.prompt ||
        oldWidget.clearTick != widget.clearTick) {
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
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _preparing = true;
      _failed = false;
    });
    try {
      await _openReader();
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

  int _stamp() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final stamp = now > _lastStamp ? now : _lastStamp + 1;
    _lastStamp = stamp;
    return stamp;
  }

  Future<void> _recognize() async {
    if (_strokes.isEmpty) return;
    final generation = _generation;
    final rawStrokes = [
      for (final stroke in _strokes)
        if (stroke.isNotEmpty)
          [
            for (final point in stroke)
              StrokePoint(point.offset.dx, point.offset.dy, point.timestamp),
          ],
    ];
    // Specks never reach the reader. The pad still paints the raw ink.
    final processed = StrokePreprocessor.process(rawStrokes);
    if (processed.isEmpty) {
      if (!mounted || generation != _generation) return;
      setState(() => _unclear = true);
      return;
    }
    final strokes = [
      for (final stroke in processed)
        [for (final point in stroke) InkPoint(point.x, point.y)],
    ];
    try {
      await _openReader();
      if (!mounted || generation != _generation) return;
      final net = _net;
      if (net == null) return;
      final answer = recognizeInk(strokes, net);
      if (!mounted || generation != _generation) return;
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

  void _start(Offset position) {
    if (!widget.enabled) return;
    _generation++;
    _timer?.cancel();
    setState(() {
      _unclear = false;
      _strokes.add([_InkPoint(position, _stamp())]);
    });
  }

  void _move(Offset position) {
    if (!widget.enabled || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(_InkPoint(position, _stamp()));
    });
  }

  void _end() {
    if (!widget.enabled || _strokes.isEmpty) return;
    _schedule();
  }

  Future<void> _confirm() async {
    if (!widget.enabled) return;
    _timer?.cancel();
    if (_strokes.isNotEmpty) await _recognize();
    if (!mounted) return;
    widget.onSubmit();
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
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RawGestureDetector(
                      key: _canvasKey,
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        _InkPan: GestureRecognizerFactoryWithHandlers<_InkPan>(
                          _InkPan.new,
                          (pan) {
                            pan.onStart = (details) {
                              _start(details.localPosition);
                            };
                            pan.onUpdate = (details) {
                              _move(details.localPosition);
                            };
                            pan.onEnd = (_) => _end();
                          },
                        ),
                      },
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
          Positioned(
            right: AppSpace.s8,
            bottom: AppSpace.s8,
            child: _ConfirmButton(
              label: t.submit,
              enabled: widget.enabled,
              onPressed: _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.rSm),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpace.rSm),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            width: AppSpace.minTarget,
            height: AppSpace.minTarget,
            child: Icon(
              Icons.check,
              color: enabled ? colors.accent : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Accepts the stroke on the first pixel so a scrolling page cannot
/// swallow the start of the digit.
class _InkPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
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

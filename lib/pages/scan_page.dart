import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
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

enum _ScanPhase { capture, crop, graded }

class _ScanPageState extends ConsumerState<ScanPage> {
  final _picker = ImagePicker();
  _ScanPhase _phase = _ScanPhase.capture;
  String? _photoPath;
  int _imageWidth = 0;
  int _imageHeight = 0;
  List<GradedProblem> _grades = const [];
  List<bool> _checked = const [];
  bool _busy = false;
  String? _error;
  bool _openedCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _openedCamera) return;
      _openedCamera = true;
      _pick(ImageSource.camera);
    });
  }

  List<ScannedFact> get _facts => _grades.map((grade) => grade.fact).toList();

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
      final bytes = await File(file.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      image.dispose();
      if (!mounted) return;
      setState(() {
        _photoPath = file.path;
        _imageWidth = width;
        _imageHeight = height;
        _grades = const [];
        _checked = const [];
        _phase = _ScanPhase.crop;
        _region = null;
        _busy = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = Copy.of(context).pick(
          '没能打开相机。可以重拍，或从相册选一张。',
          'Could not open the camera. Retake, or choose a photo.',
        );
      });
    }
  }

  Future<void> _confirmRegion(Rect region) async {
    final source = _photoPath;
    if (source == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cropped = await _writeCrop(source, region);
      final recognized = await _read(cropped.path);
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
        _photoPath = cropped.path;
        _imageWidth = cropped.width;
        _imageHeight = cropped.height;
        _grades = grades;
        _checked = grades.map((grade) => !grade.correct).toList();
        _phase = _ScanPhase.graded;
        _busy = false;
        _error = grades.isEmpty
            ? Copy.of(context).pick(
                '这块区域里没有读到算式。换一块更清楚的区域再试。',
                'No problems in that area. Try a clearer region.',
              )
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = Copy.of(context).pick(
          '没能读出这张照片。换一张更亮的再试。',
          'Could not read that photo. Try a brighter picture.',
        );
      });
    }
  }

  Future<({String path, int width, int height})> _writeCrop(
    String path,
    Rect region,
  ) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;
    final left = region.left.clamp(0, source.width - 1).floor();
    final top = region.top.clamp(0, source.height - 1).floor();
    final right = region.right.clamp(left + 1, source.width).ceil();
    final bottom = region.bottom.clamp(top + 1, source.height).ceil();
    final width = right - left;
    final height = bottom - top;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      source,
      Rect.fromLTWH(
        left.toDouble(),
        top.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint(),
    );
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    source.dispose();
    image.dispose();
    final out = File('$path.crop.png');
    await out.writeAsBytes(data!.buffer.asUint8List());
    return (path: out.path, width: width, height: height);
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
            steps: [StepAsk(1, 'What is ${fact.prompt}?', fact.computed)],
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

  Rect? _region;

  void _explain(GradedProblem mark) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final fact = mark.fact;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fact.prompt,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                fact.written == null
                    ? t.pick('这题没有写出答案。', 'No answer was written.')
                    : t.pick(
                        '卷面写的是 ${fact.written}。',
                        'The page says ${fact.written}.',
                      ),
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                '${t.correctAnswerLabel} ${fact.computed}',
                style: TextStyle(
                  color: colors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              Text(
                t.howToSolve,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.s8),
              Text(_method(fact, t)),
            ],
          ),
        );
      },
    );
  }

  String _method(ScannedFact fact, Copy t) {
    final answer = fact.computed;
    switch (fact.operation) {
      case 'subtraction':
        return t.pick(
          '从 ${fact.left} 里减去 ${fact.right}，得到 $answer。',
          'Take ${fact.right} away from ${fact.left}. The result is $answer.',
        );
      case 'multiplication':
        return t.pick(
          '${fact.left} 个 ${fact.right} 加在一起，得到 $answer。',
          '${fact.left} groups of ${fact.right} make $answer.',
        );
      case 'division':
        return t.pick(
          '${fact.left} 按 ${fact.right} 一组来分，可以分成 $answer 组。',
          'Split ${fact.left} into groups of ${fact.right}. That makes $answer groups.',
        );
      default:
        return t.pick(
          '把 ${fact.left} 和 ${fact.right} 相加，得到 $answer。',
          'Add ${fact.left} and ${fact.right}. The result is $answer.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final wrongs = [
      for (final grade in _grades)
        if (!grade.correct) grade,
    ];
    return PageFrame(
      title: t.scanPaper,
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: switch (_phase) {
        _ScanPhase.capture => _captureBody(t),
        _ScanPhase.crop => _cropBody(t),
        _ScanPhase.graded => _gradedBody(t, wrongs),
      },
    );
  }

  Widget _captureBody(Copy t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.pick(
            '识别只在这台设备上进行。拍下练习页后，框出要批改的区域。',
            'Reading stays on this device. After the photo, outline the area to check.',
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
      ],
    );
  }

  Widget _cropBody(Copy t) {
    final path = _photoPath;
    if (path == null) return _captureBody(t);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.pick(
            '按住拖动，框出要批改的区域，再点确认。',
            'Drag to outline the area, then confirm.',
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: _RegionPicker(
            path: path,
            imageWidth: _imageWidth,
            imageHeight: _imageHeight,
            onChanged: (region) => _region = region,
          ),
        ),
        const SizedBox(height: AppSpace.s12),
        AppButton(
          label: t.confirmRegion,
          busy: _busy,
          onPressed: _busy
              ? null
              : () {
                  final full = Rect.fromLTWH(
                    0,
                    0,
                    _imageWidth.toDouble(),
                    _imageHeight.toDouble(),
                  );
                  _confirmRegion(_region ?? full);
                },
        ),
        const SizedBox(height: AppSpace.s12),
        AppButton(
          label: t.retakePhoto,
          secondary: true,
          onPressed: _busy ? null : () => _pick(ImageSource.camera),
        ),
      ],
    );
  }

  Widget _gradedBody(Copy t, List<GradedProblem> wrongs) {
    final path = _photoPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (path != null && _imageWidth > 0 && _imageHeight > 0)
          _GradedPhoto(
            path: path,
            imageWidth: _imageWidth,
            imageHeight: _imageHeight,
            marks: _grades,
            ink: AppColors.of(context).danger,
          ),
        const SizedBox(height: AppSpace.s24),
        Text(t.wrongAnalysis, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        if (wrongs.isEmpty)
          Text(t.noWrongsOnPage)
        else
          for (final mark in wrongs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(mark.fact.prompt),
              subtitle: Text(
                mark.fact.written == null
                    ? t.pick('没有写出答案', 'No answer written')
                    : t.pick(
                        '写的是 ${mark.fact.written}',
                        'Wrote ${mark.fact.written}',
                      ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.of(context).danger,
              ),
              onTap: () => _explain(mark),
            ),
        if (wrongs.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: t.practiceFive,
            busy: _busy,
            onPressed: _selected.isEmpty || _busy ? null : _practice,
          ),
        ],
        const SizedBox(height: AppSpace.s12),
        AppButton(
          label: t.retakePhoto,
          secondary: true,
          onPressed: _busy ? null : () => _pick(ImageSource.camera),
        ),
      ],
    );
  }
}

class _GradedPhoto extends StatelessWidget {
  const _GradedPhoto({
    required this.path,
    required this.imageWidth,
    required this.imageHeight,
    required this.marks,
    required this.ink,
  });

  final String path;
  final int imageWidth;
  final int imageHeight;
  final List<GradedProblem> marks;
  final Color ink;

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
                ink: ink,
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
    required this.ink,
  });

  final double imageWidth;
  final double imageHeight;
  final List<GradedProblem> marks;
  final Color ink;

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
        _mark(canvas, size, rect, check: true);
      } else {
        _mark(canvas, size, rect, check: false);
      }
    }
  }

  void _mark(Canvas canvas, Size size, Rect rect, {required bool check}) {
    final height = max(16.0, rect.height);
    var x = rect.right + height * 0.15;
    if (x + height > size.width - 4) x = max(4.0, size.width - height - 4);
    final y = rect.center.dy;
    final path = Path();
    if (check) {
      path
        ..moveTo(x, y)
        ..lineTo(x + height * 0.32, y + height * 0.30)
        ..lineTo(x + height * 0.82, y - height * 0.32);
    } else {
      final arm = height * 0.36;
      path
        ..moveTo(x, y - arm)
        ..lineTo(x + height * 0.72, y + arm)
        ..moveTo(x + height * 0.72, y - arm)
        ..lineTo(x, y + arm);
    }
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
        ..color = ink
        ..strokeWidth = max(2.5, height * 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _GradePainter old) {
    return old.marks != marks ||
        old.imageWidth != imageWidth ||
        old.imageHeight != imageHeight ||
        old.ink != ink;
  }
}

class _RegionPicker extends StatefulWidget {
  const _RegionPicker({
    required this.path,
    required this.imageWidth,
    required this.imageHeight,
    required this.onChanged,
  });

  final String path;
  final int imageWidth;
  final int imageHeight;
  final ValueChanged<Rect> onChanged;

  @override
  State<_RegionPicker> createState() => _RegionPickerState();
}

class _RegionPickerState extends State<_RegionPicker> {
  Offset? _start;
  Rect? _rect;
  Size _box = Size.zero;

  void _report() {
    final shown = _rect;
    final box = _box;
    if (shown == null || box.width <= 0 || box.height <= 0) return;
    if (shown.width < 24 || shown.height < 24) return;
    final sx = widget.imageWidth / box.width;
    final sy = widget.imageHeight / box.height;
    widget.onChanged(
      Rect.fromLTRB(
        shown.left * sx,
        shown.top * sy,
        shown.right * sx,
        shown.bottom * sy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageAspect = widget.imageWidth / widget.imageHeight;
        final boxAspect = constraints.maxWidth / constraints.maxHeight;
        final width = imageAspect > boxAspect
            ? constraints.maxWidth
            : constraints.maxHeight * imageAspect;
        final height = width / imageAspect;
        _box = Size(width, height);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                _RegionPan: GestureRecognizerFactoryWithHandlers<_RegionPan>(
                  _RegionPan.new,
                  (pan) {
                    pan.onStart = (details) {
                      _start = details.localPosition;
                      setState(() {
                        _rect = Rect.fromPoints(_start!, _start!);
                      });
                    };
                    pan.onUpdate = (details) {
                      final start = _start;
                      final box = _box;
                      if (start == null || box.width <= 0) return;
                      final point = Offset(
                        details.localPosition.dx.clamp(0, box.width),
                        details.localPosition.dy.clamp(0, box.height),
                      );
                      setState(() => _rect = Rect.fromPoints(start, point));
                      _report();
                    };
                  },
                ),
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(widget.path), fit: BoxFit.fill),
                  CustomPaint(painter: _RegionPainter(_rect)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RegionPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _RegionPainter extends CustomPainter {
  _RegionPainter(this.rect);

  final Rect? rect;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = rect;
    if (hole == null || hole.width <= 4 || hole.height <= 4) return;
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = const Color(0x88000000));
    canvas.drawRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFE23B32),
    );
  }

  @override
  bool shouldRepaint(covariant _RegionPainter old) => old.rect != rect;
}

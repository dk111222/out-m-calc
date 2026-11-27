import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/copy.dart';

/// Pan and pinch a photo, then keep the circle in the middle.
///
/// The circle on screen is the preview. [保存] returns PNG bytes.
class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final _transform = TransformationController();
  ui.Image? _image;
  var _ready = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _transform.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _image = frame.image);
  }

  void _fitOnce(double viewSize, ui.Image image) {
    if (_ready) return;
    _ready = true;
    final cover = _coverScale(image, viewSize);
    final childW = image.width * cover;
    final childH = image.height * cover;
    _transform.value = Matrix4.translationValues(
      (viewSize - childW) / 2,
      (viewSize - childH) / 2,
      0,
    );
  }

  Future<void> _save(double viewSize) async {
    final image = _image;
    if (image == null || _busy) return;
    setState(() => _busy = true);
    final bytes = await _circlePng(
      image: image,
      transform: _transform.value,
      viewSize: viewSize,
    );
    if (!mounted) return;
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(title: Text(t.cropAvatar)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewSize = math.min(constraints.maxWidth - 48, 320.0);
            final image = _image;
            if (image != null) _fitOnce(viewSize, image);
            return Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: viewSize,
                  height: viewSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpace.rLg),
                    child: image == null
                        ? const Center(child: CircularProgressIndicator())
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              InteractiveViewer(
                                transformationController: _transform,
                                constrained: false,
                                minScale: 1,
                                maxScale: 4,
                                boundaryMargin: EdgeInsets.all(viewSize),
                                child: SizedBox(
                                  width: image.width * _coverScale(image, viewSize),
                                  height:
                                      image.height * _coverScale(image, viewSize),
                                  child: RawImage(image: image, fit: BoxFit.fill),
                                ),
                              ),
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _CircleShadePainter(
                                    color: colors.bg.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Text(
                  t.previewAvatar,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(t.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: image == null || _busy
                              ? null
                              : () => _save(viewSize),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(t.previewAvatar),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

double _coverScale(ui.Image image, double viewSize) {
  return math.max(viewSize / image.width, viewSize / image.height);
}

Future<Uint8List> _circlePng({
  required ui.Image image,
  required Matrix4 transform,
  required double viewSize,
}) async {
  final inverse = Matrix4.inverted(transform);
  final origin = MatrixUtils.transformPoint(inverse, Offset.zero);
  final edge = MatrixUtils.transformPoint(inverse, Offset(viewSize, viewSize));
  final cover = _coverScale(image, viewSize);
  final src = Rect.fromLTRB(
    origin.dx / cover,
    origin.dy / cover,
    edge.dx / cover,
    edge.dy / cover,
  );
  const out = 512.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, out, out)));
  canvas.drawColor(const Color(0xFFE7F2FB), BlendMode.src);
  canvas.drawImageRect(
    image,
    src,
    const Rect.fromLTWH(0, 0, out, out),
    Paint()..filterQuality = FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final scaled = await picture.toImage(out.toInt(), out.toInt());
  final data = await scaled.toByteData(format: ui.ImageByteFormat.png);
  scaled.dispose();
  return data!.buffer.asUint8List();
}

class _CircleShadePainter extends CustomPainter {
  const _CircleShadePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - 8))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CircleShadePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

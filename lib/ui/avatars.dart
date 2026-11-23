import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Cute anime / chibi looks kids enjoy (not picture-book flat).
/// Keep [id] values stable — they are stored on learners.
enum _Hair { fringe, bob, curls, ponytail, bun, sweep, waves, crop }

class _Look {
  const _Look({
    required this.id,
    required this.skin,
    required this.blush,
    required this.hair,
    required this.hairLight,
    required this.shirt,
    required this.backdrop,
    required this.backdropDeep,
    required this.iris,
    required this.irisLight,
    required this.hairStyle,
    this.freckles = false,
    this.glasses = false,
  });

  final String id;
  final Color skin;
  final Color blush;
  final Color hair;
  final Color hairLight;
  final Color shirt;
  final Color backdrop;
  final Color backdropDeep;
  final Color iris;
  final Color irisLight;
  final _Hair hairStyle;
  final bool freckles;
  final bool glasses;
}

const _looks = <_Look>[
  _Look(
    id: 'sunny',
    skin: Color(0xFFFFE0C2),
    blush: Color(0xFFFF8FA8),
    hair: Color(0xFFFFC94A),
    hairLight: Color(0xFFFFE08A),
    shirt: Color(0xFF7FE0B0),
    backdrop: Color(0xFFFFF3B0),
    backdropDeep: Color(0xFFFFE8E0),
    iris: Color(0xFF3DBE66),
    irisLight: Color(0xFFB6F5C8),
    hairStyle: _Hair.fringe,
    freckles: true,
  ),
  _Look(
    id: 'maple',
    skin: Color(0xFFFFE4CE),
    blush: Color(0xFFFF7A96),
    hair: Color(0xFFFF6B3D),
    hairLight: Color(0xFFFFA07A),
    shirt: Color(0xFFFF8A65),
    backdrop: Color(0xFFFFD6E0),
    backdropDeep: Color(0xFFFFF0F4),
    iris: Color(0xFF4A7DE8),
    irisLight: Color(0xFFC5D9FF),
    hairStyle: _Hair.bob,
  ),
  _Look(
    id: 'river',
    skin: Color(0xFFF0C8A0),
    blush: Color(0xFFFF8F7A),
    hair: Color(0xFF3A2A24),
    hairLight: Color(0xFF6A4A3A),
    shirt: Color(0xFF64B5F6),
    backdrop: Color(0xFFD4EEFF),
    backdropDeep: Color(0xFFEEF7FF),
    iris: Color(0xFF3F86D4),
    irisLight: Color(0xFFB8DCFF),
    hairStyle: _Hair.curls,
    glasses: true,
  ),
  _Look(
    id: 'cedar',
    skin: Color(0xFFA06A48),
    blush: Color(0xFFE08A72),
    hair: Color(0xFF1A1210),
    hairLight: Color(0xFF4A3428),
    shirt: Color(0xFFFFB74D),
    backdrop: Color(0xFFFFE0A8),
    backdropDeep: Color(0xFFFFF3D6),
    iris: Color(0xFF8B5A2B),
    irisLight: Color(0xFFE2C29A),
    hairStyle: _Hair.curls,
  ),
  _Look(
    id: 'wren',
    skin: Color(0xFFFFDEC8),
    blush: Color(0xFFFF7A9C),
    hair: Color(0xFFE8913A),
    hairLight: Color(0xFFFFC078),
    shirt: Color(0xFFFF6B9D),
    backdrop: Color(0xFFFFD0E0),
    backdropDeep: Color(0xFFFFEEF4),
    iris: Color(0xFF55C265),
    irisLight: Color(0xFFC8F5CE),
    hairStyle: _Hair.ponytail,
  ),
  _Look(
    id: 'noah',
    skin: Color(0xFFF5D0A8),
    blush: Color(0xFFFF9A86),
    hair: Color(0xFF2A1E1A),
    hairLight: Color(0xFF5A4034),
    shirt: Color(0xFF5C7CFA),
    backdrop: Color(0xFFD8E4FF),
    backdropDeep: Color(0xFFEEF2FF),
    iris: Color(0xFF3F5FF0),
    irisLight: Color(0xFFC5D0FF),
    hairStyle: _Hair.sweep,
  ),
  _Look(
    id: 'piper',
    skin: Color(0xFFFFE2CC),
    blush: Color(0xFFFF8FB0),
    hair: Color(0xFFFFD54F),
    hairLight: Color(0xFFFFECB3),
    shirt: Color(0xFFB388FF),
    backdrop: Color(0xFFE8D8FF),
    backdropDeep: Color(0xFFF6F0FF),
    iris: Color(0xFF8B6CF7),
    irisLight: Color(0xFFDDCFFC),
    hairStyle: _Hair.waves,
  ),
  _Look(
    id: 'leo',
    skin: Color(0xFFD49A68),
    blush: Color(0xFFE89A7A),
    hair: Color(0xFF3D2818),
    hairLight: Color(0xFF6B4A32),
    shirt: Color(0xFF38B2A8),
    backdrop: Color(0xFFC8F0E8),
    backdropDeep: Color(0xFFE8FAF6),
    iris: Color(0xFF2A9B88),
    irisLight: Color(0xFFA8E8DC),
    hairStyle: _Hair.bun,
  ),
];

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.id, this.size = 48});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final look = _looks.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => _looks.first,
    );
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AvatarPainter(look)),
    );
  }
}

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Wrap(
      spacing: AppSpace.s12,
      runSpacing: AppSpace.s12,
      children: [
        for (final avatar in _looks)
          Semantics(
            button: true,
            selected: avatar.id == selected,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onSelected(avatar.id),
              child: AnimatedContainer(
                duration: motionFast,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatar.id == selected
                        ? colors.accent
                        : colors.border,
                    width: avatar.id == selected ? 2.5 : 1,
                  ),
                ),
                child: ChildAvatar(id: avatar.id, size: 56),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarPainter extends CustomPainter {
  const _AvatarPainter(this.look);

  final _Look look;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.scale(scale);
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, 100, 100)));

    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.15, -0.45),
        radius: 1.25,
        colors: [look.backdropDeep, look.backdrop],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), bg);

    final spark = Paint()..color = Colors.white.withValues(alpha: 0.65);
    for (final c in const [
      Offset(12, 16),
      Offset(88, 20),
      Offset(16, 80),
      Offset(86, 74),
      Offset(50, 8),
    ]) {
      _star(canvas, c, 3.6, spark);
    }

    // Shirt
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(14, 76, 72, 40),
        topLeft: const Radius.circular(26),
        topRight: const Radius.circular(26),
      ),
      Paint()..color = look.shirt,
    );
    canvas.drawPath(
      Path()
        ..moveTo(38, 78)
        ..lineTo(50, 92)
        ..lineTo(62, 78)
        ..close(),
      Paint()..color = Color.lerp(look.shirt, Colors.white, 0.32)!,
    );

    final skin = Paint()..color = look.skin;
    final hair = Paint()..color = look.hair;
    final hairLight = Paint()..color = look.hairLight;

    _backHair(canvas, hair, hairLight);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 68, 12, 12),
        const Radius.circular(6),
      ),
      skin,
    );
    canvas.drawOval(const Rect.fromLTWH(20, 40, 10, 13), skin);
    canvas.drawOval(const Rect.fromLTWH(70, 40, 10, 13), skin);

    // Oversized chibi head
    canvas.drawOval(const Rect.fromLTWH(18, 14, 64, 62), skin);

    // Strong anime blush
    final blush = Paint()..color = look.blush.withValues(alpha: 0.48);
    canvas.drawOval(const Rect.fromLTWH(22, 54, 18, 12), blush);
    canvas.drawOval(const Rect.fromLTWH(60, 54, 18, 12), blush);

    _frontHair(canvas, hair, hairLight);
    _face(canvas);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final outer = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      final mid = Offset(
        c.dx + math.cos(a + math.pi / 4) * r * 0.32,
        c.dy + math.sin(a + math.pi / 4) * r * 0.32,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(mid.dx, mid.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _backHair(Canvas canvas, Paint hair, Paint light) {
    switch (look.hairStyle) {
      case _Hair.ponytail:
        canvas.drawOval(const Rect.fromLTWH(70, 42, 22, 40), hair);
        canvas.drawOval(const Rect.fromLTWH(74, 50, 12, 28), light);
        canvas.drawCircle(const Offset(78, 40), 8, hair);
      case _Hair.bun:
        canvas.drawCircle(const Offset(50, 10), 14, hair);
        canvas.drawCircle(const Offset(50, 10), 8, light);
      case _Hair.curls:
        for (final center in const [
          Offset(22, 28),
          Offset(78, 28),
          Offset(14, 46),
          Offset(86, 46),
          Offset(26, 14),
          Offset(74, 14),
          Offset(16, 62),
          Offset(84, 62),
        ]) {
          canvas.drawCircle(center, 10.5, hair);
        }
      case _Hair.waves:
        canvas.drawOval(const Rect.fromLTWH(10, 32, 22, 46), hair);
        canvas.drawOval(const Rect.fromLTWH(68, 32, 22, 46), hair);
        canvas.drawOval(const Rect.fromLTWH(12, 46, 16, 30), light);
        canvas.drawOval(const Rect.fromLTWH(72, 46, 16, 30), light);
      case _Hair.bob:
        canvas.drawOval(const Rect.fromLTWH(10, 26, 20, 48), hair);
        canvas.drawOval(const Rect.fromLTWH(70, 26, 20, 48), hair);
      case _Hair.sweep:
        canvas.drawOval(const Rect.fromLTWH(10, 24, 18, 40), hair);
      default:
        break;
    }
  }

  void _frontHair(Canvas canvas, Paint hair, Paint light) {
    canvas.drawOval(const Rect.fromLTWH(16, 6, 68, 38), hair);

    // Ahoge
    if (look.hairStyle != _Hair.bun) {
      canvas.drawPath(
        Path()
          ..moveTo(46, 8)
          ..quadraticBezierTo(58, -4, 68, 10)
          ..quadraticBezierTo(56, 6, 46, 12)
          ..close(),
        hair,
      );
    }

    Path pointedFringe() {
      return Path()
        ..moveTo(22, 30)
        ..lineTo(30, 46)
        ..lineTo(38, 30)
        ..lineTo(46, 48)
        ..lineTo(54, 30)
        ..lineTo(62, 48)
        ..lineTo(70, 30)
        ..lineTo(78, 44)
        ..lineTo(82, 28)
        ..quadraticBezierTo(50, 16, 22, 30)
        ..close();
    }

    switch (look.hairStyle) {
      case _Hair.fringe:
      case _Hair.ponytail:
      case _Hair.crop:
        final fringe = pointedFringe();
        canvas.drawPath(fringe, hair);
        canvas.drawPath(
          fringe,
          Paint()..color = look.hairLight.withValues(alpha: 0.28),
        );
      case _Hair.bob:
        canvas.drawPath(pointedFringe(), hair);
        canvas.drawOval(const Rect.fromLTWH(12, 34, 14, 34), hair);
        canvas.drawOval(const Rect.fromLTWH(74, 34, 14, 34), hair);
      case _Hair.sweep:
        final sweep = Path()
          ..moveTo(20, 28)
          ..quadraticBezierTo(48, 8, 84, 26)
          ..lineTo(78, 40)
          ..quadraticBezierTo(50, 30, 24, 42)
          ..close();
        canvas.drawPath(sweep, hair);
        canvas.drawPath(
          sweep,
          Paint()..color = look.hairLight.withValues(alpha: 0.35),
        );
      case _Hair.curls:
        for (final center in const [
          Offset(34, 24),
          Offset(50, 16),
          Offset(66, 24),
          Offset(40, 34),
          Offset(60, 34),
          Offset(50, 28),
        ]) {
          canvas.drawCircle(center, 8, hair);
          canvas.drawCircle(center.translate(-2, -2), 2.4, light);
        }
      case _Hair.waves:
        canvas.drawPath(pointedFringe(), hair);
      case _Hair.bun:
        canvas.drawPath(pointedFringe(), hair);
    }
  }

  void _face(Canvas canvas) {
    void animeEye(Offset center, {required bool left}) {
      // Tall anime eye white
      final white = Path()
        ..addOval(
          Rect.fromCenter(center: center, width: 17, height: 20),
        );
      canvas.drawPath(white, Paint()..color = const Color(0xFFFFFDFB));

      // Iris
      final irisCenter = center.translate(0, 1.4);
      canvas.drawCircle(
        irisCenter,
        6.4,
        Paint()
          ..shader = RadialGradient(
            colors: [look.irisLight, look.iris, look.iris],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: irisCenter, radius: 6.4)),
      );
      // Pupil
      canvas.drawCircle(
        irisCenter.translate(0, 0.4),
        2.8,
        Paint()..color = const Color(0xFF140E0C),
      );
      // Triple sparkles
      canvas.drawCircle(
        irisCenter.translate(left ? -2.6 : 2.6, -2.8),
        2.3,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        irisCenter.translate(left ? 2.4 : -2.4, 1.8),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        irisCenter.translate(left ? -0.2 : 0.2, 3.4),
        0.7,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );

      // Thick upper lash
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(0, -1.5),
          width: 18,
          height: 16,
        ),
        math.pi * 1.02,
        math.pi * 0.96,
        false,
        Paint()
          ..color = const Color(0xFF1A1210)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      // Lower lash dots
      final lash = Paint()..color = const Color(0xFF1A1210);
      canvas.drawCircle(center.translate(left ? -6.5 : 6.5, 6.5), 0.9, lash);
      canvas.drawCircle(center.translate(left ? -3.5 : 3.5, 7.8), 0.7, lash);
    }

    // Eyebrows
    final brow = Paint()
      ..color = Color.lerp(look.hair, const Color(0xFF1A1210), 0.35)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(26, 28, 18, 10),
      math.pi * 1.15,
      math.pi * 0.55,
      false,
      brow,
    );
    canvas.drawArc(
      const Rect.fromLTWH(56, 28, 18, 10),
      math.pi * 1.3,
      math.pi * 0.55,
      false,
      brow,
    );

    animeEye(const Offset(36, 44), left: true);
    animeEye(const Offset(64, 44), left: false);

    // Tiny nose
    canvas.drawCircle(
      const Offset(50, 56),
      1.3,
      Paint()..color = Color.lerp(look.skin, look.blush, 0.6)!,
    );

    // Cute filled smile
    final mouth = Path()
      ..moveTo(43, 62)
      ..quadraticBezierTo(50, 72, 57, 62)
      ..quadraticBezierTo(50, 66, 43, 62)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFFE86A7A));
    canvas.drawPath(
      mouth,
      Paint()
        ..color = const Color(0xFF1A1210)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    if (look.freckles) {
      final dot = Paint()..color = const Color(0xFFE09A6A);
      for (final c in const [
        Offset(28, 58),
        Offset(32, 61),
        Offset(27, 62),
        Offset(72, 58),
        Offset(68, 61),
        Offset(73, 62),
      ]) {
        canvas.drawCircle(c, 0.95, dot);
      }
    }

    if (look.glasses) {
      final frames = Paint()
        ..color = const Color(0xFF1A1210)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 34, 22, 20),
          const Radius.circular(9),
        ),
        frames,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 34, 22, 20),
          const Radius.circular(9),
        ),
        frames,
      );
      canvas.drawLine(const Offset(46, 44), const Offset(54, 44), frames);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.look != look;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Cute anime / chibi looks kids enjoy.
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
    blush: Color(0xFFFF9AA8),
    hair: Color(0xFFFFC94A),
    hairLight: Color(0xFFFFE08A),
    shirt: Color(0xFF7FE0B0),
    backdrop: Color(0xFFFFF3B0),
    backdropDeep: Color(0xFFFFE8E0),
    iris: Color(0xFF4ECB71),
    irisLight: Color(0xFFB6F5C8),
    hairStyle: _Hair.fringe,
    freckles: true,
  ),
  _Look(
    id: 'maple',
    skin: Color(0xFFFFE4CE),
    blush: Color(0xFFFF8FA3),
    hair: Color(0xFFFF6B3D),
    hairLight: Color(0xFFFFA07A),
    shirt: Color(0xFFFF8A65),
    backdrop: Color(0xFFFFD6E0),
    backdropDeep: Color(0xFFFFF0F4),
    iris: Color(0xFF5B8DEF),
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
    iris: Color(0xFF4A90D9),
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
    blush: Color(0xFFFF8FA8),
    hair: Color(0xFFE8913A),
    hairLight: Color(0xFFFFC078),
    shirt: Color(0xFFFF6B9D),
    backdrop: Color(0xFFFFD0E0),
    backdropDeep: Color(0xFFFFEEF4),
    iris: Color(0xFF6BCB77),
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
    iris: Color(0xFF4C6EF5),
    irisLight: Color(0xFFC5D0FF),
    hairStyle: _Hair.sweep,
  ),
  _Look(
    id: 'piper',
    skin: Color(0xFFFFE2CC),
    blush: Color(0xFFFF9AB0),
    hair: Color(0xFFFFD54F),
    hairLight: Color(0xFFFFECB3),
    shirt: Color(0xFFB388FF),
    backdrop: Color(0xFFE8D8FF),
    backdropDeep: Color(0xFFF6F0FF),
    iris: Color(0xFF9775FA),
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
    iris: Color(0xFF2F9E8A),
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
        center: const Alignment(-0.2, -0.4),
        radius: 1.2,
        colors: [look.backdropDeep, look.backdrop],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), bg);

    // Soft sparkles in backdrop — playful anime kids vibe.
    final spark = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final c in const [
      Offset(14, 18),
      Offset(86, 22),
      Offset(18, 78),
      Offset(84, 72),
    ]) {
      _star(canvas, c, 3.2, spark);
    }

    final shirt = Paint()..color = look.shirt;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(16, 74, 68, 40),
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
      ),
      shirt,
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 76)
        ..lineTo(50, 88)
        ..lineTo(60, 76)
        ..close(),
      Paint()..color = Color.lerp(look.shirt, Colors.white, 0.28)!,
    );

    final skin = Paint()..color = look.skin;
    final hair = Paint()..color = look.hair;
    final hairLight = Paint()..color = look.hairLight;

    _backHair(canvas, hair, hairLight);

    // Short neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 66, 12, 12),
        const Radius.circular(6),
      ),
      skin,
    );

    // Anime ears (small)
    canvas.drawOval(const Rect.fromLTWH(22, 42, 9, 12), skin);
    canvas.drawOval(const Rect.fromLTWH(69, 42, 9, 12), skin);

    // Big chibi head
    canvas.drawOval(const Rect.fromLTWH(22, 18, 56, 58), skin);

    // Round blush patches
    final blush = Paint()..color = look.blush.withValues(alpha: 0.42);
    canvas.drawOval(const Rect.fromLTWH(26, 52, 15, 10), blush);
    canvas.drawOval(const Rect.fromLTWH(59, 52, 15, 10), blush);

    _frontHair(canvas, hair, hairLight);
    _face(canvas);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final outer = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      final mid = Offset(
        c.dx + math.cos(a + math.pi / 4) * r * 0.35,
        c.dy + math.sin(a + math.pi / 4) * r * 0.35,
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
        canvas.drawOval(const Rect.fromLTWH(68, 44, 20, 34), hair);
        canvas.drawOval(const Rect.fromLTWH(72, 50, 12, 24), light);
        canvas.drawCircle(const Offset(76, 42), 7, hair);
      case _Hair.bun:
        canvas.drawCircle(const Offset(50, 14), 13, hair);
        canvas.drawCircle(const Offset(50, 14), 8, light);
      case _Hair.curls:
        for (final center in const [
          Offset(24, 30),
          Offset(76, 30),
          Offset(18, 46),
          Offset(82, 46),
          Offset(28, 18),
          Offset(72, 18),
          Offset(20, 60),
          Offset(80, 60),
        ]) {
          canvas.drawCircle(center, 9.5, hair);
        }
      case _Hair.waves:
        canvas.drawOval(const Rect.fromLTWH(14, 36, 20, 40), hair);
        canvas.drawOval(const Rect.fromLTWH(66, 36, 20, 40), hair);
        canvas.drawOval(const Rect.fromLTWH(16, 48, 14, 26), light);
        canvas.drawOval(const Rect.fromLTWH(70, 48, 14, 26), light);
      case _Hair.bob:
        canvas.drawOval(const Rect.fromLTWH(14, 30, 18, 42), hair);
        canvas.drawOval(const Rect.fromLTWH(68, 30, 18, 42), hair);
      case _Hair.sweep:
        canvas.drawOval(const Rect.fromLTWH(14, 28, 16, 36), hair);
      default:
        break;
    }
  }

  void _frontHair(Canvas canvas, Paint hair, Paint light) {
    // Anime crown volume + ahoge-friendly top.
    canvas.drawOval(const Rect.fromLTWH(20, 10, 60, 36), hair);

    // Cute little ahoge for most styles.
    final ahoge = Path()
      ..moveTo(48, 12)
      ..quadraticBezierTo(56, 0, 62, 10)
      ..quadraticBezierTo(54, 8, 48, 14)
      ..close();
    if (look.hairStyle != _Hair.bun) {
      canvas.drawPath(ahoge, hair);
    }

    switch (look.hairStyle) {
      case _Hair.fringe:
        final fringe = Path()
          ..moveTo(26, 34)
          ..quadraticBezierTo(34, 48, 42, 34)
          ..quadraticBezierTo(50, 50, 58, 34)
          ..quadraticBezierTo(66, 48, 74, 32)
          ..quadraticBezierTo(50, 22, 26, 34)
          ..close();
        canvas.drawPath(fringe, hair);
        canvas.drawPath(
          fringe,
          Paint()..color = look.hairLight.withValues(alpha: 0.35),
        );
      case _Hair.bob:
        canvas.drawPath(
          Path()
            ..moveTo(28, 30)
            ..quadraticBezierTo(40, 46, 48, 32)
            ..quadraticBezierTo(56, 46, 72, 30)
            ..quadraticBezierTo(50, 22, 28, 30)
            ..close(),
          hair,
        );
      case _Hair.sweep:
        final sweep = Path()
          ..moveTo(24, 32)
          ..quadraticBezierTo(50, 14, 78, 28)
          ..quadraticBezierTo(58, 36, 30, 40)
          ..close();
        canvas.drawPath(sweep, hair);
        canvas.drawPath(
          sweep,
          Paint()..color = look.hairLight.withValues(alpha: 0.4),
        );
      case _Hair.crop:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(30, 28, 40, 12),
            const Radius.circular(10),
          ),
          hair,
        );
      case _Hair.curls:
        for (final center in const [
          Offset(36, 26),
          Offset(50, 20),
          Offset(64, 26),
          Offset(42, 34),
          Offset(58, 34),
        ]) {
          canvas.drawCircle(center, 7, hair);
          canvas.drawCircle(center.translate(-1.5, -1.5), 2.2, light);
        }
      case _Hair.ponytail:
        canvas.drawPath(
          Path()
            ..moveTo(28, 30)
            ..quadraticBezierTo(40, 44, 50, 32)
            ..quadraticBezierTo(60, 44, 72, 30)
            ..quadraticBezierTo(50, 22, 28, 30)
            ..close(),
          hair,
        );
      case _Hair.waves:
        final wave = Path()
          ..moveTo(26, 32)
          ..quadraticBezierTo(34, 46, 42, 32)
          ..quadraticBezierTo(50, 46, 58, 32)
          ..quadraticBezierTo(66, 44, 74, 30)
          ..quadraticBezierTo(50, 20, 26, 32)
          ..close();
        canvas.drawPath(wave, hair);
      case _Hair.bun:
        canvas.drawPath(
          Path()
            ..moveTo(30, 30)
            ..quadraticBezierTo(42, 42, 50, 32)
            ..quadraticBezierTo(58, 42, 70, 30)
            ..quadraticBezierTo(50, 22, 30, 30)
            ..close(),
          hair,
        );
    }
  }

  void _face(Canvas canvas) {
    void animeEye(Offset center, {required bool left}) {
      // Large anime white
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 15, height: 16),
        Paint()..color = const Color(0xFFFFFDFB),
      );
      // Iris gradient disc
      canvas.drawCircle(
        center.translate(0, 0.8),
        5.6,
        Paint()
          ..shader = RadialGradient(
            colors: [look.irisLight, look.iris],
          ).createShader(
            Rect.fromCircle(center: center.translate(0, 0.8), radius: 5.6),
          ),
      );
      // Pupil
      canvas.drawCircle(
        center.translate(0, 1.0),
        2.4,
        Paint()..color = const Color(0xFF1A1210),
      );
      // Big catchlight + small sparkle
      canvas.drawCircle(
        center.translate(left ? -2.2 : 2.2, -2.4),
        2.0,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        center.translate(left ? 2.0 : -2.0, 1.6),
        1.0,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      // Soft upper lid / lash arc
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(0, -1.2),
          width: 16,
          height: 14,
        ),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        Paint()
          ..color = const Color(0xFF2A1E1A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    animeEye(const Offset(37, 44), left: true);
    animeEye(const Offset(63, 44), left: false);

    // Tiny anime nose (dot)
    canvas.drawCircle(
      const Offset(50, 54),
      1.15,
      Paint()..color = Color.lerp(look.skin, look.blush, 0.55)!,
    );

    // Soft open smile
    canvas.drawArc(
      const Rect.fromLTWH(42, 58, 16, 11),
      0.25,
      2.6,
      false,
      Paint()
        ..color = const Color(0xFF2A1E1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );

    if (look.freckles) {
      final dot = Paint()..color = const Color(0xFFE09A6A).withValues(alpha: 0.9);
      for (final c in const [
        Offset(30, 56),
        Offset(34, 59),
        Offset(29, 60),
        Offset(70, 56),
        Offset(66, 59),
        Offset(71, 60),
      ]) {
        canvas.drawCircle(c, 0.9, dot);
      }
    }

    if (look.glasses) {
      final frames = Paint()
        ..color = const Color(0xFF2A1E1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, 36, 19, 16),
          const Radius.circular(7),
        ),
        frames,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 36, 19, 16),
          const Radius.circular(7),
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

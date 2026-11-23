import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Soft Western picture-book looks for K–5 kids.
/// Keep [id] values stable — they are stored on learners.
enum _Hair { fringe, bob, curls, ponytail, bun, sweep, waves, crop }

class _Look {
  const _Look({
    required this.id,
    required this.skin,
    required this.blush,
    required this.hair,
    required this.shirt,
    required this.backdrop,
    required this.backdropDeep,
    required this.iris,
    required this.hairStyle,
    this.freckles = false,
    this.glasses = false,
  });

  final String id;
  final Color skin;
  final Color blush;
  final Color hair;
  final Color shirt;
  final Color backdrop;
  final Color backdropDeep;
  final Color iris;
  final _Hair hairStyle;
  final bool freckles;
  final bool glasses;
}

const _looks = <_Look>[
  _Look(
    id: 'sunny',
    skin: Color(0xFFF6D2B0),
    blush: Color(0xFFF0A48A),
    hair: Color(0xFFE8B84A),
    shirt: Color(0xFF6FBF9A),
    backdrop: Color(0xFFFFF1C9),
    backdropDeep: Color(0xFFE8F6DF),
    iris: Color(0xFF4A7C59),
    hairStyle: _Hair.fringe,
    freckles: true,
  ),
  _Look(
    id: 'maple',
    skin: Color(0xFFF8DCC4),
    blush: Color(0xFFEFA08C),
    hair: Color(0xFFC45A2C),
    shirt: Color(0xFFFF8F6B),
    backdrop: Color(0xFFFFE0D4),
    backdropDeep: Color(0xFFFFF0EA),
    iris: Color(0xFF4F6F8F),
    hairStyle: _Hair.bob,
  ),
  _Look(
    id: 'river',
    skin: Color(0xFFE2B48A),
    blush: Color(0xFFD98972),
    hair: Color(0xFF3B2A22),
    shirt: Color(0xFF5BA4C9),
    backdrop: Color(0xFFD9EEF8),
    backdropDeep: Color(0xFFEEF7FC),
    iris: Color(0xFF3E6B8A),
    hairStyle: _Hair.curls,
    glasses: true,
  ),
  _Look(
    id: 'cedar',
    skin: Color(0xFF8F5A3C),
    blush: Color(0xFFC57A5E),
    hair: Color(0xFF1F1612),
    shirt: Color(0xFFF0B35A),
    backdrop: Color(0xFFFFE6B8),
    backdropDeep: Color(0xFFFFF4DE),
    iris: Color(0xFF6B4A32),
    hairStyle: _Hair.curls,
  ),
  _Look(
    id: 'wren',
    skin: Color(0xFFF5CEB4),
    blush: Color(0xFFF09A86),
    hair: Color(0xFFD28A3A),
    shirt: Color(0xFFFF7A8A),
    backdrop: Color(0xFFFFD9E0),
    backdropDeep: Color(0xFFFFF0F3),
    iris: Color(0xFF5A7A4A),
    hairStyle: _Hair.ponytail,
  ),
  _Look(
    id: 'noah',
    skin: Color(0xFFE8C09A),
    blush: Color(0xFFE09278),
    hair: Color(0xFF2F221C),
    shirt: Color(0xFF4A6FA5),
    backdrop: Color(0xFFDCE7F7),
    backdropDeep: Color(0xFFEEF3FB),
    iris: Color(0xFF3D5A80),
    hairStyle: _Hair.sweep,
  ),
  _Look(
    id: 'piper',
    skin: Color(0xFFF9D8C2),
    blush: Color(0xFFF2A090),
    hair: Color(0xFFF2D06A),
    shirt: Color(0xFF9B87D4),
    backdrop: Color(0xFFE8DFF8),
    backdropDeep: Color(0xFFF5F0FC),
    iris: Color(0xFF6A5A9A),
    hairStyle: _Hair.waves,
  ),
  _Look(
    id: 'leo',
    skin: Color(0xFFC98B5C),
    blush: Color(0xFFD48A6A),
    hair: Color(0xFF4A2E20),
    shirt: Color(0xFF3F9A74),
    backdrop: Color(0xFFD8F0E4),
    backdropDeep: Color(0xFFECF8F2),
    iris: Color(0xFF3A5A48),
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
        center: const Alignment(-0.25, -0.35),
        radius: 1.15,
        colors: [look.backdropDeep, look.backdrop],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));
    canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), bg);

    // Soft vignette for storybook depth.
    canvas.drawCircle(
      const Offset(50, 112),
      46,
      Paint()..color = Colors.black.withValues(alpha: 0.04),
    );

    final shirt = Paint()..color = look.shirt;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(18, 72, 64, 40),
        topLeft: const Radius.circular(22),
        topRight: const Radius.circular(22),
      ),
      shirt,
    );
    // Collar notch — common in Western kids-app avatars.
    canvas.drawPath(
      Path()
        ..moveTo(42, 74)
        ..lineTo(50, 84)
        ..lineTo(58, 74)
        ..close(),
      Paint()..color = Color.lerp(look.shirt, Colors.white, 0.22)!,
    );

    final skin = Paint()..color = look.skin;
    final hair = Paint()..color = look.hair;
    final hairShade = Paint()
      ..color = Color.lerp(look.hair, const Color(0xFF1A1210), 0.18)!;

    _backHair(canvas, hair, hairShade);

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 64, 14, 14),
        const Radius.circular(7),
      ),
      skin,
    );

    // Soft ears
    canvas.drawOval(const Rect.fromLTWH(24, 44, 10, 13), skin);
    canvas.drawOval(const Rect.fromLTWH(66, 44, 10, 13), skin);

    // Rounder Western kid head (slightly wider cheeks).
    canvas.drawOval(const Rect.fromLTWH(25, 24, 50, 52), skin);

    // Cheek blush before features so eyes sit on top.
    final blush = Paint()..color = look.blush.withValues(alpha: 0.38);
    canvas.drawOval(const Rect.fromLTWH(28, 52, 14, 9), blush);
    canvas.drawOval(const Rect.fromLTWH(58, 52, 14, 9), blush);

    _frontHair(canvas, hair, hairShade);
    _face(canvas);
  }

  void _backHair(Canvas canvas, Paint hair, Paint shade) {
    switch (look.hairStyle) {
      case _Hair.ponytail:
        canvas.drawOval(const Rect.fromLTWH(66, 48, 18, 28), hair);
        canvas.drawOval(const Rect.fromLTWH(70, 54, 12, 22), shade);
        canvas.drawCircle(const Offset(74, 46), 6, hair);
      case _Hair.bun:
        canvas.drawCircle(const Offset(50, 18), 11, hair);
        canvas.drawCircle(const Offset(50, 18), 7, shade);
      case _Hair.curls:
        for (final center in const [
          Offset(26, 34),
          Offset(74, 34),
          Offset(22, 48),
          Offset(78, 48),
          Offset(30, 22),
          Offset(70, 22),
          Offset(24, 60),
          Offset(76, 60),
        ]) {
          canvas.drawCircle(center, 8.5, hair);
        }
      case _Hair.waves:
        canvas.drawOval(const Rect.fromLTWH(18, 40, 18, 34), hair);
        canvas.drawOval(const Rect.fromLTWH(64, 40, 18, 34), hair);
        canvas.drawOval(const Rect.fromLTWH(20, 52, 14, 22), shade);
        canvas.drawOval(const Rect.fromLTWH(66, 52, 14, 22), shade);
      case _Hair.bob:
        canvas.drawOval(const Rect.fromLTWH(18, 34, 16, 36), hair);
        canvas.drawOval(const Rect.fromLTWH(66, 34, 16, 36), hair);
      default:
        break;
    }
  }

  void _frontHair(Canvas canvas, Paint hair, Paint shade) {
    // Soft crown volume.
    canvas.drawOval(const Rect.fromLTWH(24, 16, 52, 34), hair);

    switch (look.hairStyle) {
      case _Hair.fringe:
        final fringe = Path()
          ..moveTo(30, 36)
          ..quadraticBezierTo(38, 44, 42, 36)
          ..quadraticBezierTo(50, 46, 58, 36)
          ..quadraticBezierTo(66, 44, 70, 34)
          ..quadraticBezierTo(50, 28, 30, 36)
          ..close();
        canvas.drawPath(fringe, hair);
      case _Hair.bob:
        canvas.drawOval(const Rect.fromLTWH(28, 28, 18, 12), shade);
        canvas.drawOval(const Rect.fromLTWH(50, 28, 20, 11), hair);
      case _Hair.sweep:
        final sweep = Path()
          ..moveTo(28, 34)
          ..quadraticBezierTo(48, 22, 74, 32)
          ..quadraticBezierTo(56, 38, 34, 40)
          ..close();
        canvas.drawPath(sweep, hair);
        canvas.drawPath(
          sweep,
          Paint()..color = shade.color.withValues(alpha: 0.35),
        );
      case _Hair.crop:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(32, 30, 36, 10),
            const Radius.circular(8),
          ),
          hair,
        );
      case _Hair.curls:
        for (final center in const [
          Offset(38, 28),
          Offset(50, 24),
          Offset(62, 30),
          Offset(44, 34),
          Offset(56, 34),
        ]) {
          canvas.drawCircle(center, 6.2, hair);
        }
      case _Hair.ponytail:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(32, 30, 34, 11),
            const Radius.circular(8),
          ),
          hair,
        );
      case _Hair.waves:
        final wave = Path()
          ..moveTo(28, 34)
          ..quadraticBezierTo(36, 42, 44, 34)
          ..quadraticBezierTo(52, 42, 60, 34)
          ..quadraticBezierTo(68, 40, 72, 32)
          ..quadraticBezierTo(50, 26, 28, 34)
          ..close();
        canvas.drawPath(wave, hair);
      case _Hair.bun:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(34, 30, 32, 10),
            const Radius.circular(8),
          ),
          hair,
        );
    }
  }

  void _face(Canvas canvas) {
    // Soft Western eyes: white, colored iris, dark pupil, single catchlight.
    void eye(Offset center) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 11, height: 9.5),
        Paint()..color = const Color(0xFFFFFDF9),
      );
      canvas.drawCircle(center, 3.4, Paint()..color = look.iris);
      canvas.drawCircle(center, 1.7, Paint()..color = const Color(0xFF2A211C));
      canvas.drawCircle(
        center.translate(-1.1, -1.2),
        1.05,
        Paint()..color = const Color(0xFFFFFDF9),
      );
      // Soft upper lid.
      canvas.drawArc(
        Rect.fromCenter(center: center.translate(0, -0.5), width: 12, height: 10),
        math.pi * 1.1,
        math.pi * 0.75,
        false,
        Paint()
          ..color = const Color(0xFF3A2E28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35
          ..strokeCap = StrokeCap.round,
      );
    }

    eye(const Offset(39, 46));
    eye(const Offset(61, 46));

    // Tiny nose hint (Western storybook, not anime).
    canvas.drawOval(
      const Rect.fromLTWH(47.5, 52.5, 5, 3.2),
      Paint()..color = Color.lerp(look.skin, look.blush, 0.45)!,
    );

    // Friendly open smile.
    final smile = Paint()
      ..color = const Color(0xFF3A2E28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(41, 56, 18, 12),
      0.2,
      2.7,
      false,
      smile,
    );

    if (look.freckles) {
      final dot = Paint()..color = const Color(0xFFC4845A).withValues(alpha: 0.85);
      for (final center in const [
        Offset(33, 54),
        Offset(37, 57),
        Offset(32, 58),
        Offset(67, 54),
        Offset(63, 57),
        Offset(68, 58),
      ]) {
        canvas.drawCircle(center, 0.85, dot);
      }
    }

    if (look.glasses) {
      final frames = Paint()
        ..color = const Color(0xFF3A2E28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(31, 40, 16, 13),
          const Radius.circular(5),
        ),
        frames,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 40, 16, 13),
          const Radius.circular(5),
        ),
        frames,
      );
      canvas.drawLine(
        const Offset(47, 46.5),
        const Offset(53, 46.5),
        frames,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.look != look;
}

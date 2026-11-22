import 'package:flutter/material.dart';

import '../app/theme.dart';

enum _Hair { fringe, bob, curls, ponytail, bun, sweep, waves, crop }

class _Look {
  const _Look({
    required this.id,
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.backdrop,
    required this.hairStyle,
    this.freckles = false,
    this.glasses = false,
  });

  final String id;
  final Color skin;
  final Color hair;
  final Color shirt;
  final Color backdrop;
  final _Hair hairStyle;
  final bool freckles;
  final bool glasses;
}

const _looks = <_Look>[
  _Look(
    id: 'sunny',
    skin: Color(0xFFF3C7A6),
    hair: Color(0xFFE2B15A),
    shirt: Color(0xFF7FA58A),
    backdrop: Color(0xFFF6E7C8),
    hairStyle: _Hair.fringe,
    freckles: true,
  ),
  _Look(
    id: 'maple',
    skin: Color(0xFFF6D2B8),
    hair: Color(0xFFB5522A),
    shirt: Color(0xFFC46A4A),
    backdrop: Color(0xFFF8D9C8),
    hairStyle: _Hair.bob,
  ),
  _Look(
    id: 'river',
    skin: Color(0xFFD9A679),
    hair: Color(0xFF4A3428),
    shirt: Color(0xFF5C8F9A),
    backdrop: Color(0xFFD7E6EA),
    hairStyle: _Hair.curls,
    glasses: true,
  ),
  _Look(
    id: 'cedar',
    skin: Color(0xFF8D5A3C),
    hair: Color(0xFF2A211C),
    shirt: Color(0xFFE0A15A),
    backdrop: Color(0xFFF3E2C4),
    hairStyle: _Hair.curls,
  ),
  _Look(
    id: 'wren',
    skin: Color(0xFFF4CDB4),
    hair: Color(0xFFC9843A),
    shirt: Color(0xFFE07A62),
    backdrop: Color(0xFFF8D5CE),
    hairStyle: _Hair.ponytail,
  ),
  _Look(
    id: 'noah',
    skin: Color(0xFFE4B892),
    hair: Color(0xFF3D2B22),
    shirt: Color(0xFF3E5878),
    backdrop: Color(0xFFD9E1EA),
    hairStyle: _Hair.sweep,
  ),
  _Look(
    id: 'piper',
    skin: Color(0xFFF7D3BC),
    hair: Color(0xFFF0D48A),
    shirt: Color(0xFF8E7BB8),
    backdrop: Color(0xFFE6DEF2),
    hairStyle: _Hair.waves,
  ),
  _Look(
    id: 'leo',
    skin: Color(0xFFC98A5B),
    hair: Color(0xFF5C3A28),
    shirt: Color(0xFF3F7A62),
    backdrop: Color(0xFFD7E7DC),
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
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = look.backdrop,
    );
    final shirt = Paint()..color = look.shirt;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 74, 56, 36),
        const Radius.circular(18),
      ),
      shirt,
    );
    final skin = Paint()..color = look.skin;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(42, 66, 16, 16),
        const Radius.circular(6),
      ),
      skin,
    );
    final hair = Paint()..color = look.hair;
    _backHair(canvas, hair);
    canvas.drawCircle(const Offset(30, 50), 5.5, skin);
    canvas.drawCircle(const Offset(70, 50), 5.5, skin);
    canvas.drawCircle(const Offset(50, 48), 22, skin);
    _frontHair(canvas, hair);
    _face(canvas);
  }

  void _backHair(Canvas canvas, Paint hair) {
    switch (look.hairStyle) {
      case _Hair.ponytail:
        canvas.drawCircle(const Offset(74, 58), 8, hair);
      case _Hair.bun:
        canvas.drawCircle(const Offset(50, 22), 8, hair);
      case _Hair.curls:
        for (final center in const [
          Offset(28, 36),
          Offset(72, 36),
          Offset(24, 50),
          Offset(76, 50),
          Offset(32, 24),
          Offset(68, 24),
        ]) {
          canvas.drawCircle(center, 7, hair);
        }
      case _Hair.waves:
        canvas.drawCircle(const Offset(30, 62), 8, hair);
        canvas.drawCircle(const Offset(70, 62), 8, hair);
      default:
        break;
    }
  }

  void _frontHair(Canvas canvas, Paint hair) {
    final cap = Path()..addOval(const Rect.fromLTWH(28, 22, 44, 20));
    canvas.drawPath(cap, hair);
    switch (look.hairStyle) {
      case _Hair.fringe:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(34, 32, 32, 8),
            const Radius.circular(6),
          ),
          hair,
        );
      case _Hair.bob:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 36, 10, 26),
            const Radius.circular(8),
          ),
          hair,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(66, 36, 10, 26),
            const Radius.circular(8),
          ),
          hair,
        );
      case _Hair.sweep:
        canvas.drawOval(const Rect.fromLTWH(32, 30, 22, 10), hair);
      case _Hair.crop:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(36, 34, 28, 6),
            const Radius.circular(6),
          ),
          hair,
        );
      case _Hair.curls:
        canvas.drawCircle(const Offset(40, 30), 5, hair);
        canvas.drawCircle(const Offset(52, 28), 5, hair);
        canvas.drawCircle(const Offset(62, 32), 4.5, hair);
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(36, 32, 28, 7),
            const Radius.circular(6),
          ),
          hair,
        );
    }
  }

  void _face(Canvas canvas) {
    final ink = Paint()
      ..color = const Color(0xFF3A2E28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFF3A2E28);
    canvas.drawOval(const Rect.fromLTWH(39, 44, 7, 5.5), fill);
    canvas.drawOval(const Rect.fromLTWH(54, 44, 7, 5.5), fill);
    canvas.drawCircle(
      const Offset(41.2, 45.6),
      1.1,
      Paint()..color = const Color(0xFFFFF8F2),
    );
    canvas.drawCircle(
      const Offset(56.2, 45.6),
      1.1,
      Paint()..color = const Color(0xFFFFF8F2),
    );
    canvas.drawArc(
      const Rect.fromLTWH(46.5, 50, 7, 6),
      0.2,
      2.4,
      false,
      ink..strokeWidth = 1.3,
    );
    canvas.drawArc(
      const Rect.fromLTWH(43, 56, 14, 9),
      0.15,
      2.8,
      false,
      ink..strokeWidth = 1.6,
    );
    if (look.freckles) {
      final dot = Paint()..color = const Color(0xFFC4845A);
      for (final center in const [
        Offset(36, 54),
        Offset(39, 57),
        Offset(35, 58),
        Offset(61, 54),
        Offset(64, 57),
        Offset(62, 59),
      ]) {
        canvas.drawCircle(center, 0.8, dot);
      }
    }
    if (look.glasses) {
      final frames = Paint()
        ..color = const Color(0xFF3A2E28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(const Offset(42.5, 46.5), 7, frames);
      canvas.drawCircle(const Offset(57.5, 46.5), 7, frames);
      canvas.drawLine(const Offset(49.5, 46.5), const Offset(50.5, 46.5), frames);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.look != look;
}

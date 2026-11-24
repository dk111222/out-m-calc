import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/core.dart';

/// Illustrated kid portraits for child profiles.
/// Asset files live at `assets/avatars/<id>.jpg`.
String avatarAssetPath(String id) => 'assets/avatars/$id.jpg';

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.id, this.size = 48});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = learnerAvatarIds.contains(id) ? id : learnerAvatarIds.first;
    final radius = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          avatarAssetPath(resolved),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stack) {
            final colors = AppColors.of(context);
            return ColoredBox(
              color: colors.sunken,
              child: Icon(
                Icons.child_care,
                size: size * 0.5,
                color: colors.textMuted,
              ),
            );
          },
        ),
      ),
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
        for (final id in learnerAvatarIds)
          Semantics(
            button: true,
            selected: id == selected,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(id),
              child: AnimatedContainer(
                duration: motionFast,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: id == selected ? colors.accent : colors.border,
                    width: id == selected ? 2.5 : 1,
                  ),
                ),
                child: ChildAvatar(id: id, size: 56),
              ),
            ),
          ),
      ],
    );
  }
}

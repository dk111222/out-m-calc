import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/core.dart';

/// Illustrated kid portraits for child profiles.
/// Asset files live at `assets/avatars/<id>.jpg`.
String avatarAssetPath(String id) => 'assets/avatars/$id.jpg';

/// Warm fallback so a missing asset never leaves a blank chip.
const _fallbackFills = <String, Color>{
  'sprout': Color(0xFFB7D7B8),
  'petal': Color(0xFFF0C0D0),
  'acorn': Color(0xFFA9D0E0),
  'daisy': Color(0xFFE4C48A),
  'sunny': Color(0xFFFFE08A),
  'maple': Color(0xFFFFA07A),
  'river': Color(0xFF64B5F6),
  'cedar': Color(0xFFFFB74D),
  'wren': Color(0xFFFF6B9D),
  'noah': Color(0xFF5C7CFA),
  'piper': Color(0xFFB388FF),
  'leo': Color(0xFF38B2A8),
};

Color _surfaceOf(BuildContext context) {
  return Theme.of(context).extension<AppColors>()?.surface ??
      Theme.of(context).colorScheme.surface;
}

Color _borderOf(BuildContext context) {
  return Theme.of(context).extension<AppColors>()?.border ??
      Theme.of(context).colorScheme.outlineVariant;
}

List<BoxShadow> _shadowOf(BuildContext context) {
  return Theme.of(context).extension<AppColors>()?.cardShadow ?? const [];
}

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({super.key, required this.id, this.size = 48});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved =
        learnerAvatarIds.contains(id) ? id : learnerAvatarIds.first;
    final radius = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _surfaceOf(context),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _borderOf(context), width: 1),
          boxShadow: _shadowOf(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius > 1 ? radius - 0.5 : 0),
          child: Image.asset(
            avatarAssetPath(resolved),
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) {
              debugPrint('Avatar asset failed ($resolved): $error');
              return _AvatarFallback(id: resolved, size: size);
            },
          ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fill = _fallbackFills[id] ?? const Color(0xFFE4C48A);
    return ColoredBox(
      color: fill,
      child: Center(
        child: Text(
          id.isEmpty ? '?' : id[0].toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2330),
          ),
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
    final accent =
        Theme.of(context).extension<AppColors>()?.accent ??
        Theme.of(context).colorScheme.primary;
    final border = _borderOf(context);
    final surface = _surfaceOf(context);
    // Four columns so all twelve portraits stay on the first screen.
    return Material(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s12),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.s8,
          crossAxisSpacing: AppSpace.s8,
          children: [
            for (final id in learnerAvatarIds)
              Semantics(
                button: true,
                selected: id == selected,
                label: id,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelected(id),
                  child: AnimatedContainer(
                    duration: motionFast,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: id == selected ? accent : border,
                        width: id == selected ? 3 : 1.5,
                      ),
                    ),
                    child: Center(child: ChildAvatar(id: id, size: 56)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Warm the decoder so the add-learner picker does not flash empty chips.
Future<void> precacheLearnerAvatars(BuildContext context) async {
  await Future.wait([
    for (final id in learnerAvatarIds)
      precacheImage(AssetImage(avatarAssetPath(id)), context),
  ]);
}

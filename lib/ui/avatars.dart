import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';

/// Illustrated kid + animal portraits for child profiles.
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
  'lion': Color(0xFFFFC94A),
  'seal': Color(0xFFA9D0E0),
  'squirrel': Color(0xFFD4A574),
  'zebra': Color(0xFFE8E4DC),
  'owl': Color(0xFFC4A574),
  'whale': Color(0xFF7EB6D9),
  'giraffe': Color(0xFFE8B86D),
  'peacock': Color(0xFF5BA88A),
  'fox': Color(0xFFE8913A),
  'panda': Color(0xFFD0D0D0),
  'penguin': Color(0xFF9BB5C9),
  'bunny': Color(0xFFE8D4E0),
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
    final t = Copy.of(context);
    final border = _borderOf(context);
    final surface = _surfaceOf(context);
    // Two short horizontal rows keep kids + animals on the first screen.
    return Material(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(t.kidAvatars),
            const SizedBox(height: AppSpace.s8),
            _AvatarRow(
              ids: kidAvatarIds,
              selected: selected,
              onSelected: onSelected,
            ),
            const SizedBox(height: AppSpace.s16),
            _SectionLabel(t.animalAvatars),
            const SizedBox(height: AppSpace.s8),
            _AvatarRow(
              ids: animalAvatarIds,
              selected: selected,
              onSelected: onSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.ids,
    required this.selected,
    required this.onSelected,
  });

  final List<String> ids;
  final String selected;
  final ValueChanged<String> onSelected;

  static const _chip = 56.0;

  @override
  Widget build(BuildContext context) {
    final accent =
        Theme.of(context).extension<AppColors>()?.accent ??
        Theme.of(context).colorScheme.primary;
    final border = _borderOf(context);
    // Eager Row (not ListView.builder) so all 12 chips exist for tests and
    // semantics; the parent page scrolls vertically if needed.
    return SizedBox(
      height: _chip + 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s12),
        child: Row(
          children: [
            for (var i = 0; i < ids.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.s8),
              Semantics(
                button: true,
                selected: ids[i] == selected,
                label: ids[i],
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(ids[i]),
                  child: AnimatedContainer(
                    duration: motionFast,
                    width: _chip,
                    height: _chip,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ids[i] == selected ? accent : border,
                        width: ids[i] == selected ? 3 : 1.5,
                      ),
                    ),
                    child: ChildAvatar(id: ids[i], size: _chip - 8),
                  ),
                ),
              ),
            ],
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

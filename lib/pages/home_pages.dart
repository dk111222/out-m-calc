import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../l10n/trick_zh.dart';
import '../ui/avatars.dart';
import '../ui/kit.dart';
import 'speed_form.dart';

class LoadingPage extends ConsumerWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    return PageFrame(
      title: 'StepMath',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.bootError ?? t.opening,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s16),
          const SkeletonBlock(),
          const SizedBox(height: AppSpace.s16),
          const SkeletonBlock(height: 16),
          if (app.bootError != null) ...[
            const SizedBox(height: AppSpace.s24),
            AppButton(label: t.tryAgain, onPressed: () => app.boot()),
          ],
        ],
      ),
    );
  }
}

class StartPage extends ConsumerWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Copy.of(context);
    return PageFrame(
      title: 'StepMath',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.whoUses, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          Text(t.whoUsesBody, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            label: t.parentOrTeacher,
            onPressed: () => context.go('/learner/new'),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: t.tryAsGuest,
            secondary: true,
            onPressed: () => context.go('/learner/new?guest=1'),
          ),
        ],
      ),
    );
  }
}

class LearnerFormPage extends ConsumerStatefulWidget {
  const LearnerFormPage({super.key, required this.guest});

  final bool guest;

  @override
  ConsumerState<LearnerFormPage> createState() => _LearnerFormPageState();
}

class _LearnerFormPageState extends ConsumerState<LearnerFormPage> {
  late final TextEditingController _name;
  String? _grade;
  String? _avatar;
  String? _error;
  bool _busy = false;

  bool _seededName = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    if (widget.guest) _grade = '1';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheLearnerAvatars(context);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final avatar =
        _avatar ??
        learnerAvatarIds[app.learners.length % learnerAvatarIds.length];
    if (widget.guest && !_seededName) {
      _seededName = true;
      _name.text = t.guest;
    }
    if (!app.settings.signedIn) {
      return PageFrame(
        title: t.addLearner,
        leading: IconButton(
          tooltip: t.back,
          onPressed: () => context.go('/prefs'),
          icon: const Icon(Icons.arrow_back),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.signInToAddLearner),
            const SizedBox(height: AppSpace.s16),
            AppButton(label: t.signIn, onPressed: () => context.go('/sign-in')),
          ],
        ),
      );
    }
    return PageFrame(
      title: widget.guest ? t.guest : t.addLearner,
      banner: app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/prefs'),
        icon: const Icon(Icons.arrow_back),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          0,
          AppSpace.s16,
          AppSpace.s16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s8),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppColors.of(context).danger),
                ),
              ),
            AppButton(
              label: t.save,
              busy: _busy,
              onPressed: _grade == null
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      final error = await app.createLearner(
                        name: _name.text,
                        grade: _grade!,
                        avatar: avatar,
                        guest: widget.guest,
                      );
                      if (!mounted) return;
                      if (error != null) {
                        setState(() {
                          _busy = false;
                          _error = error;
                        });
                        return;
                      }
                      if (!context.mounted) return;
                      if (widget.guest) {
                        await app.enterChild(app.activeLearnerId!);
                        if (!context.mounted) return;
                        context.go('/child');
                      } else {
                        context.go('/prefs');
                      }
                    },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: t.name,
              helperText: widget.guest ? t.guestNameHint : t.learnerNameHint,
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(t.avatarWord, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          AvatarPicker(
            selected: avatar,
            onSelected: (value) => setState(() => _avatar = value),
          ),
          const SizedBox(height: AppSpace.s16),
          Text(t.gradeWord, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          // Compact chips keep grade + both avatar rows on the first screen.
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              for (final grade in grades)
                ChoiceChip(
                  label: Text(t.grade(grade)),
                  selected: _grade == grade,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _grade = grade);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdultHomePage extends ConsumerWidget {
  const AdultHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    return PageFrame(
      title: t.learners,
      banner: app.banner,
      actions: [
        IconButton(
          tooltip: t.settings,
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings),
        ),
      ],
      body: app.learners.isEmpty
          ? _empty(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final learner in app.learners)
                  _LearnerRow(learner: learner),
                AppButton(
                  label: t.addLearner,
                  onPressed: () => context.go('/learner/new'),
                ),
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: t.tryAsGuest,
                  secondary: true,
                  onPressed: () => context.go('/learner/new?guest=1'),
                ),
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: t.scanPaper,
                  secondary: true,
                  onPressed: app.active == null
                      ? null
                      : () => context.go('/scan'),
                ),
              ],
            ),
    );
  }

  Widget _empty(BuildContext context) {
    final t = Copy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.addLearnerToStart,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: t.addLearner,
          onPressed: () => context.go('/learner/new'),
        ),
      ],
    );
  }
}

class LearnerHub extends ConsumerWidget {
  const LearnerHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final empty = app.learners.isEmpty;
    final signedIn = app.settings.signedIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.learners,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (signedIn)
              TextButton(
                onPressed: () => openLearnerForm(context, guest: false),
                child: Text(t.addLearner),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s8),
        if (empty)
          Text(
            signedIn ? t.addLearnerFirst : t.signInToAddLearner,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final learner in app.learners) _LearnerRow(learner: learner),
        if (!signedIn && !empty) ...[
          const SizedBox(height: AppSpace.s8),
          Text(
            t.signInToAddLearner,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

void openLearnerForm(BuildContext context, {required bool guest}) {
  context.go(guest ? '/learner/new?guest=1' : '/learner/new');
}

Future<void> _openLearner(
  BuildContext context,
  WidgetRef ref,
  String loc,
) async {
  final app = ref.read(appProvider);
  final learnerId = loc.split('/').last.split('?').first;
  final id = loc.contains('learner=')
      ? Uri.parse(loc).queryParameters['learner']
      : learnerId;
  if (app.childMode && id != null && app.activeLearnerId != id) {
    await app.enterChild(id);
  }
  if (context.mounted) context.go(loc);
}

class _LearnerRow extends ConsumerWidget {
  const _LearnerRow({required this.learner});

  final Learner learner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final guest = learner.isGuest ? '${t.guest} · ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrickCard(
            leading: ChildAvatar(id: learner.avatar, size: 48),
            title: learner.displayName,
            caption:
                '$guest${t.grade(learner.grade)} · ${t.dayStreak(learner.streakCount)}',
            onPressed: () async {
              await app.enterChild(learner.id);
              if (context.mounted) context.go('/child');
            },
          ),
          Wrap(
            spacing: AppSpace.s8,
            runSpacing: AppSpace.s8,
            children: [
              OutlinedButton(
                onPressed: () =>
                    _openLearner(context, ref, '/report/${learner.id}'),
                child: Text(t.report),
              ),
              OutlinedButton(
                onPressed: () =>
                    _openLearner(context, ref, '/tricks?learner=${learner.id}'),
                child: Text(t.trickLibrary),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s16),
        ],
      ),
    );
  }
}

class ChildHomePage extends ConsumerWidget {
  const ChildHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final learner = app.active;
    final t = Copy.of(context);
    if (learner == null) {
      return PageFrame(title: t.todayPractice, body: Text(t.addLearnerFirst));
    }
    final drills = factDrills(learner.grade);
    final mine = app.catalog
        .forGrade(learner.grade)
        .where((trick) => trick.ready)
        .take(3);
    return PageFrame(
      title: t.todayPractice,
      banner: app.banner,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LearnerHomeCard(
            avatarId: learner.avatar,
            name: learner.displayName,
            gradeLabel: t.grade(learner.grade),
            streakLabel: t.dayStreak(learner.streakCount),
            streakNotice: learner.streakNotice == 'held'
                ? t.skipKept
                : learner.streakNotice == 'reset'
                ? t.streakReset
                : null,
            onTraining: () => context.go('/report/${learner.id}'),
            onWrongBook: () => context.go('/review'),
            onPhotoGrade: () => context.go('/scan'),
          ),
          const SizedBox(height: AppSpace.s16),
          _DailyPracticeCard(
            tally: app.todayDaily,
            stars: app.todayDailyStars,
            onPressed: () => _startDaily(context, ref, learner.grade),
          ),
          const SizedBox(height: AppSpace.s16),
          _TrainingCard(
            children: [
              _SpeedHomeCard(
                level: learner.grade,
                initial: speedForLevel(
                  speedDefault(learner.grade),
                  learner.grade,
                ),
                onStart: (config) => _openSpeed(context, ref, config),
              ),
              _SectionLabel(
                title: t.mathTricks,
                onPressed: () => context.go('/tricks'),
              ),
              for (final trick in mine)
                _PracticeRow(
                  title: localizeTrick(trick, t).title,
                  caption: trick.example.prompt,
                  onPressed: () => context.go('/tricks/${trick.id}'),
                ),
              _SectionLabel(
                title: t.facts,
                onPressed: () => context.go('/tricks?tab=facts'),
              ),
              for (final drill in drills)
                _PracticeRow(
                  title: t.factTitle(drill.title),
                  caption: drill.sample,
                  onPressed: () => _startDrill(context, ref, drill.config),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openSpeed(
    BuildContext context,
    WidgetRef ref,
    SpeedConfig config,
  ) async {
    await ref.read(speedProvider).start(config);
    if (context.mounted) context.go('/speed/run');
  }

  Future<void> _startDaily(
    BuildContext context,
    WidgetRef ref,
    String grade,
  ) async {
    final app = ref.read(appProvider);
    final snapshot = app.snapshot;
    final open = openDailyPractice(snapshot, grade, app.clock.today);
    if (snapshot != null && open != null) {
      await ref.read(speedProvider).resume(snapshot);
    } else {
      await ref.read(speedProvider).start(dailyPractice(grade));
    }
    if (context.mounted) context.go('/speed/run');
  }

  Future<void> _startDrill(
    BuildContext context,
    WidgetRef ref,
    SpeedConfig config,
  ) async {
    await ref.read(speedProvider).start(config);
    if (context.mounted) context.go('/speed/run');
  }
}

class _LearnerHomeCard extends StatelessWidget {
  const _LearnerHomeCard({
    required this.avatarId,
    required this.name,
    required this.gradeLabel,
    required this.streakLabel,
    required this.onTraining,
    required this.onWrongBook,
    required this.onPhotoGrade,
    this.streakNotice,
  });

  final String avatarId;
  final String name;
  final String gradeLabel;
  final String streakLabel;
  final String? streakNotice;
  final VoidCallback onTraining;
  final VoidCallback onWrongBook;
  final VoidCallback onPhotoGrade;

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChildAvatar(id: avatarId, size: 64),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        '${t.learningStage} · $gradeLabel',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        streakLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      if (streakNotice != null) ...[
                        const SizedBox(height: AppSpace.s8),
                        Text(
                          streakNotice!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.sunken,
                borderRadius: BorderRadius.circular(AppSpace.rSm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _LearnerHomeAction(
                      icon: Icons.insights_outlined,
                      label: t.trainingStatus,
                      onPressed: onTraining,
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colors.border,
                    ),
                  ),
                  Expanded(
                    child: _LearnerHomeAction(
                      icon: Icons.menu_book_outlined,
                      label: t.wrongProblems,
                      onPressed: onWrongBook,
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colors.border,
                    ),
                  ),
                  Expanded(
                    child: _LearnerHomeAction(
                      icon: Icons.photo_camera_outlined,
                      label: t.scanPaper,
                      onPressed: onPhotoGrade,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnerHomeAction extends StatelessWidget {
  const _LearnerHomeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpace.rSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpace.s12,
            horizontal: AppSpace.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colors.accent),
              const SizedBox(height: AppSpace.s4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPracticeCard extends StatelessWidget {
  const _DailyPracticeCard({
    required this.tally,
    required this.stars,
    required this.onPressed,
  });

  final DailyPracticeTally tally;
  final int stars;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.rMd),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.dailyPractice,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    _DailyStars(stars: stars),
                  ],
                ),
                const SizedBox(height: AppSpace.s12),
                Row(
                  children: [
                    Expanded(
                      child: _DailyFigure(
                        value: '${tally.answered}',
                        label: t.problemCount,
                      ),
                    ),
                    const _DailyDash(),
                    Expanded(
                      child: _DailyFigure(
                        value: tally.accuracyLabel,
                        label: t.accuracy,
                      ),
                    ),
                    const _DailyDash(),
                    Expanded(
                      child: _DailyFigure(
                        value: clockLabel(tally.durationMs),
                        label: t.practiceTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyStars extends StatelessWidget {
  const _DailyStars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final earned = stars.clamp(0, 3);
    return Semantics(
      container: true,
      label: '$earned',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < earned ? Icons.star_rounded : Icons.star_border_rounded,
              size: 20,
              color: i < earned ? colors.warning : colors.textMuted,
            ),
        ],
      ),
    );
  }
}

class _DailyDash extends StatelessWidget {
  const _DailyDash();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 8,
      height: 40,
      child: CustomPaint(
        painter: _DailyDashPainter(AppColors.of(context).textMuted),
      ),
    );
  }
}

class _DailyDashPainter extends CustomPainter {
  const _DailyDashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dash = 3.0;
    const gap = 3.0;
    final x = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final end = y + dash > size.height ? size.height : y + dash;
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DailyDashPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _DailyFigure extends StatelessWidget {
  const _DailyFigure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: AppSpace.s4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final lines = <Widget>[];
    Widget? previous;
    for (final child in children) {
      if (previous != null &&
          (child is _SectionLabel || previous is! _SectionLabel)) {
        lines.add(Divider(height: 1, thickness: 1, color: colors.border));
      }
      lines.add(child);
      previous = child;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.rMd),
          side: BorderSide(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: lines,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s16,
          AppSpace.s16,
          AppSpace.s16,
          AppSpace.s8,
        ),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.title,
    required this.onPressed,
    this.caption = '',
    this.trailing,
  });

  final String title;
  final String caption;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: enabled ? colors.text : colors.textMuted,
                      ),
                    ),
                    if (caption.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        caption,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (enabled) Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedHomeCard extends StatefulWidget {
  const _SpeedHomeCard({
    required this.level,
    required this.initial,
    required this.onStart,
  });

  final String level;
  final SpeedConfig initial;
  final Future<void> Function(SpeedConfig config) onStart;

  @override
  State<_SpeedHomeCard> createState() => _SpeedHomeCardState();
}

class _SpeedHomeCardState extends State<_SpeedHomeCard> {
  late SpeedConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final summary = _config.summary(language: t.language);
    return _PracticeRow(
      title: t.speedDrill,
      caption: summary,
      onPressed: () => widget.onStart(_config),
      trailing: IconButton(
        tooltip: t.settings,
        onPressed: () async {
          final next = await showSpeedSetupDialog(
            context,
            config: _config,
            level: widget.level,
          );
          if (next != null && mounted) {
            setState(() => _config = next);
          }
        },
        icon: const Icon(Icons.settings),
      ),
    );
  }
}

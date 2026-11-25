import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../l10n/trick_zh.dart';
import '../ui/avatars.dart';
import '../ui/gates.dart';
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
          RadioGroup<String>(
            groupValue: _grade,
            onChanged: (value) => setState(() => _grade = value),
            child: Column(
              children: [
                for (final grade in grades)
                  RadioListTile<String>(
                    value: grade,
                    title: Text(t.grade(grade)),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.learners, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        if (empty) ...[
          Text(t.whoUsesBody, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpace.s16),
        ] else
          for (final learner in app.learners) _LearnerRow(learner: learner),
        AppButton(
          label: empty ? t.parentOrTeacher : t.addLearner,
          onPressed: () => openLearnerForm(context, ref, guest: false),
        ),
        const SizedBox(height: AppSpace.s12),
        AppButton(
          label: t.tryAsGuest,
          secondary: true,
          onPressed: () => openLearnerForm(context, ref, guest: true),
        ),
      ],
    );
  }
}

Future<void> openLearnerForm(
  BuildContext context,
  WidgetRef ref, {
  required bool guest,
}) async {
  final app = ref.read(appProvider);
  if (app.childMode) {
    final ok = await requireParentCode(
      context,
      app,
      title: app.copy.parentCode,
      body: app.copy.pick(
        '请输入家长密码，再管理孩子。',
        'Enter the parent code to manage learners.',
      ),
      action: (pin, again) => app.leaveChild(pin, again: again),
    );
    if (!ok || !context.mounted) return;
  }
  if (!context.mounted) return;
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
    final assignment = app.today[learner.id];
    final assigned = assignment == null
        ? null
        : app.catalog.byId(assignment.trickId ?? '');
    final task = assignment == null
        ? t.nothingAssigned
        : assignment.kind == 'learn'
        ? (assigned == null ? t.learnATrick : localizeTrick(assigned, t).title)
        : (assignment.parsedSpeed?.summary(language: t.language) ??
              t.speedDrill);
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
                '$guest${t.grade(learner.grade)} · ${t.dayStreak(learner.streakCount)} · $task',
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
                    _openLearner(context, ref, '/assign/${learner.id}'),
                child: Text(t.assign),
              ),
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
      return PageFrame(
        title: t.todayPractice,
        body: Text(t.addLearnerFirst),
      );
    }
    final assignment = app.today[learner.id];
    final learnTrick = assignment?.kind == 'learn'
        ? app.catalog.byId(assignment?.trickId ?? '')
        : null;
    final speed = assignment?.kind == 'speed' ? assignment?.parsedSpeed : null;
    final seen =
        learnTrick != null &&
        learner.seenLessons[learnTrick.id] == app.clock.today;
    final drills = factDrills(learner.grade);
    final mine = app.catalog
        .forGrade(learner.grade)
        .where((trick) => trick.ready)
        .take(3);
    final colors = AppColors.of(context);
    return PageFrame(
      title: t.todayPractice,
      banner: app.banner,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChildAvatar(id: learner.avatar, size: 48),
              const SizedBox(width: AppSpace.s12),
              Expanded(
                child: Text(
                  learner.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s12,
                  vertical: AppSpace.s8,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpace.rPill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(t.grade(learner.grade)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          Text(
            t.dayStreak(learner.streakCount),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (learner.streakNotice == 'held') ...[
            const SizedBox(height: AppSpace.s8),
            Text(t.skipKept),
          ],
          if (learner.streakNotice == 'reset') ...[
            const SizedBox(height: AppSpace.s8),
            Text(t.streakReset),
          ],
          const SizedBox(height: AppSpace.s16),
          if (app.snapshot != null &&
              app.snapshot!.localDate == app.clock.today)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s16),
              child: AppButton(
                label: t.continueLabel,
                onPressed: () => _continue(context, ref),
              ),
            ),
          _DailyCard(
            learnerId: learner.id,
            onStart: () => _startDaily(context, ref, learner.grade),
          ),
          const SizedBox(height: AppSpace.s16),
          _SpeedHomeCard(
            level: learner.grade,
            initial: speedForLevel(
              speed ?? speedDefault(learner.grade),
              learner.grade,
            ),
            onStart: (config) => _openSpeed(context, ref, config),
          ),
          const SizedBox(height: AppSpace.s16),
          InkWell(
            onTap: () => _openLearn(context, ref, learnTrick, seen),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
              child: Text(
                t.mathTricks,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final trick in mine)
            TrickCard(
              title: localizeTrick(trick, t).title,
              caption: trick.example.prompt,
              onPressed: () => context.go('/tricks/${trick.id}'),
            ),
          InkWell(
            onTap: () => context.go('/tricks?tab=facts'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
              child: Text(
                t.facts,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          for (final drill in drills)
            TrickCard(
              title: t.factTitle(drill.title),
              caption: drill.sample,
              onPressed: () => _startDrill(context, ref, drill.config),
            ),
          TextButton(
            onPressed: () => context.go('/review'),
            child: Text(t.wrongProblems),
          ),
          TextButton(
            onPressed: () => context.go('/scan'),
            child: Text(t.scanPaper),
          ),
        ],
      ),
    );
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    final app = ref.read(appProvider);
    final snapshot = app.snapshot;
    if (snapshot == null) return;
    if (snapshot.module == 'speed') {
      await ref.read(speedProvider).resume(snapshot);
      if (context.mounted) context.go('/speed/run');
      return;
    }
    await ref.read(practiceProvider).resume(snapshot);
    final view = ref.read(practiceProvider).view;
    if (view != null && context.mounted) {
      context.go('/practice/${view.trickId}/${view.phase}');
    }
  }

  Future<void> _openLearn(
    BuildContext context,
    WidgetRef ref,
    dynamic trick,
    bool seen,
  ) async {
    if (trick == null) {
      context.go('/tricks');
      return;
    }
    if (!seen) {
      context.go('/tricks/${trick.id}');
      return;
    }
    await ref.read(practiceProvider).startLearn(trick.id as String);
    final view = ref.read(practiceProvider).view;
    if (view != null && context.mounted) {
      context.go('/practice/${trick.id}/${view.phase}');
    }
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
    await ref.read(speedProvider).start(dailyPractice(grade));
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

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.learnerId, required this.onStart});

  final String learnerId;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    return TrickCard(
      key: ValueKey(learnerId),
      title: t.dailyPractice,
      caption: t.tenProblems,
      onPressed: onStart,
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
    final colors = AppColors.of(context);
    final summary = _config.summary(language: t.language);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpace.rMd),
          onTap: () => widget.onStart(_config),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s16,
                AppSpace.s8,
                AppSpace.s4,
                AppSpace.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.speedDrill,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpace.s4),
                        Text(
                          summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AssignPage extends ConsumerStatefulWidget {
  const AssignPage({super.key, required this.learnerId});

  final String learnerId;

  @override
  ConsumerState<AssignPage> createState() => _AssignPageState();
}

class _AssignPageState extends ConsumerState<AssignPage> {
  String _kind = 'learn';
  String? _trickId;
  bool _later = false;
  late SpeedConfig _speed;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final learner = ref.read(appProvider).learnerById(widget.learnerId);
    _speed = speedDefault(learner?.grade ?? '1');
    _ready = true;
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final learner = app.learnerById(widget.learnerId);
    final t = Copy.of(context);
    if (!_ready || learner == null) {
      return PageFrame(title: t.assign, body: const SkeletonBlock());
    }
    final mine = app.catalog.forGrade(learner.grade);
    final later = app.catalog.tricks.where(
      (trick) => canonicalGrade(trick.grade) != canonicalGrade(learner.grade),
    );
    return PageFrame(
      title: t.assign,
      banner: app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            learner.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s12),
          TrickCard(
            title: t.learnATrick,
            caption: t.pick('先看步骤，再做几道题。', 'Steps, then a short quiz.'),
            onPressed: () => setState(() => _kind = 'learn'),
          ),
          TrickCard(
            title: t.speedDrill,
            caption: _speed.summary(language: t.language),
            onPressed: () => setState(() => _kind = 'speed'),
          ),
          if (_kind == 'learn') ...[
            Text(t.thisGrade, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s8),
            for (final trick in mine)
              _pick(
                trick.id,
                localizeTrick(trick, t).title,
                trick.id == _trickId,
              ),
            ExpansionTile(
              title: Text(t.laterGrades),
              initiallyExpanded: _later,
              onExpansionChanged: (value) => setState(() => _later = value),
              children: [
                for (final trick in later)
                  _pick(
                    trick.id,
                    '${localizeTrick(trick, t).title} · ${t.grade(trick.grade)}',
                    trick.id == _trickId,
                  ),
              ],
            ),
          ] else
            SpeedForm(
              level: learner.grade,
              config: _speed,
              onChanged: (value) => setState(() => _speed = value),
            ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: t.saveToday,
            onPressed: _kind == 'learn' && _trickId == null
                ? null
                : () async {
                    final now = app.clock.now().toUtc();
                    await app.saveAssignment(
                      Assignment(
                        id: newId(),
                        learnerId: learner.id,
                        localDate: app.clock.today,
                        kind: _kind,
                        trickId: _kind == 'learn' ? _trickId : null,
                        speedConfig: _kind == 'speed'
                            ? jsonEncode(_speed.toJson())
                            : null,
                        status: 'open',
                        createdAt: now,
                        updatedAt: now,
                      ),
                    );
                    if (context.mounted && app.banner == null)
                      context.go('/adult');
                  },
          ),
        ],
      ),
    );
  }

  Widget _pick(String id, String title, bool selected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      onTap: () => setState(() => _trickId = id),
    );
  }
}

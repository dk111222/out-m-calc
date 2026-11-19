import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../ui/gates.dart';
import '../ui/kit.dart';
import 'speed_pages.dart';

class LoadingPage extends ConsumerWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    return PageFrame(
      title: 'StepMath',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.bootError ?? 'Opening practice on this device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s16),
          const SkeletonBlock(),
          const SizedBox(height: AppSpace.s16),
          const SkeletonBlock(height: 16),
          if (app.bootError != null) ...[
            const SizedBox(height: AppSpace.s24),
            AppButton(label: 'Try again', onPressed: () => app.boot()),
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
    return PageFrame(
      title: 'StepMath',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is using this device?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            'A parent or teacher sets up learners. A guest can practice without a name.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            label: 'Parent or teacher',
            onPressed: () => context.go('/learner/new'),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: 'Try as a guest',
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
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.guest ? 'Guest' : '');
    if (widget.guest) _grade = '1';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    return PageFrame(
      title: widget.guest ? 'Guest' : 'Add a learner',
      banner: app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => app.learners.isEmpty ? context.go('/start') : context.go('/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: 'Name',
              helperText: widget.guest
                  ? 'Leave this blank to use Guest.'
                  : 'Leave this blank to use Learner and a number.',
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Grade', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          RadioGroup<String>(
            groupValue: _grade,
            onChanged: (value) => setState(() => _grade = value),
            child: Column(
              children: [
                for (final grade in grades)
                  RadioListTile<String>(
                    value: grade,
                    title: Text(gradeLabel(grade)),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: AppColors.of(context).danger)),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Save',
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
                      context.go('/adult');
                    }
                  },
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
    return PageFrame(
      title: 'Learners',
      banner: app.banner,
      actions: [
        IconButton(
          tooltip: 'Settings',
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
                  label: 'Add a learner',
                  onPressed: () => context.go('/learner/new'),
                ),
                const SizedBox(height: AppSpace.s12),
                AppButton(
                  label: 'Try as a guest',
                  secondary: true,
                  onPressed: () => context.go('/learner/new?guest=1'),
                ),
              ],
            ),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add a learner to start.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Add a learner',
          onPressed: () => context.go('/learner/new'),
        ),
      ],
    );
  }
}

class _LearnerRow extends ConsumerWidget {
  const _LearnerRow({required this.learner});

  final Learner learner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final assignment = app.today[learner.id];
    final task = assignment == null
        ? 'Nothing assigned today'
        : assignment.kind == 'learn'
        ? (app.catalog.byId(assignment.trickId ?? '')?.title ?? 'Learn a trick')
        : (assignment.parsedSpeed?.summary ?? 'Speed drill');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrickCard(
            title: learner.displayName,
            caption:
                '${learner.isGuest ? 'Guest · ' : ''}${gradeLabel(learner.grade)} · ${learner.streakCount} day streak · $task',
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
                onPressed: () => context.go('/assign/${learner.id}'),
                child: const Text('Assign'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/report/${learner.id}'),
                child: const Text('Report'),
              ),
              OutlinedButton(
                onPressed: () => context.go('/tricks?learner=${learner.id}'),
                child: const Text('Trick library'),
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
    if (learner == null) {
      return const PageFrame(
        title: "Today's practice",
        body: Text('Add a learner first.'),
      );
    }
    final assignment = app.today[learner.id];
    final learnTrick = assignment?.kind == 'learn'
        ? app.catalog.byId(assignment?.trickId ?? '')
        : null;
    final speed = assignment?.kind == 'speed' ? assignment?.parsedSpeed : null;
    final seen = learnTrick != null && learner.seenLessons[learnTrick.id] == app.clock.today;
    return PageFrame(
      title: "Today's practice",
      banner: app.banner,
      actions: [
        IconButton(
          tooltip: 'Text size and sound',
          onPressed: () => context.go('/prefs'),
          icon: const Icon(Icons.text_fields),
        ),
        IconButton(
          tooltip: 'Leave',
          onPressed: () async {
            final ok = await requireParentCode(
              context,
              app,
              title: 'Parent code',
              body: app.settings.parentPinHash == null
                  ? 'Set a four-digit code before leaving practice.'
                  : 'Enter the parent code to leave practice.',
              action: (pin, again) => app.leaveChild(pin, again: again),
            );
            if (ok && context.mounted) context.go('/adult');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(learner.displayName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s4),
          Text(
            '${gradeLabel(learner.grade)} · ${learner.streakCount} day streak',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (learner.isGuest) ...[
            const SizedBox(height: AppSpace.s8),
            const Text(
              'Guest profile on this device. Progress stays here until a parent deletes it.',
            ),
          ],
          if (learner.streakNotice == 'held') ...[
            const SizedBox(height: AppSpace.s8),
            const Text("This week's skip kept the streak."),
          ],
          if (learner.streakNotice == 'reset') ...[
            const SizedBox(height: AppSpace.s8),
            const Text('The streak started over.'),
          ],
          const SizedBox(height: AppSpace.s16),
          if (app.snapshot != null && app.snapshot!.localDate == app.clock.today)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s16),
              child: AppButton(
                label: 'Continue',
                onPressed: () => _continue(context, ref),
              ),
            ),
          TrickCard(
            title: 'Math Tricks',
            caption: learnTrick?.title ??
                (assignment == null
                    ? 'Ask a parent to assign today'
                    : 'Not assigned today'),
            onPressed: () => _openLearn(context, ref, learnTrick, seen),
          ),
          TrickCard(
            title: 'Speed Drill',
            caption: speed?.summary ??
                (assignment == null
                    ? 'Ask a parent to assign today'
                    : 'Not assigned today'),
            onPressed: () => _openSpeed(context, ref, speed, learner.grade),
          ),
          AppButton(
            label: 'Wrong problems',
            secondary: true,
            onPressed: () => context.go('/review'),
          ),
          const SizedBox(height: AppSpace.s12),
          AppButton(
            label: 'Trick library',
            secondary: true,
            onPressed: () => context.go('/tricks'),
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
    SpeedConfig? config,
    String grade,
  ) async {
    if (config == null) {
      context.go('/speed/setup');
      return;
    }
    await ref.read(speedProvider).start(config);
    if (context.mounted) context.go('/speed/run');
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
    if (!_ready || learner == null) {
      return const PageFrame(title: 'Assign', body: SkeletonBlock());
    }
    final mine = app.catalog.forGrade(learner.grade);
    final later = app.catalog.tricks.where((trick) => trick.grade != learner.grade);
    return PageFrame(
      title: 'Assign',
      banner: app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go('/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(learner.displayName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s12),
          TrickCard(
            title: 'Learn a trick',
            caption: 'Steps, then a short quiz.',
            onPressed: () => setState(() => _kind = 'learn'),
          ),
          TrickCard(
            title: 'Speed drill',
            caption: _speed.summary,
            onPressed: () => setState(() => _kind = 'speed'),
          ),
          if (_kind == 'learn') ...[
            Text('This grade', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s8),
            for (final trick in mine)
              _pick(trick.id, trick.title, trick.id == _trickId),
            ExpansionTile(
              title: const Text('Later grades'),
              initiallyExpanded: _later,
              onExpansionChanged: (value) => setState(() => _later = value),
              children: [
                for (final trick in later)
                  _pick(trick.id, '${trick.title} · ${gradeLabel(trick.grade)}', trick.id == _trickId),
              ],
            ),
          ] else
            SpeedForm(
              config: _speed,
              onChanged: (value) => setState(() => _speed = value),
            ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Save today',
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
                    if (context.mounted && app.banner == null) context.go('/adult');
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
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      onTap: () => setState(() => _trickId = id),
    );
  }
}

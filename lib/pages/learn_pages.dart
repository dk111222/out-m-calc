import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/catalog.dart';
import '../domain/core.dart';
import '../domain/engine.dart';
import '../domain/machines.dart';
import '../ui/kit.dart';

class TricksPage extends ConsumerStatefulWidget {
  const TricksPage({super.key, this.learnerId});

  final String? learnerId;

  @override
  ConsumerState<TricksPage> createState() => _TricksPageState();
}

class _TricksPageState extends ConsumerState<TricksPage> {
  bool _savedOnly = false;
  bool _loading = true;
  String? _error;
  Map<String, Mastery> _mastery = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = ref.read(appProvider);
    final id = widget.learnerId ?? app.activeLearnerId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await app.store.masteries(id);
      if (!mounted) return;
      setState(() {
        _mastery = {for (final row in rows) row.trickId: row};
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final learner = app.learnerById(widget.learnerId ?? app.activeLearnerId);
    final tricks = learner == null
        ? const <Trick>[]
        : app.catalog.tricks.where((trick) {
            if (_savedOnly && !(learner.favorites.contains(trick.id))) {
              return false;
            }
            return true;
          }).toList();
    final groups = ['addition', 'subtraction', 'multiplication', 'division', 'percent'];
    return PageFrame(
      title: 'Math Tricks',
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: learner == null
          ? const Text('Add a learner first.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(gradeLabel(learner.grade), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpace.s12),
                Wrap(
                  spacing: AppSpace.s8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = false),
                    ),
                    ChoiceChip(
                      label: const Text('Saved'),
                      selected: _savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
                if (_loading)
                  const SkeletonBlock()
                else if (tricks.isEmpty)
                  const Text('No tricks for this grade yet')
                else
                  for (final operation in groups)
                    _Group(
                      title: operationLabel(operation),
                      tricks: tricks.where((trick) => trick.operation == operation).toList(),
                      learner: learner,
                      mastery: _mastery,
                      childMode: app.childMode,
                    ),
              ],
            ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.tricks,
    required this.learner,
    required this.mastery,
    required this.childMode,
  });

  final String title;
  final List<Trick> tricks;
  final Learner learner;
  final Map<String, Mastery> mastery;
  final bool childMode;

  @override
  Widget build(BuildContext context) {
    if (tricks.isEmpty) return const SizedBox.shrink();
    final current = tricks.where((trick) => trick.grade == learner.grade).toList();
    final later = tricks.where((trick) => trick.grade != learner.grade).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        for (final trick in current)
          _card(context, trick, locked: false),
        if (later.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Later grades'),
            children: [
              for (final trick in later)
                _card(context, trick, locked: childMode),
            ],
          ),
        const SizedBox(height: AppSpace.s8),
      ],
    );
  }

  Widget _card(BuildContext context, Trick trick, {required bool locked}) {
    return TrickCard(
      title: trick.title,
      caption: locked
          ? 'This trick is for a later grade.'
          : '${gradeLabel(trick.grade)} · ${trick.shortRange}',
      mastered: mastery[trick.id]?.mastered ?? false,
      saved: learner.favorites.contains(trick.id),
      onPressed: locked ? null : () => context.go('/tricks/${trick.id}?learner=${learner.id}'),
    );
  }
}

class TrickDetailPage extends ConsumerStatefulWidget {
  const TrickDetailPage({super.key, required this.id, this.learnerId});

  final String id;
  final String? learnerId;

  @override
  ConsumerState<TrickDetailPage> createState() => _TrickDetailPageState();
}

class _TrickDetailPageState extends ConsumerState<TrickDetailPage> {
  bool _loading = true;
  int _correct = 0;
  int _answered = 0;
  bool _mastered = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = ref.read(appProvider);
    final learnerId = widget.learnerId ?? app.activeLearnerId;
    if (learnerId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final attempts = await app.store.attempts(learnerId);
      final mastery = await app.store.mastery(learnerId, widget.id);
      final finals = attempts
          .where((attempt) => attempt.trickId == widget.id && attempt.mode == 'final')
          .toList();
      final last = finals.length > 20 ? finals.sublist(finals.length - 20) : finals;
      if (!mounted) return;
      setState(() {
        _answered = last.length;
        _correct = last.where((attempt) => attempt.correct).length;
        _mastered = mastery?.mastered ?? false;
        _loading = false;
      });
      final learner = app.learnerById(learnerId);
      if (learner != null && learner.seenLessons[widget.id] != app.clock.today) {
        await app.markLessonSeen(learnerId, widget.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final trick = app.catalog.byId(widget.id);
    final learner = app.learnerById(widget.learnerId ?? app.activeLearnerId);
    if (trick == null || learner == null) {
      return PageFrame(
        title: 'Math Tricks',
        body: const Text('This trick is not on this device.'),
      );
    }
    final later = _rank(trick.grade) > _rank(learner.grade) && app.childMode;
    final saved = learner.favorites.contains(trick.id);
    final colors = AppColors.of(context);
    return PageFrame(
      title: trick.title,
      banner: app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go('/tricks?learner=${learner.id}'),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: saved ? 'Saved' : 'Save',
          onPressed: () => app.toggleFavorite(learner.id, trick.id),
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(gradeLabel(trick.grade), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.s16),
          if (_loading)
            const SkeletonBlock(height: 48)
          else
            ProgressChart(
              correct: _correct,
              answered: _answered,
              mastered: _mastered,
            ),
          const SizedBox(height: AppSpace.s24),
          Text('Use this when', style: Theme.of(context).textTheme.titleMedium),
          Text(trick.appliesWhen),
          const SizedBox(height: AppSpace.s16),
          Text('Not for', style: Theme.of(context).textTheme.titleMedium),
          Text(trick.notWhen),
          const SizedBox(height: AppSpace.s16),
          Text('Steps', style: Theme.of(context).textTheme.titleMedium),
          for (final step in trick.steps) ...[
            const SizedBox(height: AppSpace.s8),
            Text(
              '${step.number}. ${step.title}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.step(step.number),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(step.body),
          ],
          const SizedBox(height: AppSpace.s16),
          _Diagram(trick: trick),
          const SizedBox(height: AppSpace.s8),
          Text('Short range: ${trick.shortRange}', style: Theme.of(context).textTheme.bodySmall),
          Text(
            'Standard range: ${trick.standardRange}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.s24),
          if (!trick.ready || later)
            Text(
              later
                  ? 'This trick is for a later grade.'
                  : (trick.blockReason ?? 'This trick is not ready to practice yet.'),
            )
          else
            AppButton(
              label: 'Start practice',
              onPressed: () async {
                await ref.read(practiceProvider).startLearn(trick.id);
                final view = ref.read(practiceProvider).view;
                if (view != null && context.mounted) {
                  context.go('/practice/${trick.id}/${view.phase}');
                }
              },
            ),
          if (!app.childMode) ...[
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: 'Worksheet',
              secondary: true,
              onPressed: () => context.go(
                '/export/worksheet?trickId=${trick.id}&learner=${learner.id}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Diagram extends StatelessWidget {
  const _Diagram({required this.trick});

  final Trick trick;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpace.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  for (final piece in trick.example.pieces)
                    TextSpan(
                      text: piece.text,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.step(piece.step),
                      ),
                    ),
                ],
              ),
            ),
            for (final note in trick.example.notes)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s8),
                child: Row(
                  children: [
                    Icon(Icons.south, color: colors.step(note.step), size: 24),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Text(
                        note.text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.step(note.step),
                        ),
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

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practice = ref.watch(practiceProvider);
    final app = ref.watch(appProvider);
    final view = practice.view;
    ref.listen(practiceProvider, (previous, next) {
      final current = next.view;
      if (current == null) return;
      final target = '/practice/${current.trickId}/${current.phase}';
      final loc = GoRouterState.of(context).uri.path;
      if (loc != target) context.go(target);
    });
    if (view == null || view.current == null) {
      return PageFrame(
        title: 'Practice',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This round is not open.'),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Back to today',
              onPressed: () => context.go('/child'),
            ),
          ],
        ),
      );
    }
    final item = view.current!;
    final prompt = _Prompt(view: view, item: item);
    final keys = Keypad(
      enabled: !view.locked,
      onKey: practice.key,
      onSubmit: practice.submit,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(context, ref, didPop),
      child: PageFrame(
        scroll: false,
        title: '${min(view.index + 1, view.items.length)} of ${view.items.length}',
        banner: app.banner,
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => _leave(context, ref, false),
          icon: const Icon(Icons.close),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth >= AppSpace.sideBySide;
            return HardwareKeys(
              enabled: !view.locked,
              onKey: practice.key,
              onSubmit: practice.submit,
              child: side
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SingleChildScrollView(child: prompt)),
                        const SizedBox(width: AppSpace.s16),
                        Flexible(child: keys),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: SingleChildScrollView(child: prompt)),
                        keys,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, bool didPop) async {
    if (didPop) return;
    final leave = await showConfirm(
      context,
      title: 'Leave this round?',
      body: 'Answered questions stay on this round until the day ends.',
      confirm: 'Leave',
      cancel: 'Stay',
    );
    if (leave && context.mounted) {
      await ref.read(practiceProvider).leave();
      if (context.mounted) context.go('/child');
    }
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.view, required this.item});

  final PracticeView view;
  final Problem item;

  @override
  Widget build(BuildContext context) {
    final step = view.showingSteps ? item.steps[view.stepIndex] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (view.phase == 'locate')
          Text('Check the step', style: Theme.of(context).textTheme.titleMedium),
        Text(item.prompt, style: Theme.of(context).textTheme.displaySmall),
        if (view.shownWrongFinal != null)
          Text('You entered ${view.shownWrongFinal}'),
        if (step != null) ...[
          const SizedBox(height: AppSpace.s12),
          Text('Step ${step.number} of ${item.steps.length}'),
          Text(step.ask, style: Theme.of(context).textTheme.titleMedium),
        ],
        const SizedBox(height: AppSpace.s16),
        AnswerReadout(value: view.draft, mark: view.mark),
        MarkLine(mark: view.mark),
      ],
    );
  }
}

class DonePage extends ConsumerWidget {
  const DonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(practiceProvider).view;
    if (view == null) {
      return PageFrame(
        title: 'Practice results',
        body: AppButton(
          label: 'Back to today',
          onPressed: () => context.go('/child'),
        ),
      );
    }
    final total = view.items.length;
    return PageFrame(
      title: 'Practice results',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${view.correctCount} of $total correct',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpace.s16),
          if (view.missedNotes.isEmpty)
            const Text('Every problem in this round was correct.')
          else ...[
            Text('Check these steps', style: Theme.of(context).textTheme.titleMedium),
            for (final note in view.missedNotes) Text(note),
          ],
          const SizedBox(height: AppSpace.s24),
          AppButton(
            label: 'Back to today',
            onPressed: () => context.go('/child'),
          ),
        ],
      ),
    );
  }
}

int _rank(String grade) => grades.indexOf(grade);

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/catalog.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../l10n/trick_zh.dart';
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
        _error = Copy.of(context).couldNotSave;
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
    final groups = [
      'addition',
      'subtraction',
      'multiplication',
      'division',
      'percent',
    ];
    final t = Copy.of(context);
    return PageFrame(
      title: t.mathTricks,
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: learner == null
          ? Text(t.addLearnerFirst)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.grade(learner.grade),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpace.s12),
                Wrap(
                  spacing: AppSpace.s8,
                  children: [
                    ChoiceChip(
                      label: Text(t.all),
                      selected: !_savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = false),
                    ),
                    ChoiceChip(
                      label: Text(t.saved),
                      selected: _savedOnly,
                      onSelected: (_) => setState(() => _savedOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s16),
                if (_loading)
                  const SkeletonBlock()
                else if (tricks.isEmpty)
                  Text(t.noTricksYet)
                else
                  for (final operation in groups)
                    _Group(
                      title: t.operation(operation),
                      tricks: tricks
                          .where((trick) => trick.operation == operation)
                          .toList(),
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
    final level = canonicalGrade(learner.grade);
    final current = tricks
        .where((trick) => canonicalGrade(trick.grade) == level)
        .toList();
    final earlier = tricks
        .where((trick) => _rank(trick.grade) < _rank(learner.grade))
        .toList();
    final later = tricks
        .where((trick) => _rank(trick.grade) > _rank(learner.grade))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        for (final trick in current) _card(context, trick, locked: false),
        for (final trick in earlier) _card(context, trick, locked: false),
        if (later.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(Copy.of(context).laterGrades),
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
    final t = Copy.of(context);
    final shown = localizeTrick(trick, t);
    return TrickCard(
      title: shown.title,
      caption: locked
          ? t.laterGradeTrick
          : '${t.grade(trick.grade)} · ${shown.shortRange}',
      mastered: mastery[trick.id]?.mastered ?? false,
      saved: learner.favorites.contains(trick.id),
      onPressed: locked
          ? null
          : () => context.go('/tricks/${trick.id}?learner=${learner.id}'),
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
          .where(
            (attempt) =>
                attempt.trickId == widget.id && attempt.mode == 'final',
          )
          .toList();
      final last = finals.length > 20
          ? finals.sublist(finals.length - 20)
          : finals;
      if (!mounted) return;
      setState(() {
        _answered = last.length;
        _correct = last.where((attempt) => attempt.correct).length;
        _mastered = mastery?.mastered ?? false;
        _loading = false;
      });
      final learner = app.learnerById(learnerId);
      if (learner != null &&
          learner.seenLessons[widget.id] != app.clock.today) {
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
    final raw = app.catalog.byId(widget.id);
    final t = Copy.of(context);
    final trick = raw == null ? null : localizeTrick(raw, t);
    final learner = app.learnerById(widget.learnerId ?? app.activeLearnerId);
    if (trick == null || learner == null) {
      return PageFrame(title: t.mathTricks, body: Text(t.missingTrick));
    }
    final later = _rank(trick.grade) > _rank(learner.grade) && app.childMode;
    final saved = learner.favorites.contains(trick.id);
    final colors = AppColors.of(context);
    return PageFrame(
      title: trick.title,
      banner: app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/tricks?learner=${learner.id}'),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: saved ? t.saved : t.save,
          onPressed: () => app.toggleFavorite(learner.id, trick.id),
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.grade(trick.grade),
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
          Text(t.useThisWhen, style: Theme.of(context).textTheme.titleMedium),
          Text(trick.appliesWhen),
          const SizedBox(height: AppSpace.s16),
          Text(t.notFor, style: Theme.of(context).textTheme.titleMedium),
          Text(trick.notWhen),
          const SizedBox(height: AppSpace.s16),
          Text(t.steps, style: Theme.of(context).textTheme.titleMedium),
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
          Text(
            t.pick(
              '短范围：${trick.shortRange}',
              'Short range: ${trick.shortRange}',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            t.pick(
              '标准范围：${trick.standardRange}',
              'Standard range: ${trick.standardRange}',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.s24),
          if (!trick.ready || later)
            Text(
              later
                  ? t.laterGradeTrick
                  : (t.zh ? t.notReady : (trick.blockReason ?? t.notReady)),
            )
          else
            AppButton(
              label: t.startPractice,
              onPressed: () async {
                await ref.read(practiceProvider).startLearn(trick.id);
                final view = ref.read(practiceProvider).view;
                if (view != null && context.mounted) {
                  context.go('/practice/${trick.id}/${view.phase}');
                }
              },
            ),
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: colors.step(piece.step)),
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
      if (current == null || current.phase == 'done') return;
      final target = '/practice/${current.trickId}/${current.phase}';
      final loc = GoRouterState.of(context).uri.path;
      if (loc != target) context.go(target);
    });
    if (practice.reportDue && view != null && view.phase == 'done') {
      practice.reportDue = false;
      final misses = view.misses;
      final correct = view.correctCount;
      final elapsed = view.elapsedMs;
      final trickId = view.trickId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final again = await showTrainingReport(
          context,
          correct: correct,
          wrong: misses.length,
          elapsed: clockLabel(elapsed),
          onSaveWrongs: misses.isEmpty
              ? null
              : () => ref.read(appProvider).bookRoundMisses(misses),
          bookWrongs: ref.read(appProvider).settings.bookWrongs,
          onBookWrongs: (value) {
            final app = ref.read(appProvider);
            return app.updateSettings(
              app.settings.copyWith(bookWrongs: value),
            );
          },
        );
        if (!context.mounted) return;
        if (again) {
          await ref.read(practiceProvider).startLearn(trickId);
          return;
        }
        context.go('/child');
      });
    }
    final finished = view != null && view.phase == 'done';
    final item = view?.current ??
        (finished && view.items.isNotEmpty ? view.items.last : null);
    if (view == null || item == null) {
      return PageFrame(
        title: Copy.of(context).practice,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Copy.of(context).pick('这一轮还没开始。', 'This round is not open.')),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: Copy.of(context).backToToday,
              onPressed: () => context.go('/child'),
            ),
          ],
        ),
      );
    }
    final t = Copy.of(context);
    final raw = app.catalog.byId(view.trickId);
    final title = raw == null ? t.dailyPractice : localizeTrick(raw, t).title;
    final next = !finished && view.index + 1 < view.items.length
        ? view.items[view.index + 1].prompt
        : null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(context, ref, didPop),
      child: PageFrame(
        scroll: false,
        padding: EdgeInsets.zero,
        title: title,
        banner: app.banner,
        body: HardwareKeys(
          enabled: !finished && !view.locked,
          onKey: practice.key,
          onSubmit: practice.submit,
          child: DrillBoard(
            title: title,
            onBack: () => _leave(context, ref, false),
            status: Text(
              '${min(view.index + 1, view.items.length)} / ${view.items.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            previousPrompt: finished ? null : view.previousPrompt,
            previousAnswer: finished ? null : view.previousAnswer,
            previousCorrect: finished ? null : view.previousCorrect,
            prompt: item.prompt,
            value: finished ? '' : view.draft,
            mark: finished ? null : view.mark,
            nextPrompt: next,
            keysEnabled: !finished && !view.locked,
            showAnswer: !finished,
            onKey: practice.key,
            onSubmit: practice.submit,
            detail: finished ? null : _PracticeDetail(view: view, item: item),
          ),
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

class _PracticeDetail extends StatelessWidget {
  const _PracticeDetail({required this.view, required this.item});

  final PracticeView view;
  final Problem item;

  @override
  Widget build(BuildContext context) {
    final step = view.showingSteps ? item.steps[view.stepIndex] : null;
    final t = Copy.of(context);
    if (view.phase != 'locate' &&
        view.shownWrongFinal == null &&
        step == null &&
        view.mark == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (view.phase == 'locate')
          Text(
            t.pick('核对这一步', 'Check the step'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (view.shownWrongFinal != null)
          Text(
            Copy.of(context).pick(
              '你输入了 ${view.shownWrongFinal}',
              'You entered ${view.shownWrongFinal}',
            ),
          ),
        if (step != null) ...[
          const SizedBox(height: AppSpace.s12),
          Text(
            t.pick(
              '第 ${step.number} 步，共 ${item.steps.length} 步',
              'Step ${step.number} of ${item.steps.length}',
            ),
          ),
          Text(step.ask, style: Theme.of(context).textTheme.titleMedium),
        ],
        MarkLine(mark: view.mark),
      ],
    );
  }
}

class DonePage extends ConsumerStatefulWidget {
  const DonePage({super.key});

  @override
  ConsumerState<DonePage> createState() => _DonePageState();
}

class _DonePageState extends ConsumerState<DonePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  Future<void> _report() async {
    final view = ref.read(practiceProvider).view;
    if (!mounted) return;
    if (view == null) {
      context.go('/child');
      return;
    }
    final trickId = view.trickId;
    final again = await showTrainingReport(
      context,
      correct: view.correctCount,
      wrong: view.misses.length,
      elapsed: clockLabel(view.elapsedMs),
      onSaveWrongs: view.misses.isEmpty
          ? null
          : () => ref.read(appProvider).bookRoundMisses(view.misses),
      bookWrongs: ref.read(appProvider).settings.bookWrongs,
      onBookWrongs: (value) {
        final app = ref.read(appProvider);
        return app.updateSettings(app.settings.copyWith(bookWrongs: value));
      },
    );
    if (!mounted) return;
    if (again) {
      await ref.read(practiceProvider).startLearn(trickId);
      final phase = ref.read(practiceProvider).view?.phase;
      if (mounted && phase != null) context.go('/practice/$trickId/$phase');
      return;
    }
    context.go('/child');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.of(context).bg,
      child: const SizedBox.expand(),
    );
  }
}

int _rank(String grade) => grades.indexOf(canonicalGrade(grade));

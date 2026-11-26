import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../ui/kit.dart';
import 'speed_form.dart';

class SpeedSetupPage extends ConsumerStatefulWidget {
  const SpeedSetupPage({super.key});

  @override
  ConsumerState<SpeedSetupPage> createState() => _SpeedSetupPageState();
}

class _SpeedSetupPageState extends ConsumerState<SpeedSetupPage> {
  SpeedConfig? _config;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final learner = app.active;
    _config ??= speedDefault(learner?.grade ?? '1');
    final config = _config!;
    final t = Copy.of(context);
    return PageFrame(
      title: t.speedDrill,
      banner: app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.pick(
              '选择运算和数字大小。这一轮记下总用时。',
              'Choose the operation and the size of the numbers. The round records total time.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s16),
          SpeedForm(
            level: learner?.grade ?? '1',
            config: config,
            onChanged: (value) => setState(() => _config = value),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: Copy.of(context).pick('开始', 'Start'),
            onPressed: learner == null
                ? null
                : () async {
                    await ref.read(speedProvider).start(config);
                    if (context.mounted) context.go('/speed/run');
                  },
          ),
          if (!app.childMode && learner != null) ...[
            const SizedBox(height: AppSpace.s12),
            AppButton(
              label: Copy.of(context).saveToday,
              secondary: true,
              onPressed: () async {
                final now = app.clock.now().toUtc();
                await app.saveAssignment(
                  Assignment(
                    id: newId(),
                    learnerId: learner.id,
                    localDate: app.clock.today,
                    kind: 'speed',
                    trickId: null,
                    speedConfig: jsonEncode(config.toJson()),
                    status: 'open',
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
                if (context.mounted && app.banner == null) context.go('/adult');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class SpeedRunPage extends ConsumerStatefulWidget {
  const SpeedRunPage({super.key});

  @override
  ConsumerState<SpeedRunPage> createState() => _SpeedRunPageState();
}

class _SpeedRunPageState extends ConsumerState<SpeedRunPage>
    with WidgetsBindingObserver {
  DateTime? _hidden;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _hidden ??= DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      final hidden = _hidden;
      _hidden = null;
      if (hidden != null) {
        ref.read(speedProvider).onBackground(DateTime.now().difference(hidden));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final speed = ref.watch(speedProvider);
    final view = speed.view;
    if (speed.reportDue && view != null && view.done) {
      speed.reportDue = false;
      final misses = view.misses;
      final correct = view.correct;
      final elapsed = view.elapsedMs;
      final config = view.config;
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
            return app.updateSettings(app.settings.copyWith(bookWrongs: value));
          },
        );
        if (!context.mounted) return;
        if (again) {
          await ref.read(speedProvider).start(config);
          return;
        }
        context.go('/child');
      });
    }
    if (view == null) {
      return PageFrame(
        title: Copy.of(context).speedDrill,
        body: AppButton(
          label: Copy.of(context).backToToday,
          onPressed: () => context.go('/child'),
        ),
      );
    }
    if (view.paused) {
      return PageFrame(
        title: Copy.of(context).pick('暂停', 'Pause'),
        scroll: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Copy.of(context).pick('已暂停', 'Paused'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpace.s8),
            Text(Copy.of(context).clockStopped),
            const Spacer(),
            AppButton(
              label: Copy.of(context).continueLabel,
              onPressed: speed.resumeRunning,
            ),
          ],
        ),
      );
    }
    final finished = view.done;
    final item =
        view.current ??
        (finished && view.items.isNotEmpty ? view.items.last : null);
    final t = Copy.of(context);
    final roundTitle = isDailyPractice(view.config, view.grade)
        ? t.dailyPractice
        : t.speedDrill;
    final next = !finished && view.index + 1 < view.items.length
        ? view.items[view.index + 1].prompt
        : null;
    Future<void> leave() async {
      final go = await showConfirm(
        context,
        title: t.pick('离开这一轮？', 'Leave this round?'),
        body: t.pick(
          '已答的题会留到今天结束。',
          'Answered questions stay on this round until the day ends.',
        ),
        confirm: t.pick('离开', 'Leave'),
        cancel: t.pick('留下', 'Stay'),
      );
      if (go && context.mounted) {
        await speed.leave();
        if (context.mounted) context.go('/child');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leave();
      },
      child: PageFrame(
        scroll: false,
        padding: EdgeInsets.zero,
        title: roundTitle,
        body: HardwareKeys(
          enabled: !finished && !view.locked && view.current != null,
          onKey: speed.key,
          onSubmit: speed.submit,
          child: DrillBoard(
            title: roundTitle,
            onBack: leave,
            status: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(t.elapsed, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: AppSpace.s8),
                Text(
                  clockLabel(view.elapsedMs),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            action: IconButton(
              tooltip: t.pick('暂停', 'Pause'),
              onPressed: speed.pause,
              icon: const Icon(Icons.pause),
            ),
            previousPrompt: finished ? null : view.previousPrompt,
            previousAnswer: finished ? null : view.previousAnswer,
            previousCorrect: finished ? null : view.previousCorrect,
            prompt: item?.prompt ?? '',
            value: finished ? '' : view.draft,
            mark: finished ? null : view.mark,
            nextPrompt: next,
            showAnswer: !finished,
            keysEnabled: !finished && !view.locked && view.current != null,
            onKey: speed.key,
            onReplace: speed.replaceDraft,
            onSubmit: speed.submit,
          ),
        ),
      ),
    );
  }
}

class SpeedDonePage extends ConsumerStatefulWidget {
  const SpeedDonePage({super.key});

  @override
  ConsumerState<SpeedDonePage> createState() => _SpeedDonePageState();
}

class _SpeedDonePageState extends ConsumerState<SpeedDonePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  Future<void> _report() async {
    final view = ref.read(speedProvider).view;
    if (!mounted) return;
    if (view == null) {
      context.go('/child');
      return;
    }
    final config = view.config;
    final again = await showTrainingReport(
      context,
      correct: view.correct,
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
      await ref.read(speedProvider).start(config);
      if (mounted) context.go('/speed/run');
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

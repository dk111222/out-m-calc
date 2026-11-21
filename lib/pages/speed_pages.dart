import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../domain/machines.dart';
import '../ui/kit.dart';

class SpeedForm extends StatelessWidget {
  const SpeedForm({super.key, required this.config, required this.onChanged});

  final SpeedConfig config;
  final ValueChanged<SpeedConfig> onChanged;

  static const counts = [5, 10, 15, 20, 30];
  static const digits = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.operationWord, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        Wrap(
          spacing: AppSpace.s8,
          runSpacing: AppSpace.s8,
          children: [
            for (final operation in const [
              'mixed',
              'addition',
              'subtraction',
              'multiplication',
              'division',
              'percent',
            ])
              ChoiceChip(
                label: Text(t.operation(operation)),
                selected: config.operation == operation,
                onSelected: (_) =>
                    onChanged(config.copyWith(operation: operation)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        StepperRow(
          label: t.pick('题数', 'Problems'),
          value: counts.contains(config.limitValue)
              ? config.limitValue
              : counts[1],
          steps: counts,
          onChanged: (value) =>
              onChanged(config.copyWith(limitMode: 'count', limitValue: value)),
        ),
        StepperRow(
          label: t.pick('最少位数', 'Smallest number of digits'),
          value: config.digitMin,
          steps: digits,
          onChanged: (value) => onChanged(
            config.copyWith(
              digitMin: value,
              digitMax: value > config.digitMax ? value : config.digitMax,
            ),
          ),
        ),
        StepperRow(
          label: t.pick('最多位数', 'Largest number of digits'),
          value: config.digitMax,
          steps: digits.where((digit) => digit >= config.digitMin).toList(),
          onChanged: (value) => onChanged(config.copyWith(digitMax: value)),
        ),
        Text(
          t.pick(
            '这一轮只记录总用时，不倒计时。',
            'This round records total time. There is no countdown.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

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
    ref.listen(speedProvider, (previous, next) {
      if (next.view?.done == true && previous?.view?.done != true) {
        context.go('/speed/done');
      }
    });
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
    final item = view.current;
    final prompt = _SpeedPrompt(view: view);
    final keys = Keypad(
      enabled: !view.locked && item != null,
      onKey: speed.key,
      onSubmit: speed.submit,
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showConfirm(
          context,
          title: Copy.of(context).pick('离开这一轮？', 'Leave this round?'),
          body: Copy.of(context).pick(
            '已答的题会留到今天结束。',
            'Answered questions stay on this round until the day ends.',
          ),
          confirm: Copy.of(context).pick('离开', 'Leave'),
          cancel: Copy.of(context).pick('留下', 'Stay'),
        );
        if (leave && context.mounted) {
          await speed.leave();
          if (context.mounted) context.go('/child');
        }
      },
      child: PageFrame(
        scroll: false,
        title: Copy.of(context).speedDrill,
        leading: IconButton(
          tooltip: Copy.of(context).pick('关闭', 'Close'),
          onPressed: () async {
            final leave = await showConfirm(
              context,
              title: Copy.of(context).pick('离开这一轮？', 'Leave this round?'),
              body: Copy.of(context).pick(
                '已答的题会留到今天结束。',
                'Answered questions stay on this round until the day ends.',
              ),
              confirm: Copy.of(context).pick('离开', 'Leave'),
              cancel: Copy.of(context).pick('留下', 'Stay'),
            );
            if (leave && context.mounted) {
              await speed.leave();
              if (context.mounted) context.go('/child');
            }
          },
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            tooltip: Copy.of(context).pick('暂停', 'Pause'),
            onPressed: speed.pause,
            icon: const Icon(Icons.pause),
          ),
        ],
        body: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth >= AppSpace.sideBySide;
            return HardwareKeys(
              enabled: !view.locked,
              onKey: speed.key,
              onSubmit: speed.submit,
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
}

class _SpeedPrompt extends StatelessWidget {
  const _SpeedPrompt({required this.view});

  final SpeedView view;

  @override
  Widget build(BuildContext context) {
    final item = view.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimerPanel(
          caption: Copy.of(context).elapsed,
          value: clockLabel(view.elapsedMs),
        ),
        const SizedBox(height: AppSpace.s24),
        EquationLine(
          prompt: item?.prompt ?? '',
          value: view.draft,
          mark: view.mark,
        ),
        MarkLine(mark: view.mark),
      ],
    );
  }
}

class SpeedDonePage extends ConsumerWidget {
  const SpeedDonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(speedProvider).view;
    if (view == null) {
      return PageFrame(
        title: Copy.of(context).speedDrill,
        body: AppButton(
          label: Copy.of(context).backToToday,
          onPressed: () => context.go('/child'),
        ),
      );
    }
    final t = Copy.of(context);
    final best = view.correct > view.previousBest
        ? view.correct
        : view.previousBest;
    final fresh = view.correct > view.previousBest && view.correct > 0;
    return PageFrame(
      title: t.speedDrill,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.nCorrect(view.correct),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            fresh ? t.newBest : t.best(best),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            view.config.summary(language: t.language),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            '${t.elapsed} ${clockLabel(view.elapsedMs)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            label: t.backToToday,
            onPressed: () => context.go('/child'),
          ),
        ],
      ),
    );
  }
}

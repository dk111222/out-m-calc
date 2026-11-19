import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../domain/machines.dart';
import '../ui/kit.dart';

class SpeedForm extends StatelessWidget {
  const SpeedForm({
    super.key,
    required this.config,
    required this.onChanged,
  });

  final SpeedConfig config;
  final ValueChanged<SpeedConfig> onChanged;

  static const counts = [5, 10, 15, 20, 30];
  static const times = [30, 60, 120, 180, 300];
  static const digits = [1, 2, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Operation', style: Theme.of(context).textTheme.titleMedium),
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
                label: Text(operationLabel(operation)),
                selected: config.operation == operation,
                onSelected: (_) => onChanged(config.copyWith(operation: operation)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s16),
        Text('End the round by', style: Theme.of(context).textTheme.titleMedium),
        RadioGroup<String>(
          groupValue: config.limitMode,
          onChanged: (value) {
            if (value == null) return;
            final timed = value == 'time';
            onChanged(
              config.copyWith(
                limitMode: value,
                limitValue: (timed ? times : counts).contains(config.limitValue)
                    ? config.limitValue
                    : (timed ? 180 : 10),
              ),
            );
          },
          child: const Column(
            children: [
              RadioListTile<String>(
                value: 'count',
                title: Text('Problems left'),
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                value: 'time',
                title: Text('Time left'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        StepperRow(
          label: config.limitMode == 'time' ? 'Seconds' : 'Problems',
          value: (config.limitMode == 'time' ? times : counts).contains(config.limitValue)
              ? config.limitValue
              : (config.limitMode == 'time' ? times : counts).first,
          steps: config.limitMode == 'time' ? times : counts,
          onChanged: (value) => onChanged(config.copyWith(limitValue: value)),
        ),
        StepperRow(
          label: 'Smallest number of digits',
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
          label: 'Largest number of digits',
          value: config.digitMax,
          steps: digits.where((digit) => digit >= config.digitMin).toList(),
          onChanged: (value) => onChanged(config.copyWith(digitMax: value)),
        ),
        TimerPanel(
          caption: config.limitMode == 'time' ? 'Time left' : 'Problems left',
          value: config.limitMode == 'time'
              ? clockLabel(config.limitValue * 1000)
              : '${config.limitValue}',
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
    return PageFrame(
      title: 'Speed Drill',
      banner: app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose the operation, the size of the numbers, and how the round ends.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.s16),
          SpeedForm(config: config, onChanged: (value) => setState(() => _config = value)),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Start',
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
              label: 'Save today',
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
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
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
        title: 'Speed Drill',
        body: AppButton(
          label: 'Back to today',
          onPressed: () => context.go('/child'),
        ),
      );
    }
    if (view.paused) {
      return PageFrame(
        title: 'Pause',
        scroll: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Paused', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpace.s8),
            const Text('The clock is stopped. The same problem is waiting.'),
            const Spacer(),
            AppButton(label: 'Continue', onPressed: speed.resumeRunning),
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
          title: 'Leave this round?',
          body: 'Answered questions stay on this round until the day ends.',
          confirm: 'Leave',
          cancel: 'Stay',
        );
        if (leave && context.mounted) {
          await speed.leave();
          if (context.mounted) context.go('/child');
        }
      },
      child: PageFrame(
        scroll: false,
        title: 'Speed Drill',
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () async {
            final leave = await showConfirm(
              context,
              title: 'Leave this round?',
              body: 'Answered questions stay on this round until the day ends.',
              confirm: 'Leave',
              cancel: 'Stay',
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
            tooltip: 'Pause',
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
    final caption = view.config.limitMode == 'time' ? 'Time left' : 'Problems left';
    final value = view.config.limitMode == 'time'
        ? clockLabel(view.remainingMs)
        : '${view.problemsLeft}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TimerPanel(caption: caption, value: value, warning: view.warning),
        const SizedBox(height: AppSpace.s24),
        Text(
          item?.prompt ?? '',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpace.s16),
        AnswerReadout(value: view.draft, mark: view.mark),
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
        title: 'Speed Drill',
        body: AppButton(
          label: 'Back to today',
          onPressed: () => context.go('/child'),
        ),
      );
    }
    final best = view.correct > view.previousBest ? view.correct : view.previousBest;
    final fresh = view.correct > view.previousBest && view.correct > 0;
    return PageFrame(
      title: 'Speed Drill',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${view.correct} correct',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            fresh ? 'New personal best' : 'Personal best: $best',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(view.config.summary, style: Theme.of(context).textTheme.bodySmall),
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

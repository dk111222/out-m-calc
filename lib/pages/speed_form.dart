import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../ui/kit.dart';

class SpeedForm extends StatelessWidget {
  const SpeedForm({
    super.key,
    required this.config,
    required this.onChanged,
    required this.level,
  });

  final SpeedConfig config;
  final ValueChanged<SpeedConfig> onChanged;
  final String level;

  static const counts = [5, 10, 15, 20, 30];
  static const digits = [1, 2, 3, 4];

  List<String> get operations => operationsFor(level);

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.operationWord, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        for (var row = 0; row < operations.length; row += 3) ...[
          if (row > 0) const SizedBox(height: AppSpace.s8),
          Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: AppSpace.s8),
                Expanded(
                  child: row + column < operations.length
                      ? _OperationChoice(
                          label: t.operation(operations[row + column]),
                          selected:
                              config.operation == operations[row + column],
                          onPressed: () => onChanged(
                            config.copyWith(
                              operation: operations[row + column],
                            ),
                          ),
                        )
                      : const SizedBox(height: 52),
                ),
              ],
            ],
          ),
        ],
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
        if (canonicalGrade(level) != '5') ...[
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
        ],
      ],
    );
  }
}

class _OperationChoice extends StatelessWidget {
  const _OperationChoice({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = selected ? colors.accent : colors.sunken;
    final foreground = selected ? colors.onAccent : colors.text;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSpace.rMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<SpeedConfig?> showSpeedSetupDialog(
  BuildContext context, {
  required SpeedConfig config,
  required String level,
}) {
  return showDialog<SpeedConfig>(
    context: context,
    builder: (context) => _SpeedSetupDialog(initial: config, level: level),
  );
}

class _SpeedSetupDialog extends StatefulWidget {
  const _SpeedSetupDialog({required this.initial, required this.level});

  final SpeedConfig initial;
  final String level;

  @override
  State<_SpeedSetupDialog> createState() => _SpeedSetupDialogState();
}

class _SpeedSetupDialogState extends State<_SpeedSetupDialog> {
  late SpeedConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final t = Copy.of(context);
    final width = math.min(400, MediaQuery.sizeOf(context).width - 32);
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.all(AppSpace.s16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rLg),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width.toDouble(),
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.pick('速算设置', 'Speed settings'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.s16),
              SpeedForm(
                config: _config,
                level: widget.level,
                onChanged: (value) => setState(() => _config = value),
              ),
              const SizedBox(height: AppSpace.s24),
              AppButton(
                label: t.pick('确定', 'Done'),
                onPressed: () => Navigator.pop(context, _config),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

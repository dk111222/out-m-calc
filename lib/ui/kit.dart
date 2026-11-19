import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.actions,
    this.bottom,
    this.banner,
    this.scroll = true,
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final String? banner;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final padded = Padding(
      padding: const EdgeInsets.all(AppSpace.s16),
      child: body,
    );
    final content = width >= AppSpace.wide
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpace.column),
              child: padded,
            ),
          )
        : padded;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
      ),
      body: Column(
        children: [
          if (banner != null)
            Material(
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colors.danger),
                    const SizedBox(width: AppSpace.s8),
                    Expanded(
                      child: Text(banner!, style: TextStyle(color: colors.danger)),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: scroll ? SingleChildScrollView(child: content) : content),
          ?bottom,
        ],
      ),
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.height = 72});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.border,
        borderRadius: BorderRadius.circular(AppSpace.rMd),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.secondary = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool secondary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = busy ? 'Working' : label;
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSpace.minTarget),
      backgroundColor: secondary
          ? colors.surface
          : (destructive ? colors.surface : colors.accent),
      foregroundColor: destructive
          ? colors.danger
          : (secondary ? colors.text : colors.onAccent),
      disabledBackgroundColor: colors.sunken,
      disabledForegroundColor: colors.textMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rSm),
        side: secondary || destructive
            ? BorderSide(color: destructive ? colors.danger : colors.border)
            : BorderSide.none,
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: secondary ? colors.text : colors.onAccent,
      ),
    );
    return Focus(
      child: FilledButton(
        style: style,
        onPressed: busy ? null : onPressed,
        child: Text(text),
      ),
    );
  }
}

class TrickCard extends StatelessWidget {
  const TrickCard({
    super.key,
    required this.title,
    required this.caption,
    required this.onPressed,
    this.mastered = false,
    this.saved = false,
  });

  final String title;
  final String caption;
  final VoidCallback? onPressed;
  final bool mastered;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null;
    final name = mastered ? '$title, ${caption.isEmpty ? '' : '$caption, '}Mastered' : '$title, $caption';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpace.rMd),
          border: Border.all(color: colors.border),
          boxShadow: colors.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpace.rMd),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Semantics(
                button: enabled,
                enabled: enabled,
                label: name,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.s16),
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
                              Text(caption, style: Theme.of(context).textTheme.bodySmall),
                            ],
                            if (mastered) ...[
                              const SizedBox(height: AppSpace.s4),
                              Text(
                                'Mastered',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (saved)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpace.s8),
                          child: Icon(Icons.bookmark, color: colors.accent),
                        ),
                      if (enabled)
                        Icon(Icons.chevron_right, color: colors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Keypad extends StatelessWidget {
  const Keypad({
    super.key,
    required this.onKey,
    required this.onSubmit,
    this.enabled = true,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final keyHeight = math.max(AppSpace.minTarget, AppSpace.minTarget * scale);
    Widget key(String label, String value, {String? semantics}) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpace.rSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpace.rSm),
            onTap: enabled ? () => onKey(value) : null,
            child: Semantics(
              button: true,
              enabled: enabled,
              label: semantics ?? label,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: keyHeight),
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: value == 'delete' ? colors.textMuted : colors.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpace.keypadMax),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.sunken,
          borderRadius: BorderRadius.circular(AppSpace.rMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                  children: [
                    for (final digit in row) Expanded(child: key(digit, digit)),
                  ],
                ),
              Row(
                children: [
                  Expanded(child: key('.', '.')),
                  Expanded(child: key('0', '0')),
                  Expanded(child: key('Delete', 'delete', semantics: 'Delete')),
                ],
              ),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Submit',
                onPressed: enabled ? onSubmit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnswerReadout extends StatelessWidget {
  const AnswerReadout({
    super.key,
    required this.value,
    this.mark,
  });

  final String value;
  final String? mark;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final border = mark == 'wrong'
        ? colors.danger
        : (mark == 'correct' ? colors.success : colors.borderInput);
    return Semantics(
      textField: true,
      label: 'Your answer',
      value: value.isEmpty ? 'Empty' : value,
      liveRegion: true,
      child: AnimatedContainer(
        duration: motionFast,
        curve: Curves.easeOut,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppSpace.minTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpace.rSm),
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          value.isEmpty ? 'Your answer' : value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: value.isEmpty ? colors.textMuted : colors.text,
          ),
        ),
      ),
    );
  }
}

class MarkLine extends StatelessWidget {
  const MarkLine({super.key, required this.mark});

  final String? mark;

  @override
  Widget build(BuildContext context) {
    if (mark == null) return const SizedBox(height: AppSpace.s24);
    final colors = AppColors.of(context);
    final correct = mark == 'correct';
    final color = correct ? colors.success : colors.danger;
    final label = correct ? 'Correct' : 'Not quite';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        children: [
          Icon(correct ? Icons.check : Icons.close, color: color),
          const SizedBox(width: AppSpace.s8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class TimerPanel extends StatelessWidget {
  const TimerPanel({
    super.key,
    required this.caption,
    required this.value,
    this.warning = false,
  });

  final String caption;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      liveRegion: true,
      label: '$caption $value',
      child: Container(
        height: AppSpace.minTarget,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpace.rPill),
          border: Border.all(
            color: warning ? colors.warning : colors.border,
            width: warning ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.correct,
    required this.answered,
    this.mastered = false,
    this.loading = false,
  });

  final int correct;
  final int answered;
  final bool mastered;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final shown = answered == 0 ? 0 : correct;
    final label = mastered
        ? 'Mastered. $shown of 20 correct'
        : '$shown of 20 correct';
    final fraction = loading ? 0.0 : (shown / 20).clamp(0.0, 1.0);
    return Semantics(
      label: answered == 0 && !mastered ? '0 of 20' : label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mastered ? 'Mastered' : (answered == 0 ? '0 of 20' : '$shown of 20 correct'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpace.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpace.rSm),
            child: SizedBox(
              height: 12,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(color: colors.sunken),
                      AnimatedContainer(
                        duration: motionBase,
                        curve: Curves.easeOut,
                        width: constraints.maxWidth * fraction,
                        color: loading ? colors.border : colors.accent,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.steps,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final List<int> steps;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final index = steps.indexOf(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          _stepButton(
            context,
            icon: Icons.remove,
            label: 'Decrease $label',
            onPressed: index <= 0 ? null : () => onChanged(steps[index - 1]),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _stepButton(
            context,
            icon: Icons.add,
            label: 'Increase $label',
            onPressed: index < 0 || index >= steps.length - 1
                ? null
                : () => onChanged(steps[index + 1]),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _stepButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    AppColors? colors,
  }) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSpace.minTarget, AppSpace.minTarget),
      ),
    );
  }
}

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  String cancel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !destructive,
    builder: (context) => _DialogShell(
      title: title,
      body: body,
      destructive: destructive,
      barrierLocked: destructive,
      actions: [
        AppButton(
          label: cancel,
          secondary: true,
          onPressed: () => Navigator.pop(context, false),
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: confirm,
          destructive: destructive,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

class PinResult {
  const PinResult(this.pin, this.again);
  final String pin;
  final String? again;
}

Future<PinResult?> showPinDialog(
  BuildContext context, {
  required String title,
  required String body,
  required bool create,
  String? error,
  int? waitSeconds,
}) {
  return showDialog<PinResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PinDialog(
      title: title,
      body: body,
      create: create,
      error: error,
      waitSeconds: waitSeconds,
    ),
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.body,
    required this.actions,
    this.destructive = false,
    this.barrierLocked = false,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final bool destructive;
  final bool barrierLocked;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final width = math.min(400, MediaQuery.sizeOf(context).width - 32);
    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.all(AppSpace.s16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rLg),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.toDouble()),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpace.s12),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpace.s24),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({
    required this.title,
    required this.body,
    required this.create,
    this.error,
    this.waitSeconds,
  });

  final String title;
  final String body;
  final bool create;
  final String? error;
  final int? waitSeconds;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.error;
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final locked = (widget.waitSeconds ?? 0) > 0;
    return _DialogShell(
      title: widget.title,
      body: widget.body,
      barrierLocked: true,
      actions: [
        TextField(
          controller: _first,
          autofocus: true,
          enabled: !locked,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Parent code',
            counterText: '',
          ),
        ),
        if (widget.create) ...[
          const SizedBox(height: AppSpace.s12),
          TextField(
            controller: _second,
            enabled: !locked,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Enter the code again',
              counterText: '',
            ),
          ),
        ],
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Text(
              'Try again in ${widget.waitSeconds} seconds.',
              style: TextStyle(color: colors.danger),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Text(_error!, style: TextStyle(color: colors.danger)),
          ),
        const SizedBox(height: AppSpace.s16),
        AppButton(
          label: 'Cancel',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: 'Continue',
          onPressed: locked
              ? null
              : () {
                  final pin = _first.text;
                  final again = widget.create ? _second.text : null;
                  if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                    setState(() => _error = 'Enter four digits.');
                    return;
                  }
                  if (widget.create && pin != again) {
                    setState(() => _error = 'Those codes do not match.');
                    return;
                  }
                  Navigator.pop(context, PinResult(pin, again));
                },
        ),
      ],
    );
  }
}

class HardwareKeys extends StatelessWidget {
  const HardwareKeys({
    super.key,
    required this.enabled,
    required this.onKey,
    required this.onSubmit,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          onKey('delete');
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          onSubmit();
          return KeyEventResult.handled;
        }
        final character = event.character;
        if (character == '.') {
          onKey('.');
          return KeyEventResult.handled;
        }
        if (character != null && RegExp(r'^\d$').hasMatch(character)) {
          onKey(character);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

String clockLabel(int remainingMs) {
  final seconds = (remainingMs / 1000).ceil().clamp(0, 24 * 3600);
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

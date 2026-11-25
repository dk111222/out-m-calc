import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/copy.dart';

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
    this.padding = const EdgeInsets.all(AppSpace.s16),
  });

  final String title;
  final Widget body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottom;
  final String? banner;
  final bool scroll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final padded = Padding(padding: padding, child: body);
    final content = width >= AppSpace.wide
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpace.column),
              child: padded,
            ),
          )
        : padded;
    final tools = leading != null || (actions?.isNotEmpty ?? false);
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Semantics(
          namesRoute: true,
          label: title,
          explicitChildNodes: true,
          child: Column(
            children: [
              if (tools)
                SizedBox(
                  height: AppSpace.minTarget,
                  child: Row(children: [?leading, const Spacer(), ...?actions]),
                ),
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
                          child: Text(
                            banner!,
                            style: TextStyle(color: colors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: scroll ? SingleChildScrollView(child: content) : content,
              ),
              ?bottom,
            ],
          ),
        ),
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
    final text = busy ? Copy.of(context).working : label;
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
    this.leading,
    this.mastered = false,
    this.saved = false,
  });

  final String title;
  final String caption;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool mastered;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null;
    final name = mastered
        ? '$title, ${caption.isEmpty ? '' : '$caption, '}Mastered'
        : '$title, $caption';
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
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: AppSpace.s12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: enabled
                                        ? colors.text
                                        : colors.textMuted,
                                  ),
                            ),
                            if (caption.isNotEmpty) ...[
                              const SizedBox(height: AppSpace.s4),
                              Text(
                                caption,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (mastered) ...[
                              const SizedBox(height: AppSpace.s4),
                              Text(
                                Copy.of(context).mastered,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
    this.showSubmit = true,
    this.showDelete = true,
    this.keyExtent,
  });

  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;
  final bool enabled;
  final bool showSubmit;
  final bool showDelete;
  final double? keyExtent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final keyHeight =
        keyExtent ?? math.max(AppSpace.minTarget, AppSpace.minTarget * scale);
    Widget key(String label, String value, {String? semantics}) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.s4),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpace.rSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpace.rSm),
            onTap: enabled
                ? () {
                    if (int.tryParse(value) != null) {
                      HapticFeedback.selectionClick();
                    }
                    onKey(value);
                  }
                : null,
            child: Semantics(
              button: true,
              enabled: enabled,
              label: semantics ?? label,
              child: SizedBox(
                height: keyHeight,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: value == 'delete'
                            ? colors.textMuted
                            : colors.text,
                      ),
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
                  Expanded(
                    child: showDelete
                        ? key(
                            Copy.of(context).delete,
                            'delete',
                            semantics: Copy.of(context).delete,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              if (showSubmit) ...[
                const SizedBox(height: AppSpace.s8),
                AppButton(
                  label: Copy.of(context).submit,
                  onPressed: enabled ? onSubmit : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DrillBoard extends StatelessWidget {
  const DrillBoard({
    super.key,
    required this.title,
    required this.onBack,
    required this.prompt,
    required this.value,
    required this.onKey,
    required this.onSubmit,
    this.status,
    this.action,
    this.previousPrompt,
    this.previousAnswer,
    this.previousCorrect,
    this.mark,
    this.detail,
    this.nextPrompt,
    this.keysEnabled = true,
    this.showAnswer = true,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? status;
  final Widget? action;
  final String? previousPrompt;
  final String? previousAnswer;
  final bool? previousCorrect;
  final String prompt;
  final String value;
  final String? mark;
  final Widget? detail;
  final String? nextPrompt;
  final bool keysEnabled;
  final bool showAnswer;
  final ValueChanged<String> onKey;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final previous = previousPrompt != null &&
        previousAnswer != null &&
        previousCorrect != null;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final naturalKey = math.max(AppSpace.minTarget, AppSpace.minTarget * scale);
    final previousHeight = _previousHeight(scale);
    final equationHeight = _equationHeight(scale);
    final nextHeight = _nextHeight(scale);
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyExtent = _keyExtent(
          height: constraints.maxHeight,
          natural: naturalKey,
          scale: scale,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s16,
                  AppSpace.s8,
                  AppSpace.s16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: t.back,
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          ?status,
                          ?action,
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, space) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: previousHeight,
                                        child: previous
                                            ? Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _settledLine(
                                                        previousPrompt!,
                                                        previousAnswer!,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium,
                                                    ),
                                                  ),
                                                  Icon(
                                                    previousCorrect!
                                                        ? Icons.check
                                                        : Icons.close,
                                                    color: previousCorrect!
                                                        ? colors.success
                                                        : colors.danger,
                                                  ),
                                                ],
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpace.s12),
                                      SizedBox(
                                        height: equationHeight,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: EquationLine(
                                            prompt: prompt,
                                            value: value,
                                            mark: mark,
                                            showAnswer: showAnswer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpace.s8),
                                      SizedBox(
                                        height: nextHeight,
                                        child: nextPrompt == null
                                            ? null
                                            : Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  _settledLine(
                                                    nextPrompt!,
                                                    '( )',
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: colors.textMuted,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (detail != null)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: space.maxHeight * 0.35,
                                  ),
                                  child: SingleChildScrollView(
                                    clipBehavior: Clip.none,
                                    child: detail,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(height: AppSpace.s16),
                    Keypad(
                      enabled: keysEnabled,
                      onKey: onKey,
                      onSubmit: onSubmit,
                      showSubmit: false,
                      showDelete: true,
                      keyExtent: keyExtent,
                    ),
                    const SizedBox(height: AppSpace.s8),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: t.submit,
                        onPressed: keysEnabled ? onSubmit : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _previousHeight(double scale) => math.max(36.0, 32 * scale);

  double _equationHeight(double scale) => 48 * scale;

  double _nextHeight(double scale) => math.max(32.0, 28 * scale);

  double _keyExtent({
    required double height,
    required double natural,
    required double scale,
  }) {
    if (!height.isFinite) return natural;
    final submit = math.max(AppSpace.minTarget, AppSpace.minTarget * scale);
    final used =
        AppSpace.s8 +
        56 +
        _previousHeight(scale) +
        AppSpace.s12 +
        _equationHeight(scale) +
        AppSpace.s8 +
        _nextHeight(scale) +
        AppSpace.s16 +
        AppSpace.s8 +
        submit;
    final fitted = (height - used - 48) / 4;
    if (!fitted.isFinite) return natural;
    return fitted.clamp(32.0, natural);
  }

  static String _settledLine(String prompt, String blank) {
    final equals = prompt.contains('=') ? '' : ' = ';
    return '$prompt$equals$blank';
  }
}

class EquationLine extends StatelessWidget {
  const EquationLine({
    super.key,
    required this.prompt,
    required this.value,
    this.mark,
    this.showAnswer = true,
  });

  final String prompt;
  final String value;
  final String? mark;
  final bool showAnswer;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall;
    if (!showAnswer) {
      return Text(
        prompt,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final showEquals = prompt.isNotEmpty && !prompt.contains('=');
    return _BleedRight(
      extra: AppSpace.s16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: _fittedEquation(
              maxWidth: constraints.maxWidth,
              style: style,
              showEquals: showEquals,
            ),
          );
        },
      ),
    );
  }

  Widget _fittedEquation({
    required double maxWidth,
    required TextStyle? style,
    required bool showEquals,
  }) {
    final base = style ?? const TextStyle(fontSize: 40);
    var low = 0.45;
    var high = 1.0;
    var scale = low;
    for (var i = 0; i < 12; i++) {
      final mid = (low + high) / 2;
      if (_equationFits(base, mid, maxWidth, showEquals)) {
        scale = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    final fitted = base.copyWith(fontSize: (base.fontSize ?? 40) * scale);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(prompt, style: fitted, maxLines: 1, softWrap: false),
        if (showEquals) ...[
          const SizedBox(width: AppSpace.s8),
          Text('=', style: fitted),
        ],
        const SizedBox(width: AppSpace.s8),
        Expanded(
          child: AnswerReadout(value: value, mark: mark, style: fitted),
        ),
      ],
    );
  }

  bool _equationFits(
    TextStyle base,
    double scale,
    double maxWidth,
    bool showEquals,
  ) {
    final fitted = base.copyWith(fontSize: (base.fontSize ?? 40) * scale);
    final promptWidth = _textWidth(prompt, fitted);
    final equalsWidth = showEquals
        ? _textWidth('=', fitted) + AppSpace.s8
        : 0;
    final parenWidth = _textWidth('()', fitted);
    final middle = _textWidth(value.isEmpty ? '0' : value, fitted);
    final needed =
        promptWidth + equalsWidth + AppSpace.s8 + parenWidth + middle;
    return needed + 4 <= maxWidth;
  }
}

double _textWidth(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

class _BleedRight extends SingleChildRenderObjectWidget {
  const _BleedRight({required this.extra, required super.child});

  final double extra;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBleedRight(extra);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBleedRight renderObject,
  ) {
    renderObject.extra = extra;
  }
}

class _RenderBleedRight extends RenderShiftedBox {
  _RenderBleedRight(this._extra) : super(null);

  double _extra;

  double get extra => _extra;

  set extra(double value) {
    if (_extra == value) return;
    _extra = value;
    markNeedsLayout();
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 0,
      maxWidth: constraints.maxWidth + extra,
      minHeight: 0,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_childConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(
      Size(math.max(0, child.size.width - extra), child.size.height),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final childSize = child.getDryLayout(_childConstraints(constraints));
    return constraints.constrain(
      Size(math.max(0, childSize.width - extra), childSize.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset);
  }
}

class AnswerReadout extends StatelessWidget {
  const AnswerReadout({super.key, required this.value, this.mark, this.style});

  final String value;
  final String? mark;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = mark == 'wrong'
        ? colors.danger
        : (mark == 'correct' ? colors.success : colors.text);
    final textStyle = (style ?? Theme.of(context).textTheme.displaySmall)
        ?.copyWith(color: color);
    final t = Copy.of(context);
    return Semantics(
      textField: true,
      label: t.yourAnswer,
      value: value.isEmpty ? t.pick('空', 'Empty') : value,
      liveRegion: true,
      child: Row(
        children: [
          Text('(', style: textStyle),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
          Text(')', style: textStyle),
        ],
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
    final label = correct
        ? Copy.of(context).correct
        : Copy.of(context).notQuite;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        children: [
          Icon(correct ? Icons.check : Icons.close, color: color),
          const SizedBox(width: AppSpace.s8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
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
    final t = Copy.of(context);
    final shown = answered == 0 ? 0 : correct;
    final count = t.pick('$shown / 20 题正确', '$shown of 20 correct');
    final label = mastered ? '${t.mastered}. $count' : count;
    final fraction = loading ? 0.0 : (shown / 20).clamp(0.0, 1.0);
    return Semantics(
      label: answered == 0 && !mastered ? t.pick('0 / 20', '0 of 20') : label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mastered
                ? t.mastered
                : (answered == 0 ? t.pick('0 / 20', '0 of 20') : count),
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
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
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

Future<bool> showTrainingReport(
  BuildContext context, {
  required int correct,
  required int wrong,
  required String elapsed,
  Future<void> Function()? onSaveWrongs,
  bool bookWrongs = true,
  Future<void> Function(bool value)? onBookWrongs,
}) async {
  final again = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => TrainingReportDialog(
      correct: correct,
      wrong: wrong,
      elapsed: elapsed,
      onSaveWrongs: onSaveWrongs,
      bookWrongs: bookWrongs,
      onBookWrongs: onBookWrongs,
    ),
  );
  return again ?? false;
}

/// Whole-number percent, or null when the round had no answers.
int? accuracyPercent(int correct, int wrong) {
  final total = correct + wrong;
  if (total <= 0) return null;
  return ((correct * 100) / total).round();
}

/// Another round is offered only when accuracy is under 80 percent.
bool offerAnotherRound(int correct, int wrong) {
  final total = correct + wrong;
  if (total <= 0) return false;
  return correct / total < 0.8;
}

class TrainingReportDialog extends StatefulWidget {
  const TrainingReportDialog({
    super.key,
    required this.correct,
    required this.wrong,
    required this.elapsed,
    this.onSaveWrongs,
    this.bookWrongs = true,
    this.onBookWrongs,
  });

  final int correct;
  final int wrong;
  final String elapsed;
  final Future<void> Function()? onSaveWrongs;
  final bool bookWrongs;
  final Future<void> Function(bool value)? onBookWrongs;

  @override
  State<TrainingReportDialog> createState() => _TrainingReportDialogState();
}

class _TrainingReportDialogState extends State<TrainingReportDialog> {
  late bool _book;
  bool _leaving = false;

  bool get _offerBook => widget.wrong > 0 && widget.onSaveWrongs != null;

  @override
  void initState() {
    super.initState();
    _book = widget.bookWrongs;
  }

  Future<void> _close(bool again) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      if (_offerBook && _book) await widget.onSaveWrongs?.call();
      if (_offerBook) await widget.onBookWrongs?.call(_book);
    } catch (_) {}
    if (!mounted) return;
    Navigator.pop(context, again);
  }

  _ReportCheer _cheer(Copy t, AppColors colors, int? percent) {
    if (widget.wrong == 0 && widget.correct > 0) {
      return _ReportCheer(
        t.pick('全部做对了', 'All correct'),
        Icons.emoji_events_rounded,
        colors.success,
      );
    }
    if (percent != null && percent >= 80) {
      return _ReportCheer(
        t.pick('做得很好', 'Well done'),
        Icons.star_rounded,
        colors.success,
      );
    }
    if (percent != null && percent > 0) {
      return _ReportCheer(
        null,
        Icons.favorite_rounded,
        colors.warning,
      );
    }
    return _ReportCheer(
      t.pick('训练结束', 'Round finished'),
      Icons.flag_rounded,
      colors.accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final percent = accuracyPercent(widget.correct, widget.wrong);
    final again = offerAnotherRound(widget.correct, widget.wrong);
    final cheer = _cheer(t, colors, percent);
    final width = math.min(400, MediaQuery.sizeOf(context).width - 32);
    return Dialog(
      backgroundColor: colors.surface,
      elevation: 0,
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpace.rLg),
            boxShadow: colors.popShadow,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.pick('训练报告', 'Training report'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.s16),
                Center(child: _ReportMark(color: cheer.tone, icon: cheer.icon)),
                if (cheer.title != null) ...[
                  const SizedBox(height: AppSpace.s12),
                  Text(
                    cheer.title!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
                if (percent != null) ...[
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    t.pick('正确率 $percent%', '$percent% correct'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: AppSpace.s16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportStat(
                      label: t.pick(
                        '正确 ${widget.correct} 题',
                        '${widget.correct} correct',
                      ),
                      color: colors.success,
                    ),
                    const SizedBox(width: AppSpace.s8),
                    _ReportStat(
                      label: t.pick(
                        '错误 ${widget.wrong} 题',
                        '${widget.wrong} wrong',
                      ),
                      color: widget.wrong == 0 ? colors.success : colors.warning,
                    ),
                    const SizedBox(width: AppSpace.s8),
                    _ReportStat(
                      label: t.pick(
                        '用时 ${widget.elapsed}',
                        'Time ${widget.elapsed}',
                      ),
                      color: colors.accent,
                    ),
                  ],
                ),
                if (_offerBook) ...[
                  const SizedBox(height: AppSpace.s16),
                  Material(
                    color: colors.sunken,
                    borderRadius: BorderRadius.circular(AppSpace.rMd),
                    clipBehavior: Clip.antiAlias,
                    child: CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s8,
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _book,
                      onChanged: _leaving
                          ? null
                          : (value) => setState(() => _book = value ?? false),
                      title: Text(
                        t.pick('加入错题本', 'Add to the wrong-problem book'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.s24),
                if (again) ...[
                  AppButton(
                    label: t.pick('再练一次', 'Practice again'),
                    busy: _leaving,
                    onPressed: _leaving ? null : () => _close(true),
                  ),
                  const SizedBox(height: AppSpace.s8),
                ],
                AppButton(
                  label: t.backToToday,
                  secondary: again,
                  busy: _leaving,
                  onPressed: _leaving ? null : () => _close(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCheer {
  const _ReportCheer(this.title, this.icon, this.tone);

  final String? title;
  final IconData icon;
  final Color tone;
}

class _ReportMark extends StatelessWidget {
  const _ReportMark({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: motionBase,
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s12),
          child: Icon(icon, size: 36, color: color),
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpace.rMd),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s8,
            vertical: AppSpace.s12,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
          decoration: InputDecoration(
            labelText: Copy.of(context).parentCode,
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
            decoration: InputDecoration(
              labelText: Copy.of(
                context,
              ).pick('再输入一次密码', 'Enter the code again'),
              counterText: '',
            ),
          ),
        ],
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s8),
            child: Text(
              Copy.of(context).pick(
                '${widget.waitSeconds} 秒后再试。',
                'Try again in ${widget.waitSeconds} seconds.',
              ),
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
          label: Copy.of(context).cancel,
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpace.s8),
        AppButton(
          label: Copy.of(context).continueLabel,
          onPressed: locked
              ? null
              : () {
                  final pin = _first.text;
                  final again = widget.create ? _second.text : null;
                  if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                    setState(
                      () => _error = Copy.of(
                        context,
                      ).pick('请输入四位数字。', 'Enter four digits.'),
                    );
                    return;
                  }
                  if (widget.create && pin != again) {
                    setState(
                      () => _error = Copy.of(
                        context,
                      ).pick('两次密码不一致。', 'Those codes do not match.'),
                    );
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

String clockLabel(int elapsedMs) {
  final seconds = (elapsedMs / 1000).floor().clamp(0, 24 * 3600);
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

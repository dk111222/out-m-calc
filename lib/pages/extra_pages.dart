import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../app/platform_auth.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../l10n/trick_zh.dart';
import '../domain/engine.dart';
import '../export/pdfs.dart';
import '../ui/avatars.dart';
import '../ui/gates.dart';
import '../ui/kit.dart';
import 'home_pages.dart';

bool _hasAccount(DeviceSettings settings) =>
    settings.accountSubject != null || settings.accountEmail != null;

String parentAccountName(DeviceSettings settings, Copy t) {
  final email = settings.accountEmail;
  final name = settings.accountName;
  if (email != null && email.isNotEmpty) return email;
  if (name != null && name.isNotEmpty) return name;
  if (settings.accountProvider == 'apple') return t.appleAccount;
  if (settings.accountProvider == 'google') return t.googleAccount;
  return t.parentAccount;
}

class ParentSignInButton extends ConsumerStatefulWidget {
  const ParentSignInButton({super.key});

  @override
  ConsumerState<ParentSignInButton> createState() => _ParentSignInButtonState();
}

class _ParentSignInButtonState extends ConsumerState<ParentSignInButton> {
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    final android = Theme.of(context).platform == TargetPlatform.android;
    final apple = Theme.of(context).platform == TargetPlatform.iOS;
    final label = android
        ? t.signInWithGoogle
        : apple
        ? t.signInWithApple
        : t.signInUnavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: label,
          busy: _busy,
          onPressed: android || apple ? _signIn : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.s12),
          Text(_error!, style: TextStyle(color: AppColors.of(context).danger)),
        ],
      ],
    );
  }

  Future<void> _signIn() async {
    final app = ref.read(appProvider);
    final t = Copy.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final identity = await signInOnThisPhone();
      if (!mounted) return;
      if (identity == null) {
        setState(() => _busy = false);
        return;
      }
      final error = await app.signInWithIdentity(
        provider: identity.provider,
        subject: identity.subject,
        email: identity.email,
        name: identity.name,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = t.signInFailed;
      });
    }
  }
}

class ErrorTrainingGate extends ConsumerWidget {
  const ErrorTrainingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    if (app.childMode) {
      return const Text(
        'Wrong-problem practice needs a parent sign-in and a subscription. Ask a parent to turn it on in Settings.',
      );
    }
    if (app.settings.signedIn && !app.settings.subscriptionActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.signedInAs(parentAccountName(app.settings, t)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          const Text(
            'Wrong-problem practice is a subscription. Lessons and speed drills stay available without it. The subscription is recorded on this device.',
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(label: 'Subscribe', onPressed: () => app.subscribe()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.parentAccount,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.s8),
        Text(t.wrongPracticeSignIn),
        const SizedBox(height: AppSpace.s16),
        const ParentSignInButton(),
      ],
    );
  }
}

class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  bool _loading = true;
  String? _error;
  String? _trickId;
  List<WrongItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = ref.read(appProvider);
    final id = app.activeLearnerId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final items = await app.store.wrongs(id);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
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
    if (!app.errorTrainingOpen) {
      return PageFrame(
        title: 'Wrong problems',
        banner: app.banner,
        leading: IconButton(
          tooltip: Copy.of(context).back,
          onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
          icon: const Icon(Icons.arrow_back),
        ),
        body: const ErrorTrainingGate(),
      );
    }
    final open = _items.where((item) => !item.reviewedOk).toList();
    final filtered = _trickId == null
        ? open
        : open.where((item) => item.trickId == _trickId).toList();
    final tricks = open.map((item) => item.trickId).toSet().toList();
    final groups = <String, List<WrongItem>>{};
    for (final item in filtered) {
      final day = formatYmd(item.createdAt.toLocal());
      groups.putIfAbsent(day, () => []).add(item);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final t = Copy.of(context);
    return PageFrame(
      title: t.wrongProblems,
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go(app.childMode ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: _loading
          ? const SkeletonBlock()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tricks.isNotEmpty)
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: _trickId,
                    hint: Text(t.pick('全部技巧', 'All tricks')),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(t.pick('全部技巧', 'All tricks')),
                      ),
                      for (final id in tricks)
                        DropdownMenuItem(
                          value: id,
                          child: Text(
                            app.catalog.byId(id) == null
                                ? id
                                : localizeTrick(app.catalog.byId(id)!, t).title,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _trickId = value),
                  ),
                const SizedBox(height: AppSpace.s12),
                if (filtered.isEmpty)
                  Text(t.pick('还没有错题', 'No wrong problems yet'))
                else
                  for (final day in days) ...[
                    Text(day, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      t.pick(
                        '${groups[day]!.length} 题待练',
                        '${groups[day]!.length} to practice',
                      ),
                    ),
                    for (final item in groups[day]!)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.prompt),
                        subtitle: Text(
                          t.pick(
                            '你输入了 ${item.userAnswer}。结果是 ${item.correctAnswer}。${item.failedStep == null ? '' : '第 ${item.failedStep} 步。'}',
                            'You entered ${item.userAnswer}. ${item.correctAnswer} is the result.${item.failedStep == null ? '' : ' Step ${item.failedStep}.'}',
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref.read(practiceProvider).startRepair(item);
                            final view = ref.read(practiceProvider).view;
                            if (view != null && context.mounted) {
                              context.go(
                                '/practice/${item.trickId}/${view.phase}',
                              );
                            }
                          },
                          child: Text(t.practice),
                        ),
                      ),
                    const SizedBox(height: AppSpace.s16),
                  ],
              ],
            ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.child = false});

  final bool child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    if (!child && app.childMode) {
      return PageFrame(title: t.settings, body: Text(t.parentNeedsThis));
    }
    final settings = app.settings;
    return PageFrame(
      title: child ? t.me : t.settings,
      banner: app.banner,
      leading: child
          ? null
          : IconButton(
              tooltip: t.back,
              onPressed: () => context.go('/adult'),
              icon: const Icon(Icons.arrow_back),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (child) ...[
            const LearnerHub(),
            const SizedBox(height: AppSpace.s24),
            Text(t.settings, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s16),
          ],
          if (!child) ...[
            Text(t.languageWord, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'zh', label: Text('中文')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.language == 'en' ? 'en' : 'zh'},
              onSelectionChanged: (value) =>
                  app.updateSettings(settings.copyWith(language: value.first)),
            ),
            const SizedBox(height: AppSpace.s16),
            Text(t.appearance, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', label: Text(t.system)),
                ButtonSegment(value: 'light', label: Text(t.light)),
                ButtonSegment(value: 'dark', label: Text(t.dark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) =>
                  app.updateSettings(settings.copyWith(themeMode: value.first)),
            ),
            const SizedBox(height: AppSpace.s16),
            Text(t.textSize, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.s8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'small', label: Text(t.small)),
                ButtonSegment(value: 'medium', label: Text(t.medium)),
                ButtonSegment(value: 'large', label: Text(t.large)),
              ],
              selected: {settings.textScale},
              onSelectionChanged: (value) =>
                  app.updateSettings(settings.copyWith(textScale: value.first)),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.soundEffects),
            value: settings.soundEnabled,
            onChanged: (value) =>
                app.updateSettings(settings.copyWith(soundEnabled: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.readProblem),
            value: settings.readAloudEnabled,
            onChanged: (value) =>
                app.updateSettings(settings.copyWith(readAloudEnabled: value)),
          ),
          if (!child) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Copy.of(context).pick('使用数据', 'Usage numbers')),
              subtitle: Text(
                Copy.of(context).pick(
                  '这一版不会把它们发送到别处。开关只保存你的选择。',
                  'This version does not send them anywhere. The switch only saves your choice.',
                ),
              ),
              value: settings.telemetryEnabled,
              onChanged: (value) => app.updateSettings(
                settings.copyWith(telemetryEnabled: value),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Copy.of(context).parentCode),
              subtitle: Text(
                settings.parentPinHash == null
                    ? Copy.of(context).pick('还没设置', 'Not set yet')
                    : Copy.of(
                        context,
                      ).pick('已保存在这台设备上', 'Saved on this device'),
              ),
              onTap: () async {
                if (app.settings.parentPinHash == null) {
                  await requireParentCode(
                    context,
                    app,
                    title: Copy.of(context).parentCode,
                    body: 'Set a four-digit code.',
                    action: (pin, again) => app.submitPin(pin, again: again),
                  );
                  return;
                }
                final ok = await requireParentCode(
                  context,
                  app,
                  title: Copy.of(context).parentCode,
                  body: 'Enter the current parent code.',
                  action: (pin, _) => app.submitPin(pin),
                );
                if (!ok || !context.mounted) return;
                await requireParentCode(
                  context,
                  app,
                  title: Copy.of(context).parentCode,
                  body: 'Set a new four-digit code.',
                  create: true,
                  action: (pin, again) => app.setNewPin(pin, again),
                );
              },
            ),
            const SizedBox(height: AppSpace.s16),
            Text(
              'Wrong-problem practice',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              settings.signedIn
                  ? t.signedInAs(parentAccountName(settings, t))
                  : t.notSignedIn,
            ),
            Text(
              settings.subscriptionActive
                  ? 'Subscription is on for this account.'
                  : 'A subscription is required before a child can practice missed problems.',
            ),
            const SizedBox(height: AppSpace.s12),
            if (!settings.signedIn)
              const ParentSignInButton()
            else ...[
              if (!settings.subscriptionActive)
                AppButton(label: 'Subscribe', onPressed: () => app.subscribe()),
              const SizedBox(height: AppSpace.s8),
              AppButton(
                label: 'Sign out',
                secondary: true,
                onPressed: () async {
                  final provider = settings.accountProvider;
                  await endProviderSession(provider);
                  await app.signOut();
                },
              ),
            ],
            const SizedBox(height: AppSpace.s16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(Copy.of(context).privacyPolicy),
              onTap: () => context.go('/settings/privacy'),
            ),
            const SizedBox(height: AppSpace.s16),
            Text(
              'Printing and extra learners are included on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: _hasAccount(settings) ? t.deleteAccount : t.deleteAll,
              destructive: true,
              onPressed: () async {
                final hasAccount = _hasAccount(settings);
                final provider = settings.accountProvider;
                final leave = await showConfirm(
                  context,
                  title: hasAccount ? t.deleteAccount : t.deleteAll,
                  body: hasAccount ? t.deleteAccountBody : t.deleteAllBody,
                  confirm: hasAccount ? t.deleteAccount : t.deleteAll,
                  destructive: true,
                );
                if (!leave || !context.mounted) return;
                final ok = await requireParentCode(
                  context,
                  app,
                  title: t.parentCode,
                  body: hasAccount
                      ? t.deleteAccountCode
                      : 'Enter the parent code to delete everything on this device.',
                  action: (pin, again) => hasAccount
                      ? app.deleteAccount(pin, again: again)
                      : app.wipeAll(pin, again: again),
                );
                if (ok && hasAccount) await endProviderSession(provider, revoke: true);
                if (ok && context.mounted) context.go('/child');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: Copy.of(context).privacyPolicy,
      leading: IconButton(
        tooltip: Copy.of(context).back,
        onPressed: () => context.go('/settings'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.of(context).pick(
              'StepMath 把练习存在这台设备上。学技巧和速算不需要账号。错题练习需要家长登录：Android 使用 Google，iPhone 使用 Apple。登录只留在这台设备上。设置里的「删除账号」会清掉这个登录、孩子和练习。',
              'StepMath stores practice on this device. Lessons and speed drills do not ask for an account. Wrong-problem practice asks a parent to sign in: Android uses Google, and iPhone uses Apple. That sign-in stays on this device. Delete account in Settings removes the sign-in, the children, and the practice.',
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            Copy.of(context).pick(
              '孩子名字可以不填。留空时会用“学员”。访客练习也用同样的方式保存。',
              'A learner name is optional. If you leave it blank, the app uses Learner. Guest practice is stored the same way.',
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            Copy.of(context).pick(
              '家长密码以哈希保存，不保存那四位数字。',
              'The parent code is stored as a hash, not as the four digits.',
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            Copy.of(context).pick(
              '应用不显示广告。这一版不会把使用数据发送到别处。设置里的开关只记录你的选择。',
              'The app does not show ads. This version does not send usage numbers anywhere. The switch in Settings only records your choice.',
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            Copy.of(context).pick(
              '删除账号或删除这台设备上的全部数据，都会清掉孩子、练习和家长密码。之后应用会重新开始。',
              'Delete account, or delete all data on this device, erases learners, practice, and the parent code. After that, the app starts over.',
            ),
          ),
        ],
      ),
    );
  }
}

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key, required this.learnerId});

  final String learnerId;

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  bool _loading = true;
  String? _error;
  WeeklyReport? _report;
  List<Certificate> _certificates = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = ref.read(appProvider);
    try {
      final attempts = await app.store.attempts(widget.learnerId);
      final rounds = await app.store.speeds(widget.learnerId);
      final mastery = await app.store.masteries(widget.learnerId);
      final certificates = await app.store.certificates(widget.learnerId);
      if (!mounted) return;
      setState(() {
        _report = buildWeeklyReport(
          today: app.clock.today,
          attempts: attempts,
          rounds: rounds,
          mastery: mastery,
        );
        _certificates = certificates;
        _loading = false;
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
    final learner = app.learnerById(widget.learnerId);
    final report = _report;
    final t = Copy.of(context);
    return PageFrame(
      title: t.pick('最近 7 天', 'Last 7 days'),
      banner: _error,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: _loading || report == null
          ? const SkeletonBlock()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (learner != null) ...[
                      ChildAvatar(id: learner.avatar, size: 40),
                      const SizedBox(width: AppSpace.s12),
                    ],
                    Expanded(
                      child: Text(
                        learner?.displayName ?? t.learnerStem,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s12),
                if (report.problems == 0 && report.days == 0)
                  Text(t.pick('最近 7 天没有练习。', 'No practice in the last 7 days.'))
                else ...[
                  Text(
                    t.pick(
                      '练习天数：${report.days}',
                      'Days practiced: ${report.days}',
                    ),
                  ),
                  Text(
                    t.pick(
                      '题数：${report.problems}',
                      'Problems: ${report.problems}',
                    ),
                  ),
                  Text(
                    t.pick(
                      '正确：${(report.accuracy * 100).round()}%',
                      'Correct: ${(report.accuracy * 100).round()}%',
                    ),
                  ),
                  Text(
                    t.pick(
                      '新掌握：${report.newMastered}',
                      'New mastered: ${report.newMastered}',
                    ),
                  ),
                  Text(
                    report.mostMissedStep == null
                        ? t.pick('没有特别容易错的步骤。', 'No missed step stood out.')
                        : t.pick(
                            '最容易错的步骤：${report.mostMissedStep}（${report.missedStepCount}）',
                            'Most missed step: ${report.mostMissedStep} (${report.missedStepCount})',
                          ),
                  ),
                  if (report.correctPerMinute != null)
                    Text(
                      t.pick(
                        '速度：每分钟 ${report.correctPerMinute!.toStringAsFixed(1)} 题正确',
                        'Speed: ${report.correctPerMinute!.toStringAsFixed(1)} correct per minute',
                      ),
                    ),
                ],
                const SizedBox(height: AppSpace.s24),
                Text(
                  Copy.of(context).pick('奖状', 'Certificate'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_certificates.isEmpty)
                  Text(
                    Copy.of(context).pick(
                      '掌握一个技巧，或速算刷新最好成绩后，会出现奖状。',
                      'A certificate appears after a trick is mastered or a speed best is set.',
                    ),
                  )
                else
                  for (final certificate in _certificates)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(certificate.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(
                        '/export/certificate?learner=${learner?.id}&id=${certificate.id}',
                      ),
                    ),
              ],
            ),
    );
  }
}

class WorksheetPage extends ConsumerStatefulWidget {
  const WorksheetPage({super.key, required this.trickId});

  final String trickId;

  @override
  ConsumerState<WorksheetPage> createState() => _WorksheetPageState();
}

class _WorksheetPageState extends ConsumerState<WorksheetPage> {
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final trick = app.catalog.byId(widget.trickId);
    if (app.childMode) {
      return PageFrame(
        title: Copy.of(context).worksheet,
        body: Text(Copy.of(context).parentNeedsThis),
      );
    }
    if (!app.settings.printUnlocked) {
      return PageFrame(
        title: Copy.of(context).worksheet,
        body: Text(
          Copy.of(context).pick(
            '练习页留在这台设备上。这台设备还没打开打印。',
            'Worksheets stay on this device. Printing is turned off until it is included for this device.',
          ),
        ),
      );
    }
    if (trick == null || !trick.ready) {
      return PageFrame(
        title: Copy.of(context).worksheet,
        body: Text(Copy.of(context).notReady),
      );
    }
    return PageFrame(
      title: Copy.of(context).worksheet,
      banner: _error,
      leading: IconButton(
        tooltip: Copy.of(context).back,
        onPressed: () => context.go(
          '/tricks/${widget.trickId}?learner=${app.activeLearnerId ?? ''}',
        ),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizeTrick(trick, Copy.of(context)).title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(
            Copy.of(context).pick(
              '一个技巧、步骤、20 道题，以及答案页。',
              'One trick, the steps, 20 problems, and an answer page.',
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: Copy.of(context).pick('打开打印预览', 'Open print preview'),
            busy: _busy,
            onPressed: () async {
              setState(() {
                _busy = true;
                _error = null;
              });
              try {
                final problems = _twenty(trick.id);
                final regular = await rootBundle.load(
                  'assets/fonts/SourceSans3-Regular.ttf',
                );
                final bold = await rootBundle.load(
                  'assets/fonts/SourceSans3-Semibold.ttf',
                );
                final bytes = await buildWorksheet(
                  trick: trick,
                  problems: problems,
                  regular: regular,
                  bold: bold,
                );
                await Printing.layoutPdf(
                  onLayout: (_) async => bytes,
                  name: 'stepmath-${trick.id}.pdf',
                );
              } catch (_) {
                if (mounted)
                  setState(() => _error = Copy.of(context).couldNotSave);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }

  List<Problem> _twenty(String trickId) {
    final rng = Random();
    final problems = <Problem>[];
    final seen = <String>{};
    var guard = 0;
    while (problems.length < 20 && guard < 80) {
      guard += 1;
      final problem = generateTrick(trickId, standard: true, rng: rng);
      if (seen.add(problem.signature) || guard > 40) problems.add(problem);
    }
    return problems;
  }
}

class CertificatePage extends ConsumerStatefulWidget {
  const CertificatePage({super.key, required this.learnerId, required this.id});

  final String learnerId;
  final String id;

  @override
  ConsumerState<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends ConsumerState<CertificatePage> {
  String? _error;
  bool _busy = false;
  Certificate? _certificate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await ref
        .read(appProvider)
        .store
        .certificates(widget.learnerId);
    if (!mounted) return;
    setState(() {
      for (final row in rows) {
        if (row.id == widget.id) _certificate = row;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final learner = app.learnerById(widget.learnerId);
    final certificate = _certificate;
    if (!app.settings.printUnlocked) {
      return PageFrame(
        title: Copy.of(context).pick('奖状', 'Certificate'),
        body: Text(
          Copy.of(context).pick(
            '奖状留在这台设备上。这台设备还没打开打印。',
            'Certificates stay on this device. Printing is turned off until it is included for this device.',
          ),
        ),
      );
    }
    return PageFrame(
      title: Copy.of(context).pick('奖状', 'Certificate'),
      banner: _error,
      leading: IconButton(
        tooltip: Copy.of(context).back,
        onPressed: () => context.go('/report/${widget.learnerId}'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: certificate == null
          ? Text(
              Copy.of(
                context,
              ).pick('这台设备上没有这张奖状。', 'That certificate is not on this device.'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.s8),
                Text(learner?.displayName ?? 'Learner'),
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  label: Copy.of(context).pick('打开打印预览', 'Open print preview'),
                  busy: _busy,
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      final regular = await rootBundle.load(
                        'assets/fonts/SourceSans3-Regular.ttf',
                      );
                      final bold = await rootBundle.load(
                        'assets/fonts/SourceSans3-Semibold.ttf',
                      );
                      final bytes = await buildCertificate(
                        learnerName: learner?.displayName ?? 'Learner',
                        title: certificate.title,
                        dateLabel: DateFormat.yMMMd().format(
                          certificate.issuedAt.toLocal(),
                        ),
                        regular: regular,
                        bold: bold,
                      );
                      await Printing.layoutPdf(
                        onLayout: (_) async => bytes,
                        name: 'stepmath-certificate.pdf',
                      );
                    } catch (_) {
                      if (mounted) {
                        setState(() => _error = Copy.of(context).couldNotSave);
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                ),
              ],
            ),
    );
  }
}

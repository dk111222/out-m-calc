import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../domain/engine.dart';
import '../export/pdfs.dart';
import '../ui/gates.dart';
import '../ui/kit.dart';

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
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
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
    return PageFrame(
      title: 'Wrong problems',
      banner: _error ?? app.banner,
      leading: IconButton(
        tooltip: 'Back',
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
                    hint: const Text('All tricks'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All tricks')),
                      for (final id in tricks)
                        DropdownMenuItem(
                          value: id,
                          child: Text(app.catalog.byId(id)?.title ?? id),
                        ),
                    ],
                    onChanged: (value) => setState(() => _trickId = value),
                  ),
                const SizedBox(height: AppSpace.s12),
                if (filtered.isEmpty)
                  const Text('No wrong problems yet')
                else
                  for (final day in days) ...[
                    Text(day, style: Theme.of(context).textTheme.titleMedium),
                    Text('${groups[day]!.length} to practice'),
                    for (final item in groups[day]!)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.prompt),
                        subtitle: Text(
                          'You entered ${item.userAnswer}. ${item.correctAnswer} is the result.'
                          '${item.failedStep == null ? '' : ' Step ${item.failedStep}.'}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref.read(practiceProvider).startRepair(item);
                            final view = ref.read(practiceProvider).view;
                            if (view != null && context.mounted) {
                              context.go('/practice/${item.trickId}/${view.phase}');
                            }
                          },
                          child: const Text('Practice'),
                        ),
                      ),
                    const SizedBox(height: AppSpace.s16),
                  ],
                if (!app.childMode && _trickId != null)
                  AppButton(
                    label: 'Worksheet',
                    secondary: true,
                    onPressed: () => context.go(
                      '/export/worksheet?trickId=$_trickId&learner=${app.activeLearnerId}',
                    ),
                  ),
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
    if (!child && app.childMode) {
      return PageFrame(
        title: 'Settings',
        body: const Text('A parent needs to open this.'),
      );
    }
    final settings = app.settings;
    return PageFrame(
      title: child ? 'Practice settings' : 'Settings',
      banner: app.banner,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(child ? '/child' : '/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) => app.updateSettings(
              settings.copyWith(themeMode: value.first),
            ),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('Text size', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'small', label: Text('Small')),
              ButtonSegment(value: 'medium', label: Text('Medium')),
              ButtonSegment(value: 'large', label: Text('Large')),
            ],
            selected: {settings.textScale},
            onSelectionChanged: (value) => app.updateSettings(
              settings.copyWith(textScale: value.first),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound effects'),
            value: settings.soundEnabled,
            onChanged: (value) =>
                app.updateSettings(settings.copyWith(soundEnabled: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Read the problem'),
            subtitle: const Text('The problem is spoken. Keys stay quiet.'),
            value: settings.readAloudEnabled,
            onChanged: (value) =>
                app.updateSettings(settings.copyWith(readAloudEnabled: value)),
          ),
          if (!child) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usage numbers'),
              subtitle: const Text(
                'This version does not send them anywhere. The switch only saves your choice.',
              ),
              value: settings.telemetryEnabled,
              onChanged: (value) => app.updateSettings(
                settings.copyWith(telemetryEnabled: value),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Parent code'),
              subtitle: Text(
                settings.parentPinHash == null ? 'Not set yet' : 'Saved on this device',
              ),
              onTap: () async {
                if (app.settings.parentPinHash == null) {
                  await requireParentCode(
                    context,
                    app,
                    title: 'Parent code',
                    body: 'Set a four-digit code.',
                    action: (pin, again) => app.submitPin(pin, again: again),
                  );
                  return;
                }
                final ok = await requireParentCode(
                  context,
                  app,
                  title: 'Parent code',
                  body: 'Enter the current parent code.',
                  action: (pin, _) => app.submitPin(pin),
                );
                if (!ok || !context.mounted) return;
                await requireParentCode(
                  context,
                  app,
                  title: 'Parent code',
                  body: 'Set a new four-digit code.',
                  create: true,
                  action: (pin, again) => app.setNewPin(pin, again),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Privacy policy'),
              onTap: () => context.go('/settings/privacy'),
            ),
            const SizedBox(height: AppSpace.s16),
            Text(
              'Printing and extra learners are included on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpace.s16),
            AppButton(
              label: 'Delete all data on this device',
              destructive: true,
              onPressed: () async {
                final leave = await showConfirm(
                  context,
                  title: 'Delete all data on this device',
                  body: 'Learners, practice, and the parent code will be erased.',
                  confirm: 'Delete all data',
                  destructive: true,
                );
                if (!leave || !context.mounted) return;
                final ok = await requireParentCode(
                  context,
                  app,
                  title: 'Parent code',
                  body: 'Enter the parent code to delete everything on this device.',
                  action: (pin, again) => app.wipeAll(pin, again: again),
                );
                if (ok && context.mounted) context.go('/start');
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
      title: 'Privacy policy',
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go('/settings'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'StepMath stores practice on this device. We do not ask for an account, an email address, or a precise location.',
          ),
          SizedBox(height: AppSpace.s12),
          Text(
            'A learner name is optional. If you leave it blank, the app uses Learner. Guest practice is stored the same way.',
          ),
          SizedBox(height: AppSpace.s12),
          Text(
            'The parent code is stored as a hash, not as the four digits.',
          ),
          SizedBox(height: AppSpace.s12),
          Text(
            'The app does not show ads. This version does not send usage numbers anywhere. The switch in Settings only records your choice.',
          ),
          SizedBox(height: AppSpace.s12),
          Text(
            'Delete all data on this device erases learners, practice, and the parent code. After that, the app starts over.',
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
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final learner = app.learnerById(widget.learnerId);
    final report = _report;
    return PageFrame(
      title: 'Last 7 days',
      banner: _error,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go('/adult'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: _loading || report == null
          ? const SkeletonBlock()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(learner?.displayName ?? 'Learner', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpace.s12),
                if (report.problems == 0 && report.days == 0)
                  const Text('No practice in the last 7 days.')
                else ...[
                  Text('Days practiced: ${report.days}'),
                  Text('Problems: ${report.problems}'),
                  Text('Correct: ${(report.accuracy * 100).round()}%'),
                  Text('New mastered: ${report.newMastered}'),
                  Text(
                    report.mostMissedStep == null
                        ? 'No missed step stood out.'
                        : 'Most missed step: ${report.mostMissedStep} (${report.missedStepCount})',
                  ),
                  if (report.correctPerMinute != null)
                    Text(
                      'Speed: ${report.correctPerMinute!.toStringAsFixed(1)} correct per minute',
                    ),
                ],
                const SizedBox(height: AppSpace.s24),
                Text('Certificate', style: Theme.of(context).textTheme.titleMedium),
                if (_certificates.isEmpty)
                  const Text('A certificate appears after a trick is mastered or a speed best is set.')
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
      return const PageFrame(
        title: 'Worksheet',
        body: Text('A parent needs to open this.'),
      );
    }
    if (!app.settings.printUnlocked) {
      return const PageFrame(
        title: 'Worksheet',
        body: Text(
          'Worksheets stay on this device. Printing is turned off until it is included for this device.',
        ),
      );
    }
    if (trick == null || !trick.ready) {
      return const PageFrame(
        title: 'Worksheet',
        body: Text('This trick is not ready to practice yet.'),
      );
    }
    return PageFrame(
      title: 'Worksheet',
      banner: _error,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(
          '/tricks/${widget.trickId}?learner=${app.activeLearnerId ?? ''}',
        ),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trick.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          const Text('One trick, the steps, 20 problems, and an answer page.'),
          const SizedBox(height: AppSpace.s16),
          AppButton(
            label: 'Open print preview',
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
                if (mounted) setState(() => _error = 'Could not save. Try again.');
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
    final rows = await ref.read(appProvider).store.certificates(widget.learnerId);
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
      return const PageFrame(
        title: 'Certificate',
        body: Text(
          'Certificates stay on this device. Printing is turned off until it is included for this device.',
        ),
      );
    }
    return PageFrame(
      title: 'Certificate',
      banner: _error,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.go('/report/${widget.learnerId}'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: certificate == null
          ? const Text('That certificate is not on this device.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(certificate.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpace.s8),
                Text(learner?.displayName ?? 'Learner'),
                const SizedBox(height: AppSpace.s16),
                AppButton(
                  label: 'Open print preview',
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
                        setState(() => _error = 'Could not save. Try again.');
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

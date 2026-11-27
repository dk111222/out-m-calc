import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../app/platform_auth.dart';
import '../app/providers.dart';
import '../app/session.dart';
import '../app/theme.dart';
import '../domain/core.dart';
import '../l10n/copy.dart';
import '../ui/avatars.dart';
import '../ui/gates.dart';
import '../ui/kit.dart';
import '../ui/platform_prompt.dart';
import 'avatar_crop_page.dart';

/// The parent tab.
///
/// Login type and the child list live on [AppController]. Widgets below
/// watch `appProvider` (Riverpod), so a sign-in or a new child rebuilds
/// the header, the cap, and the cards together.
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvatarHeader(),
        SizedBox(height: AppSpace.s24),
        ChildManageSection(),
        SizedBox(height: AppSpace.s16),
        SettingList(),
      ],
    );
  }
}

class AvatarHeader extends ConsumerStatefulWidget {
  const AvatarHeader({super.key});

  @override
  ConsumerState<AvatarHeader> createState() => _AvatarHeaderState();
}

class _AvatarHeaderState extends ConsumerState<AvatarHeader> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final settings = app.settings;
    final colors = AppColors.of(context);
    final guest = settings.accountProvider == 'guest';
    final name = _accountName(settings, t);
    return Column(
      children: [
        _AvatarButton(
          path: guest ? null : settings.accountAvatarPath,
          busy: _busy,
          onPressed: guest || _busy ? null : () => _edit(settings),
        ),
        const SizedBox(height: AppSpace.s12),
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.s8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.sunken,
            borderRadius: BorderRadius.circular(AppSpace.rPill),
          ),
          child: Text(
            t.loginMethod(settings.accountProvider),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _edit(DeviceSettings settings) async {
    final source = await askAvatarSource(context);
    if (source == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source == ImageSourceChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      final raw = await picked.readAsBytes();
      if (!mounted) return;
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => AvatarCropPage(bytes: raw)),
      );
      if (cropped == null || !mounted) return;
      final keep = await confirmAvatarPreview(
        context,
        MemoryImage(cropped),
      );
      if (!keep || !mounted) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/account-avatar.png';
      final file = File(path);
      await file.writeAsBytes(cropped, flush: true);
      await FileImage(file).evict();
      final app = ref.read(appProvider);
      await app.updateSettings(
        app.settings.copyWith(
          accountAvatarPath: path,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showPlatformMessage(
        context,
        Copy.of(context).pick(
          '这张照片没能保存。再试一次。',
          'The photo could not be saved. Try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.path,
    required this.busy,
    required this.onPressed,
  });

  final String? path;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final file = path == null ? null : File(path!);
    final hasFile = file != null && file.existsSync();
    final editable = onPressed != null;
    return Semantics(
      button: editable,
      label: editable ? Copy.of(context).editAvatar : null,
      child: Material(
        color: colors.sunken,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasFile)
                  ClipOval(
                    child: Image.file(
                      file,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      key: ValueKey(file.lastModifiedSync().millisecondsSinceEpoch),
                    ),
                  )
                else
                  Icon(Icons.person, size: 40, color: colors.textMuted),
                if (busy)
                  const CircularProgressIndicator(strokeWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChildManageSection extends ConsumerWidget {
  const ChildManageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final cap = learnerCapFor(app.settings);
    final full = app.learners.length >= cap;
    final selectedId =
        app.activeLearnerId ??
        (app.learners.isEmpty ? null : app.learners.first.id);
    final cards = <Widget>[
      for (final learner in app.learners)
        _ProfileCard(
          label: learner.displayName,
          subtitle: t.grade(learner.grade),
          selected: learner.id == selectedId,
          avatar: ChildAvatar(id: learner.avatar, size: 48),
          onPressed: () => app.enterChild(learner.id),
          onLongPress: () => context.go('/learner/edit/${learner.id}'),
        ),
      _ProfileCard(
        label: t.addLearner,
        muted: full,
        avatar: const _AskAvatar(size: 48),
        onPressed: () {
          if (full) {
            showPlatformMessage(
              context,
              t.learnerLimitMessage(app.settings.accountProvider),
            );
            return;
          }
          context.go('/learner/new');
        },
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              t.childrenSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const ReportEntry(),
          ],
        ),
        const SizedBox(height: AppSpace.s12),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.s12),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.label,
    required this.avatar,
    required this.onPressed,
    this.subtitle,
    this.onLongPress,
    this.selected = false,
    this.muted = false,
  });

  final String label;
  final String? subtitle;
  final Widget avatar;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(AppSpace.rLg);
    return Opacity(
      opacity: muted ? 0.45 : 1,
      child: SizedBox(
        width: 132,
        child: Material(
          color: selected
              ? colors.accent.withValues(alpha: 0.08)
              : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? colors.accent : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  avatar,
                  const SizedBox(height: AppSpace.s8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpace.s4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Same rounded square as a child portrait, with a question mark.
class _AskAvatar extends StatelessWidget {
  const _AskAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = size * 0.22;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colors.border),
          boxShadow: colors.cardShadow,
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: size * 0.46,
              height: 1,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class ReportEntry extends StatelessWidget {
  const ReportEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: colors.accent,
        minimumSize: const Size(AppSpace.minTarget, AppSpace.minTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () => context.go('/family'),
      child: Text(Copy.of(context).familyReport),
    );
  }
}

class SettingList extends ConsumerWidget {
  const SettingList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final rows = <_SettingRow>[
      _SettingRow(
        icon: Icons.person_outline,
        label: t.accountSettings,
        onTap: () => context.go('/account'),
      ),
      _SettingRow(
        icon: Icons.notifications_none,
        label: t.notificationSettings,
        onTap: () => context.go('/notifications'),
      ),
      _SettingRow(
        icon: Icons.shield_outlined,
        label: t.privacyPolicy,
        onTap: () => context.go('/settings/privacy?from=me'),
      ),
      _SettingRow(
        icon: Icons.info_outline,
        label: t.aboutUs,
        onTap: () => context.go('/about'),
      ),
      _SettingRow(
        icon: Icons.logout,
        label: t.signOut,
        danger: true,
        onTap: () => _signOut(context, ref),
      ),
    ];
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.rLg),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            rows[i],
          ],
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final leave = await confirmSignOut(context);
    if (!leave || !context.mounted) return;
    final app = ref.read(appProvider);
    await endProviderSession(app.settings.accountProvider);
    await app.signOut();
    if (context.mounted) context.go('/sign-in');
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ink = danger ? colors.danger : colors.text;
    return ListTile(
      leading: Icon(icon, color: ink),
      title: Text(label, style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right, color: colors.textMuted),
      onTap: onTap,
      minTileHeight: AppSpace.minTarget,
    );
  }
}

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final settings = app.settings;
    return PageFrame(
      title: t.accountSettings,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/prefs'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _accountName(settings, t),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s8),
          Text(t.loginMethod(settings.accountProvider)),
          const SizedBox(height: AppSpace.s24),
          AppButton(
            label: t.closeAccount,
            destructive: true,
            onPressed: () => closeParentAccount(context, app, settings),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final t = Copy.of(context);
    final settings = app.settings;
    return PageFrame(
      title: t.notificationSettings,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/prefs'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.notificationBody),
          const SizedBox(height: AppSpace.s16),
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
            onChanged: (value) => app.updateSettings(
              settings.copyWith(readAloudEnabled: value),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Copy.of(context);
    return PageFrame(
      title: t.aboutUs,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/prefs'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('StepMath', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.s8),
          const Text('1.0.0'),
          const SizedBox(height: AppSpace.s16),
          Text(t.aboutBody),
        ],
      ),
    );
  }
}

class FamilyReportPage extends ConsumerStatefulWidget {
  const FamilyReportPage({super.key});

  @override
  ConsumerState<FamilyReportPage> createState() => _FamilyReportPageState();
}

class _FamilyReportPageState extends ConsumerState<FamilyReportPage> {
  var _loading = true;
  String? _error;
  List<({String id, String name, WeeklyReport report})> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(appProvider).familyReports();
      if (!mounted) return;
      setState(() {
        _rows = rows;
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
    final t = Copy.of(context);
    final colors = AppColors.of(context);
    final problems = _rows.fold<int>(0, (sum, row) => sum + row.report.problems);
    return PageFrame(
      title: t.familyReportTitle,
      banner: _error,
      leading: IconButton(
        tooltip: t.back,
        onPressed: () => context.go('/prefs'),
        icon: const Icon(Icons.arrow_back),
      ),
      body: _loading
          ? const SkeletonBlock()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.pick(
                    '最近 7 天共 $problems 题',
                    '$problems problems in the last 7 days',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.s16),
                if (_rows.isEmpty)
                  Text(t.noChildrenYet)
                else
                  for (final row in _rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s12),
                      child: Material(
                        color: colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpace.rLg),
                          side: BorderSide(color: colors.border),
                        ),
                        child: ListTile(
                          title: Text(row.name),
                          subtitle: Text(
                            t.pick(
                              '${row.report.problems} 题，正确 ${(row.report.accuracy * 100).round()}%',
                              '${row.report.problems} problems, ${(row.report.accuracy * 100).round()}% correct',
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: colors.textMuted,
                          ),
                          onTap: () async {
                            await ref.read(appProvider).enterChild(row.id);
                            if (context.mounted) {
                              context.go('/report/${row.id}?from=me');
                            }
                          },
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

String _accountName(DeviceSettings settings, Copy t) {
  if (settings.accountProvider == 'guest') return t.loginMethod('guest');
  final email = settings.accountEmail;
  final name = settings.accountName;
  if (email != null && email.isNotEmpty) return email;
  if (name != null && name.isNotEmpty) return name;
  return t.loginMethod(settings.accountProvider);
}

/// Deletes the parent account after a confirm step and the parent code.
Future<void> closeParentAccount(
  BuildContext context,
  AppController app,
  DeviceSettings settings,
) async {
  final t = Copy.of(context);
  final provider = settings.accountProvider;
  final leave = await showConfirm(
    context,
    title: t.closeAccount,
    body: t.deleteAccountBody,
    confirm: t.closeAccount,
    cancel: t.cancel,
    destructive: true,
  );
  if (!leave || !context.mounted) return;
  final ok = await requireParentCode(
    context,
    app,
    title: t.parentCode,
    body: t.deleteAccountCode,
    action: (pin, again) => app.deleteAccount(pin, again: again),
  );
  if (ok) {
    await endProviderSession(provider, revoke: true);
  }
  if (ok && context.mounted) context.go('/sign-in');
}

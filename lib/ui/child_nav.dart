import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../l10n/copy.dart';
import '../pages/extra_pages.dart';
import '../pages/home_pages.dart';
import '../pages/learn_pages.dart';

const tabsPageKey = ValueKey<String>('main-tabs');

class MainTabs extends StatefulWidget {
  const MainTabs({
    super.key,
    required this.index,
    this.trickId,
    this.learnerId,
    this.reportLearnerId,
  });

  final int index;
  final String? trickId;
  final String? learnerId;
  final String? reportLearnerId;

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  final _visited = <int>{};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
  }

  @override
  void didUpdateWidget(MainTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: widget.index,
        sizing: StackFit.expand,
        children: [
          _visited.contains(0) ? const ChildHomePage() : const SizedBox.shrink(),
          _visited.contains(1) ? _practice() : const SizedBox.shrink(),
          _visited.contains(2) ? _report() : const SizedBox.shrink(),
          _visited.contains(3)
              ? const SettingsPage(child: true)
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: ChildNavBar(index: widget.index),
    );
  }

  Widget _practice() {
    return Stack(
      fit: StackFit.expand,
      children: [
        TricksPage(learnerId: widget.learnerId),
        if (widget.trickId != null)
          TrickDetailPage(
            key: ValueKey(widget.trickId),
            id: widget.trickId!,
            learnerId: widget.learnerId,
          ),
      ],
    );
  }

  Widget _report() {
    final id = widget.reportLearnerId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();
    return ReportPage(key: ValueKey(id), learnerId: id);
  }
}

class ChildNavBar extends ConsumerWidget {
  const ChildNavBar({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learnerId = ref.watch(appProvider).activeLearnerId;
    final t = Copy.of(context);
    final colors = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: index,
      height: 64,
      backgroundColor: colors.surface,
      elevation: 3,
      shadowColor: colors.shadow,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (value) {
        switch (value) {
          case 0:
            context.go('/child');
          case 1:
            context.go('/tricks');
          case 2:
            if (learnerId != null) context.go('/report/$learnerId');
          case 3:
            context.go('/prefs');
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: t.home,
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          label: t.practice,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart),
          label: t.report,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: t.me,
        ),
      ],
    );
  }
}

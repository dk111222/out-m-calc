import 'package:go_router/go_router.dart';

import '../pages/extra_pages.dart';
import '../pages/scan_page.dart';
import '../pages/home_pages.dart';
import '../pages/learn_pages.dart';
import '../pages/speed_pages.dart';
import '../ui/child_nav.dart';
import 'session.dart';

NoTransitionPage<void> _tabs({
  required int index,
  String? trickId,
  String? learnerId,
  String? reportLearnerId,
}) {
  return NoTransitionPage<void>(
    key: tabsPageKey,
    child: MainTabs(
      index: index,
      trickId: trickId,
      learnerId: learnerId,
      reportLearnerId: reportLearnerId,
    ),
  );
}

GoRouter buildRouter(AppController app) {
  return GoRouter(
    initialLocation: app.openLocation(),
    refreshListenable: app,
    redirect: (context, state) => app.redirect(state.uri.path),
    routes: [
      GoRoute(path: '/loading', builder: (_, _) => const LoadingPage()),
      GoRoute(path: '/start', builder: (_, _) => const StartPage()),
      GoRoute(
        path: '/learner/new',
        builder: (_, state) => LearnerFormPage(
          guest: state.uri.queryParameters['guest'] == '1',
        ),
      ),
      GoRoute(path: '/adult', builder: (_, _) => const AdultHomePage()),
      GoRoute(
        path: '/assign/:learnerId',
        builder: (_, state) =>
            AssignPage(learnerId: state.pathParameters['learnerId']!),
      ),
      GoRoute(
        path: '/child',
        pageBuilder: (_, _) => _tabs(index: 0),
      ),
      GoRoute(
        path: '/tricks',
        pageBuilder: (_, state) => _tabs(
          index: 1,
          learnerId: state.uri.queryParameters['learner'],
        ),
      ),
      GoRoute(
        path: '/tricks/:id',
        pageBuilder: (_, state) => _tabs(
          index: 1,
          trickId: state.pathParameters['id'],
          learnerId: state.uri.queryParameters['learner'],
        ),
      ),
      GoRoute(
        path: '/report/:learnerId',
        pageBuilder: (_, state) => _tabs(
          index: 2,
          reportLearnerId: state.pathParameters['learnerId'],
        ),
      ),
      GoRoute(
        path: '/prefs',
        pageBuilder: (_, _) => _tabs(index: 3),
      ),
      GoRoute(
        path: '/practice/:id/done',
        builder: (_, _) => const DonePage(),
      ),
      GoRoute(
        path: '/practice/:id/:phase',
        builder: (_, _) => const PracticePage(),
      ),
      GoRoute(path: '/speed/setup', builder: (_, _) => const SpeedSetupPage()),
      GoRoute(path: '/speed/run', builder: (_, _) => const SpeedRunPage()),
      GoRoute(path: '/speed/done', builder: (_, _) => const SpeedDonePage()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewPage()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanPage()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/settings/privacy',
        builder: (_, _) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/export/worksheet',
        builder: (_, state) => WorksheetPage(
          trickId: state.uri.queryParameters['trickId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/export/certificate',
        builder: (_, state) => CertificatePage(
          learnerId: state.uri.queryParameters['learner'] ?? '',
          id: state.uri.queryParameters['id'] ?? '',
        ),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/session.dart';
import 'app/theme.dart';
import 'data/device_paths.dart';
import 'data/hive_store.dart';
import 'domain/catalog.dart';
import 'l10n/copy.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return buildRouter(ref.read(appProvider));
});

const launchBackground = Color(0xFFF4F1EA);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DevicePaths.install();
  runApp(const BootApp());
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  Widget? _child;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      final store = HiveAppStore();
      final catalogText = rootBundle.loadString('assets/tricks/catalog.json');
      final ready = await Future.wait([store.init(), catalogText]);
      final catalog = Catalog.parse(ready[1] as String);
      final app = AppController(store: store, catalog: catalog);
      if (!mounted) return;
      setState(() {
        _child = ProviderScope(
          overrides: [
            storeProvider.overrideWithValue(store),
            appProvider.overrideWith((ref) => app),
          ],
          child: const StepMathApp(),
        );
      });
      await app.boot();
    } catch (error, stack) {
      debugPrint('$error\n$stack');
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return StartupFailed(message: '$_error');
    return _child ?? const ColoredBox(color: launchBackground);
  }
}

class StartupFailed extends StatelessWidget {
  const StartupFailed({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StepMath 打不开。',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StepMathApp extends ConsumerWidget {
  const StepMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appProvider);
    final router = ref.watch(routerProvider);
    final mode = switch (app.settings.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: false,
      builder: (context, child) {
        final code = app.settings.language == 'en' ? 'en' : 'zh';
        return MaterialApp.router(
          title: 'StepMath',
          debugShowCheckedModeBanner: false,
          locale: Locale(code),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            CopyDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          routerConfig: router,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final product =
                (media.textScaler.scale(1) * app.settings.textScaleFactor)
                    .clamp(0.85, 1.3);
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(product)),
              child: RepaintBoundary(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/session.dart';
import 'app/theme.dart';
import 'data/hive_store.dart';
import 'domain/catalog.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return buildRouter(ref.read(appProvider));
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = HiveAppStore();
  await store.init();
  final catalog = Catalog.parse(
    await rootBundle.loadString('assets/tricks/catalog.json'),
  );
  final app = AppController(store: store, catalog: catalog);
  await app.boot();
  runApp(
    ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        appProvider.overrideWith((ref) => app),
      ],
      child: const StepMathApp(),
    ),
  );
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
        return MaterialApp.router(
          title: 'StepMath',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          routerConfig: router,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final product = (media.textScaler.scale(1) * app.settings.textScaleFactor)
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

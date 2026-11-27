import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stepmath/app/providers.dart';
import 'package:stepmath/app/session.dart';
import 'package:stepmath/data/hive_store.dart';
import 'package:stepmath/domain/catalog.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/main.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture clone screens at phone width', (tester) async {
    final font = File('assets/fonts/SourceSans3-Regular.ttf').readAsBytesSync();
    final loader = FontLoader('Source Sans 3')
      ..addFont(Future.value(ByteData.sublistView(font)));
    await loader.load();
    final directory = await Directory.systemTemp.createTemp('stepmath-ui');
    final store = HiveAppStore();
    await store.init(path: directory.path);
    final catalog = Catalog.parse(
      File('assets/tricks/catalog.json').readAsStringSync(),
    );
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storeProvider.overrideWithValue(store),
          appProvider.overrideWith((ref) => app),
        ],
        child: const StepMathApp(),
      ),
    );
    await _settle(tester);
    await _shoot(tester, 'P01');

    await tester.tap(find.text('Play as Guest'));
    await _settle(tester);
    await tester.tap(find.text('我的'));
    await _settle(tester);
    await tester.tap(find.text('添加孩子'));
    await _settle(tester);
    await _shoot(tester, 'P02');

    await tester.enterText(find.byType(TextField), 'Ava ${'North' * 11}');
    await tester.tap(find.text('一年级'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await _settle(tester);
    await _shoot(tester, 'P03');

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await _settle(tester);
    await _shoot(tester, 'P03-wide');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await _settle(tester);

    final learnerId = app.learners.single.id;
    await _go(tester, '/settings');
    await _shoot(tester, 'P16');
    await tester.tap(find.text('深色'));
    await _settle(tester);
    await _shoot(tester, 'P16-dark');
    await tester.scrollUntilVisible(
      find.text('隐私政策'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('隐私政策'));
    await _settle(tester);
    await _shoot(tester, 'privacy');
    await app.updateSettings(app.settings.copyWith(themeMode: 'light'));
    await _settle(tester);

    await _go(tester, '/report/$learnerId');
    await _shoot(tester, 'report');
    await _go(tester, '/tricks?learner=$learnerId');
    await _shoot(tester, 'P06');
    await tester.tap(find.text('凑十法'));
    await _settle(tester);
    await _shoot(tester, 'P07');
    await tester.scrollUntilVisible(
      find.text('开始练习'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始练习'));
    await _settle(tester);
    await _shoot(tester, 'P08');

    await _go(tester, '/speed/setup');
    await _shoot(tester, 'P12');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    await container.read(speedProvider).start(speedDefault('1'));
    await _go(tester, '/speed/run');
    await _shoot(tester, 'P13');
    await tester.tap(find.byTooltip('暂停'));
    await _settle(tester);
    await _shoot(tester, 'P13-pause');

    expect(
      await app.createAccount(
        email: 'parent@example.com',
        password: 'password1',
        again: 'password1',
      ),
      isNull,
    );
    expect(await app.subscribe(), isNull);
    await _go(tester, '/review');
    await _shoot(tester, 'P15');
    await _go(tester, '/export/worksheet?trickId=g1-make-10');
    await _shoot(tester, 'worksheet');
    await app.enterChild(learnerId);
    await _go(tester, '/child');
    await _shoot(tester, 'P05');
    await _go(tester, '/prefs');
    await _shoot(tester, 'prefs');
    await _go(tester, '/practice/g1-make-10/done');
    await _shoot(tester, 'P11');
    await _go(tester, '/speed/done');
    await _shoot(tester, 'P14');
  });
}

Future<void> _go(WidgetTester tester, String location) async {
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(location);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _shoot(WidgetTester tester, String name) async {
  Object? error;
  while ((error = tester.takeException()) != null) {
    fail('$name threw $error');
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('replica/clone-screens/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

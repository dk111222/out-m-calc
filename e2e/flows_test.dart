import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stepmath/app/providers.dart';
import 'package:stepmath/app/session.dart';
import 'package:stepmath/data/hive_store.dart';
import 'package:stepmath/domain/catalog.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/domain/engine.dart';
import 'package:stepmath/domain/machines.dart';
import 'package:stepmath/export/pdfs.dart';
import 'package:stepmath/main.dart';
import 'package:stepmath/pages/home_pages.dart';
import 'package:stepmath/ui/avatars.dart';
import 'package:stepmath/ui/kit.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late HiveAppStore store;
  late Catalog catalog;
  final errors = <FlutterErrorDetails>[];

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('stepmath-e2e');
    store = HiveAppStore();
    await store.init(path: directory.path);
    catalog = Catalog.parse(
      File('assets/tricks/catalog.json').readAsStringSync(),
    );
    FlutterError.onError = (details) {
      errors.add(details);
      FlutterError.presentError(details);
    };
  });

  tearDown(() {
    final copy = [...errors];
    errors.clear();
    expect(copy, isEmpty);
  });

  tearDownAll(() async {
    await store.close();
    await directory.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> signInOnMe(WidgetTester tester) async {
    if (find.text('Play as Guest').evaluate().isNotEmpty) {
      await tester.tap(find.text('Play as Guest'));
      await settle(tester);
    }
    await tester.tap(find.text('我的'));
    await settle(tester);
  }

  Future<AppController> boot() async {
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    await app.updateSettings(
      app.settings.copyWith(soundEnabled: false, readAloudEnabled: false),
    );
    return app;
  }

  Future<void> show(WidgetTester tester, AppController app) async {
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
    await tester.pump();
    // A signed-out open is the login page. A signed-in open is home.
    // Neither wait is the loading page.
    expect(find.byType(LoadingPage), findsNothing);
    expect(find.textContaining('正在这台设备上打开练习'), findsNothing);
    await settle(tester);
  }

  testWidgets('F01-H1 assign 凑十法 and answer the first step', (tester) async {
    final app = await boot();
    await show(tester, app);
    await signInOnMe(tester);
    await tester.tap(find.text('添加孩子'));
    await settle(tester);
    // Kid + animal rows both mount (horizontal strips, 12 each).
    expect(find.text('孩子'), findsWidgets);
    expect(find.text('动物'), findsOneWidget);
    expect(find.byType(ChildAvatar), findsNWidgets(24));
    expect(find.byType(Image), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Ava');
    await tester.tap(find.text('一年级'));
    await tester.pump();
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await settle(tester);
    expect(find.text('布置'), findsNothing);

    await tester.tap(find.text('Ava').first);
    await settle(tester);
    expect(find.text('首页'), findsOneWidget);
    await tester.tap(find.text('速算技巧'));
    await settle(tester);
    await tester.tap(find.text('凑十法'));
    await settle(tester);
    expect(find.textContaining('何时用'), findsOneWidget);
    expect(find.textContaining('别用'), findsOneWidget);
    expect(find.textContaining('怎么算'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('开始练习'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始练习'));
    await settle(tester);
    expect(find.text('提交'), findsOneWidget);
    expect(find.byType(AnswerReadout), findsOneWidget);
    expect(
      tester.widget<AnswerReadout>(find.byType(AnswerReadout)).value,
      isEmpty,
    );
    expect(find.text('删除'), findsOneWidget);

    final practice = ProviderScope.containerOf(
      tester.element(find.text('提交')),
    ).read(practiceProvider);
    final answer = practice.view!.current!.steps.first.answer;
    for (final digit in answer.split('')) {
      await tester.tap(
        find.descendant(of: find.byType(Keypad), matching: find.text(digit)),
      );
      await tester.pump();
    }
    await tester.tap(find.text('提交'));
    await tester.tap(find.text('提交'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(practice.view!.stepIndex, 1);
    expect(find.textContaining('第 2 步'), findsOneWidget);

    await tester.tap(find.text('提交'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(practice.view!.stepIndex, 1);
    await tester.tap(
      find.descendant(of: find.byType(Keypad), matching: find.text('9')),
    );
    await tester.pump();
    await tester.tap(find.text('提交'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('还不对'), findsOneWidget);
    expect(practice.view!.stepIndex, 1);
  });

  testWidgets('F01-E3 a signed-out me page cannot add a learner', (
    tester,
  ) async {
    final app = await boot();
    await show(tester, app);
    expect(find.text('Play as Guest'), findsOneWidget);
    expect(find.text('首页'), findsNothing);
    await tester.tap(find.text('Play as Guest'));
    await settle(tester);
    await tester.tap(find.text('我的'));
    await settle(tester);
    expect(find.text('本地游客'), findsNothing);
    expect(find.text('游客'), findsNWidgets(2));
    expect(find.text('孩子管理'), findsOneWidget);
    expect(find.text('添加孩子'), findsOneWidget);
    expect(find.text('查看报告'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    await tester.tap(find.text('添加孩子'));
    await tester.pump(const Duration(milliseconds: 300));
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(save.onPressed, isNull);
    await tester.tap(find.text('一年级'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('保存'));
    await settle(tester);
    expect(find.text('学员'), findsWidgets);
  });

  testWidgets('F01-E2 a long accented name is kept and shown', (tester) async {
    final app = await boot();
    await show(tester, app);
    await signInOnMe(tester);
    await tester.tap(find.text('添加孩子'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Léa 数学🎒');
    await tester.tap(find.text('幼儿园'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await settle(tester);
    expect(find.text('Léa 数学🎒'), findsWidgets);
  });

  testWidgets('F01-N1 a child cannot open settings or wipe', (tester) async {
    final app = await boot();
    await app.signInAsGuest();
    await app.createLearner(name: 'Ava', grade: '1');
    await app.enterChild(app.learners.single.id);
    await show(tester, app);
    GoRouter.of(tester.element(find.text('首页'))).go('/settings');
    await settle(tester);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('删除这台设备上的全部数据'), findsNothing);
    expect(await app.wipeAll('1234', again: '1234'), isFalse);
  });

  testWidgets('F03-H1 pause hides the speed problem', (tester) async {
    final app = await boot();
    await app.signInAsGuest();
    await app.createLearner(name: 'Ava', grade: '3');
    await app.enterChild(app.learners.single.id);
    await show(tester, app);
    final speed = ProviderScope.containerOf(
      tester.element(find.text('首页')),
    ).read(speedProvider);
    await speed.start(speedDefault('3'));
    GoRouter.of(tester.element(find.text('首页'))).go('/speed/run');
    await settle(tester);
    expect(find.text('总用时'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    final shown = clockLabel(speed.view!.elapsedMs);
    expect(shown, isNot('00:00'));
    expect(find.text(shown), findsOneWidget);
    final prompt = speed.view!.current!.prompt;
    expect(find.text(prompt), findsOneWidget);
    await tester.tap(find.byTooltip('暂停'));
    await settle(tester);
    expect(find.text('计时已暂停。同一道题还在。'), findsOneWidget);
    expect(find.text(prompt), findsNothing);
    await speed.leave();
  });

  testWidgets('F03-H1b a second daily round keeps counting', (tester) async {
    final app = await boot();
    await app.createLearner(name: 'Ava', grade: '1');
    await app.enterChild(app.learners.single.id);
    final speed = SpeedController(app);
    addTearDown(speed.dispose);
    final config = dailyPractice('1').copyWith(limitValue: 1);
    await speed.start(config);
    final answer = speed.view!.current!.finalAnswer;
    for (final digit in answer.split('')) {
      if (RegExp(r'^\d$').hasMatch(digit) || digit == '.') speed.key(digit);
    }
    await speed.submit();
    expect(speed.view!.done, isTrue);
    await speed.start(config);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(clockLabel(speed.view!.elapsedMs), isNot('00:00'));
  });

  testWidgets('F03-H2 the training report opens on the speed drill', (
    tester,
  ) async {
    final app = await boot();
    await app.signInAsGuest();
    await app.createLearner(name: 'Ava', grade: '3');
    await app.enterChild(app.learners.single.id);
    await show(tester, app);
    final speed = ProviderScope.containerOf(
      tester.element(find.text('首页')),
    ).read(speedProvider);
    await speed.start(
      speedDefault('3').copyWith(limitMode: 'count', limitValue: 1),
    );
    GoRouter.of(tester.element(find.text('首页'))).go('/speed/run');
    await settle(tester);
    final answer = speed.view!.current!.finalAnswer;
    for (final digit in answer.split('')) {
      if (!RegExp(r'^\d$').hasMatch(digit)) continue;
      await tester.tap(
        find.descendant(of: find.byType(Keypad), matching: find.text(digit)),
      );
      await tester.pump();
    }
    await tester.tap(find.text('提交'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('训练报告'), findsOneWidget);
    expect(find.textContaining('正确 1 题'), findsOneWidget);
    expect(find.textContaining('错误 0 题'), findsOneWidget);
    await tester.tap(find.text('返回首页'));
    await settle(tester);
    expect(find.text('首页'), findsOneWidget);
  });

  testWidgets('F05-H1 a repaired miss leaves the open queue', (tester) async {
    final app = await boot();
    expect(
      await app.createAccount(
        email: 'parent@example.com',
        password: 'password1',
        again: 'password1',
      ),
      isNull,
    );
    expect(await app.subscribe(), isNull);
    await app.createLearner(name: 'Ava', grade: '1');
    await app.createLearner(name: 'Ben', grade: '2');
    final ava = app.learners.firstWhere(
      (learner) => learner.displayName == 'Ava',
    );
    final ben = app.learners.firstWhere(
      (learner) => learner.displayName == 'Ben',
    );
    await app.enterChild(ava.id);
    final sample = makeTen(8, 7);
    await app.recordAttempt(
      AttemptDraft(
        trickId: sample.trickId,
        prompt: sample.prompt,
        userAnswer: '14',
        correctAnswer: sample.finalAnswer,
        correct: false,
        failedStep: 3,
        mode: 'final',
        steps: sample.steps,
        reviewSlot: null,
        repairWrongId: null,
      ),
    );
    store.setSession(childMode: false, learnerId: null);
    await app.enterChild(ben.id);
    await app.recordAttempt(
      AttemptDraft(
        trickId: sample.trickId,
        prompt: '9 + 6',
        userAnswer: '14',
        correctAnswer: '15',
        correct: false,
        failedStep: 1,
        mode: 'final',
        steps: makeTen(9, 6).steps,
        reviewSlot: null,
        repairWrongId: null,
      ),
    );
    await app.enterChild(ava.id);
    expect(() => store.wrongs(ben.id), throwsStateError);
    await show(tester, app);
    GoRouter.of(tester.element(find.text('首页'))).go('/review');
    await settle(tester);
    expect(find.widgetWithText(ListTile, '8 + 7'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListTile), matching: find.text('9 + 6')),
      findsNothing,
    );

    final practice = ProviderScope.containerOf(
      tester.element(find.widgetWithText(ListTile, '8 + 7')),
    ).read(practiceProvider);
    final open = await store.wrongs(ava.id);
    await practice.startRepair(open.single);
    for (var guard = 0; guard < 8 && practice.view?.phase != 'done'; guard++) {
      final view = practice.view!;
      final step = view.current!.steps[view.stepIndex];
      for (final digit in step.answer.split('')) {
        practice.key(digit);
      }
      await practice.submit();
      await tester.pump(const Duration(milliseconds: 150));
    }
    store.setSession(childMode: false, learnerId: null);
    final left = await store.wrongs(ava.id);
    expect(left.where((item) => !item.reviewedOk), isEmpty);
    expect(left, isNotEmpty);
  });

  testWidgets('F06-H1 two players is not on the device', (tester) async {
    final app = await boot();
    await show(tester, app);
    expect(find.text('Two players'), findsNothing);
    expect(find.textContaining('500'), findsNothing);
  });

  testWidgets('C06-H1 continue restores the same problem after a restart', (
    tester,
  ) async {
    final app = await boot();
    await app.signInAsGuest();
    await app.createLearner(name: 'Ava', grade: '1');
    await app.enterChild(app.learners.single.id);
    await show(tester, app);
    final practice = ProviderScope.containerOf(
      tester.element(find.text('首页')),
    ).read(practiceProvider);
    await practice.startLearn('g1-make-10');
    final prompt = practice.view!.current!.prompt;
    final restarted = AppController(store: store, catalog: catalog);
    await restarted.boot();
    await restarted.enterChild(app.learners.single.id);
    expect(restarted.snapshot, isNotNull);
    final restored = PracticeController(restarted);
    await restored.resume(restarted.snapshot!);
    expect(restored.view!.current!.prompt, prompt);
  });

  test('C06-E1 a snapshot from yesterday is dropped on boot', () async {
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    await app.createLearner(name: 'Ava', grade: '1');
    final id = app.learners.single.id;
    final yesterday = formatYmd(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    await store.saveSnapshot(
      SessionSnapshot(
        learnerId: id,
        module: 'learn',
        trickId: 'g1-make-10',
        localDate: yesterday,
        payload: '{}',
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    final restarted = AppController(store: store, catalog: catalog);
    await restarted.boot();
    expect(await store.snapshot(id), isNull);
  });

  test('C-pin four wrong codes lock the gate', () async {
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    final clock = FixedClock(DateTime(2026, 11, 19, 9));
    final app = AppController(store: store, catalog: catalog, clock: clock);
    await app.boot();
    expect(await app.submitPin('1234', again: '1234'), isTrue);
    for (var i = 0; i < 3; i++) {
      expect(await app.submitPin('0000'), isFalse);
    }
    expect(await app.submitPin('0000'), isFalse);
    expect(app.settings.pinLockedUntil, isNotNull);
    expect(await app.submitPin('1234'), isFalse);
    clock.current = clock.current.add(const Duration(seconds: 61));
    expect(await app.submitPin('1234'), isTrue);
  });

  test(
    'F01-E1 a blank name becomes Learner and stops at 60 characters',
    () async {
      store.setSession(childMode: false, learnerId: null);
      await store.wipe();
      final app = AppController(store: store, catalog: catalog);
      await app.boot();
      expect(await app.createLearner(name: '   ', grade: '1'), isNull);
      expect(app.learners.single.displayName, '学员');
      expect(await app.createLearner(name: '', grade: '2'), isNull);
      expect(app.learners.last.displayName, '学员 2');
      final long = '北' * 80;
      expect(await app.createLearner(name: long, grade: '3'), isNull);
      expect(app.learners.last.displayName.length, 60);
    },
  );

  test('F03-E2 personal best does not leak to the other child', () async {
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    await app.createLearner(name: 'Ava', grade: '3');
    await app.createLearner(name: 'Ben', grade: '3');
    final ava = app.learners.first.id;
    final config = speedDefault('3');
    await store.saveSpeed(
      SpeedRound(
        id: 'round-ava',
        learnerId: ava,
        operation: config.operation,
        digitMin: config.digitMin,
        digitMax: config.digitMax,
        limitMode: config.limitMode,
        limitValue: config.limitValue,
        correctCount: 12,
        durationMs: 180000,
        createdAt: DateTime.utc(2026, 11, 19),
      ),
    );
    expect(await app.bestFor(ava, config), 12);
    expect(await app.bestFor(app.learners.last.id, config), 0);
  });

  test('F05-H1 worksheet is one trick and 20 problems', () async {
    final trick = catalog.byId('g1-make-10')!;
    final problems = List.generate(20, (index) => makeTen(8, 7));
    final font = File('assets/fonts/SourceSans3-Regular.ttf').readAsBytesSync();
    final bytes = await buildWorksheet(
      trick: trick,
      problems: problems,
      regular: ByteData.sublistView(font),
      bold: ByteData.sublistView(font),
    );
    expect(bytes.length, greaterThan(500));
    expect(
      () => buildWorksheet(
        trick: trick,
        problems: problems.take(19).toList(),
        regular: ByteData.sublistView(font),
        bold: ByteData.sublistView(font),
      ),
      throwsArgumentError,
    );
  });

  test('F02-H1 a percent answer keeps one decimal', () {
    final problem = percentOf(1, 80);
    expect(problem.steps.last.answer, '0.8');
    expect(sameNumber('0.80', problem.finalAnswer), isTrue);
    expect(jsonDecode(jsonEncode(problem.toJson())), isA<Map>());
  });
}

class FixedClock extends AppClock {
  FixedClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

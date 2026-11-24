import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/app/theme.dart';
import 'package:stepmath/ui/kit.dart';
import 'package:stepmath/data/hive_store.dart';
import 'package:stepmath/domain/catalog.dart';
import 'package:stepmath/domain/scan.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/domain/engine.dart';
import 'package:stepmath/domain/machines.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wrong-problem practice needs a signed-in subscription', () {
    expect(accountEmailError('parent@example.com'), isNull);
    expect(accountEmailError('parent'), 'Enter an email address.');
    expect(newPasswordError('short', 'short'), 'Use at least 8 characters.');
    expect(
      newPasswordError('password1', 'password2'),
      'Those passwords do not match.',
    );
    expect(newPasswordError('password1', 'password1'), isNull);
    expect(errorTrainingAllowed(signedIn: true, subscribed: true), isTrue);
    expect(errorTrainingAllowed(signedIn: true, subscribed: false), isFalse);
    expect(errorTrainingAllowed(signedIn: false, subscribed: true), isFalse);
  });

  test('fixed tricks match the worked examples', () {
    expect(makeTen(8, 7).steps.map((step) => step.answer), ['2', '5', '15']);
    expect(makeTen(8, 7).finalAnswer, '15');
    expect(nearHundredAdd(97, 96).finalAnswer, '193');
    expect(nearHundredSub(150, 97).finalAnswer, '53');
    expect(timesFive(48).finalAnswer, '240');
    expect(timesEleven(35).finalAnswer, '385');
    expect(timesElevenCarry(48).finalAnswer, '528');
    expect(complements(2, 6, 4).finalAnswer, '624');
    expect(squareEndsFive(4).finalAnswer, '2025');
    expect(divideByFive(48).finalAnswer, '9.6');
    expect(percentOf(10, 80).finalAnswer, '8');
    expect(percentOf(1, 80).finalAnswer, '0.8');
  });

  test('6.3 and 6.30 are the same answer', () {
    expect(sameNumber('6.3', '6.30'), isTrue);
    expect(sameNumber('8', '8.00'), isTrue);
    expect(sameNumber('', '8'), isFalse);
    expect(sameNumber('6.33', '6.3'), isFalse);
  });

  test('keypad rejects a second dot, a sign, and a ninth character', () {
    expect(applyKey('1', '.'), '1.');
    expect(applyKey('1.2', '.'), isNull);
    expect(applyKey('1', '-'), isNull);
    expect(applyKey('1', 'a'), isNull);
    expect(applyKey('12345678', '9'), isNull);
    expect(applyKey('12345678', 'delete'), '1234567');
    expect(applyKey('', '.'), '0.');
  });

  test('mastery needs 20 finals at 90 percent', () {
    final almost = scoreFinals(
      List.filled(18, true),
      latestCorrect: true,
      previousConsecutive: 18,
    );
    expect(almost.window, 19);
    expect(almost.mastered, isFalse);
    final low = scoreFinals(
      [...List.filled(16, true), false, false, false],
      latestCorrect: false,
      previousConsecutive: 0,
    );
    expect(low.window, 20);
    expect(low.correctInWindow, 16);
    expect(low.mastered, isFalse);
    final ready = scoreFinals(
      [...List.filled(17, true), false, true],
      latestCorrect: true,
      previousConsecutive: 1,
    );
    expect(ready.correctInWindow, 19);
    expect(ready.mastered, isTrue);
    final reset = scoreFinals(
      List.filled(19, true),
      latestCorrect: false,
      previousConsecutive: 19,
    );
    expect(reset.consecutive, 0);
  });

  test('a calendar gap stays on dates when the clock springs or falls', () {
    expect(dayGap('2026-03-07', '2026-03-09'), 2);
    expect(addDays('2026-03-08', 1), '2026-03-09');
    expect(addDays('2026-03-07', 2), '2026-03-09');
    expect(addDays('2026-11-01', 1), '2026-11-02');
  });

  test('a local day counts once and one skip covers a single miss', () {
    final first = completeStreak(
      count: 0,
      lastDate: null,
      skipWeek: null,
      skipUsed: false,
      today: '2026-11-19',
      thisWeek: '2026-11-16',
    );
    expect(first.count, 1);
    final again = completeStreak(
      count: first.count,
      lastDate: first.lastDate,
      skipWeek: first.skipWeek,
      skipUsed: first.skipUsed,
      today: '2026-11-19',
      thisWeek: '2026-11-16',
    );
    expect(again.changed, isFalse);
    final held = rollStreak(
      count: 4,
      lastDate: '2026-11-17',
      skipWeek: '2026-11-16',
      skipUsed: false,
      notice: null,
      today: '2026-11-19',
      thisWeek: '2026-11-16',
    );
    expect(held.count, 4);
    expect(held.skipUsed, isTrue);
    expect(held.lastDate, '2026-11-18');
    final reset = rollStreak(
      count: 4,
      lastDate: '2026-11-16',
      skipWeek: '2026-11-16',
      skipUsed: true,
      notice: null,
      today: '2026-11-19',
      thisWeek: '2026-11-16',
    );
    expect(reset.count, 0);
  });

  test('grade speed defaults', () {
    expect(canonicalGrade('basic'), '1');
    expect(canonicalGrade('middle'), '3');
    expect(canonicalGrade('advanced'), '5');
    expect(speedDefault('K').limitMode, 'count');
    expect(speedDefault('K').limitValue, 10);
    expect(speedDefault('1').digitMax, 2);
    expect(speedDefault('2').digitMin, 2);
    expect(speedDefault('3').digitMax, 1);
    expect(speedDefault('4').digitMax, 2);
    expect(speedDefault('5').operation, 'mixed');
    for (final grade in grades) {
      expect(speedDefault(grade).operation, 'mixed');
      final config = dailyPractice(grade);
      final items = buildSpeedQueue(config, grade, Random(1));
      expect(items, hasLength(10));
      expect(items.map((item) => item.prompt).toSet().length, greaterThan(1));
      expect(isDailyPractice(config, grade), isTrue);
    }
  });

  test('wrong final opens the step check and a second submit is ignored', () {
    final item = makeTen(8, 7).copyWith(guided: false);
    var view = PracticeView.start(
      learnerId: 'learner',
      trickId: item.trickId,
      items: [item],
    );
    expect(view.phase, 'final');
    view = practiceKey(view, '1').view;
    view = practiceKey(view, '4').view;
    final missed = practiceSubmit(view);
    expect(missed.view.phase, 'locate');
    expect(missed.view.shownWrongFinal, '14');
    expect(missed.attempt, isNull);
    final locked = missed.view.copy(locked: true);
    final ignored = practiceSubmit(locked);
    expect(ignored.view.phase, 'locate');
    expect(ignored.attempt, isNull);
  });

  test('a correct step waits, then moves, and the attempt is recorded once', () {
    final item = makeTen(8, 7).copyWith(guided: true);
    var view = PracticeView.start(
      learnerId: 'learner',
      trickId: item.trickId,
      items: [item],
    );
    view = practiceKey(view, '2').view;
    final effect = practiceSubmit(view);
    expect(effect.wait, isTrue);
    expect(effect.attempt, isNull);
    final advanced = practiceAdvance(effect.view);
    expect(advanced.view.stepIndex, 1);
    expect(advanced.view.previousPrompt, isNull);
    expect(correctAdvance.inMilliseconds, lessThan(100));
  });

  testWidgets('a long percent prompt stays complete on one line', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 358,
              child: EquationLine(prompt: r'10% of $180', value: ''),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(r'10% of $180'), findsOneWidget);
    expect(find.text('('), findsOneWidget);
    expect(find.text(')'), findsOneWidget);
  });

  testWidgets('the current and next problems stay on screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: DrillBoard(
            title: '速算训练',
            onBack: () {},
            prompt: '8 + 7',
            value: '',
            onKey: (_) {},
            onSubmit: () {},
            previousPrompt: '6 + 6',
            previousAnswer: '12',
            previousCorrect: true,
            nextPrompt: '9 + 8',
            detail: const SizedBox(height: 800, child: Text('步骤很长')),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final current = tester.getRect(find.text('8 + 7'));
    final next = tester.getRect(find.textContaining('9 + 8'));
    expect(current.top, greaterThanOrEqualTo(0));
    expect(next.top, greaterThan(current.top));
    expect(next.bottom, lessThan(640));
    final zero = tester.getCenter(
      find.descendant(of: find.byType(Keypad), matching: find.text('0')),
    );
    final delete = tester.getCenter(find.text('删除'));
    expect(delete.dx, greaterThan(zero.dx));
    expect((delete.dy - zero.dy).abs(), lessThan(24));
    expect(find.text('回退'), findsNothing);
    final submit = tester.getRect(find.widgetWithText(FilledButton, '提交'));
    final keypad = tester.getRect(find.byType(Keypad));
    expect(submit.width, 358);
    expect(submit.left, keypad.left);
    expect(submit.right, keypad.right);
  });

  testWidgets('the first problem already reserves the previous line', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<void> show({String? previous}) {
      return tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: DrillBoard(
              title: '每日一练',
              onBack: () {},
              prompt: '8 + 7',
              value: '',
              onKey: (_) {},
              onSubmit: () {},
              previousPrompt: previous,
              previousAnswer: previous == null ? null : '12',
              previousCorrect: previous == null ? null : true,
              nextPrompt: '9 + 8',
            ),
          ),
        ),
      );
    }

    await show();
    expect(find.textContaining('6 + 6'), findsNothing);
    final current = tester.getRect(find.text('8 + 7')).top;
    final next = tester.getRect(find.textContaining('9 + 8')).top;
    final submit = tester.getRect(find.widgetWithText(FilledButton, '提交')).top;
    await show(previous: '6 + 6');
    expect(find.textContaining('6 + 6'), findsOneWidget);
    expect(tester.getRect(find.text('8 + 7')).top, current);
    expect(tester.getRect(find.textContaining('9 + 8')).top, next);
    expect(
      tester.getRect(find.widgetWithText(FilledButton, '提交')).top,
      submit,
    );
    expect(tester.takeException(), isNull);
  });

  test('the next problem keeps the previous result and its mark', () {
    final first = makeTen(8, 7).copyWith(guided: false);
    final second = makeTen(9, 8).copyWith(guided: false);
    var view = PracticeView.start(
      learnerId: 'learner',
      trickId: first.trickId,
      items: [first, second],
    );
    for (final digit in first.finalAnswer.split('')) {
      view = practiceKey(view, digit).view;
    }
    final submitted = practiceSubmit(view);
    final advanced = practiceAdvance(submitted.view);
    expect(advanced.view.index, 1);
    expect(advanced.view.previousPrompt, first.prompt);
    expect(advanced.view.previousAnswer, first.finalAnswer);
    expect(advanced.view.previousCorrect, isTrue);
    expect(advanced.view.current?.prompt, second.prompt);
  });

  test('a wrong speed answer waits for the report before the wrong book', () {
    final item = makeTen(8, 7).copyWith(guided: false);
    final started = SpeedView.start(
      learnerId: 'learner',
      grade: '1',
      config: speedDefault('1'),
      items: [item],
      previousBest: 0,
    );
    final keyed = speedKey(started, '1').view;
    final effect = speedSubmit(keyed);
    expect(effect.attempt!.bookWrong, isFalse);
    expect(effect.view.misses, hasLength(1));
    expect(effect.view.misses.single.userAnswer, '1');
    expect(effect.view.misses.single.correctAnswer, item.finalAnswer);
  });

  testWidgets('the training report lists correct, time, and wrong', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    showTrainingReport(
      tester.element(find.byType(Scaffold)),
      correct: 8,
      wrong: 2,
      elapsed: '01:23',
      onSaveWrongs: () async {},
    );
    await tester.pumpAndSettle();
    expect(find.text('训练报告'), findsOneWidget);
    expect(find.textContaining('正确 8 题'), findsOneWidget);
    expect(find.textContaining('用时 01:23'), findsOneWidget);
    expect(find.textContaining('错误 2 题'), findsOneWidget);
    expect(find.textContaining('正确率 80%'), findsOneWidget);
    expect(find.text('加入错题本'), findsOneWidget);
    expect(find.text('一键加入错题本'), findsNothing);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(find.text('再练一次'), findsNothing);
    expect(find.text('('), findsNothing);

    var saved = 0;
    bool? choice;
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();
    expect(saved, 0);

    showTrainingReport(
      tester.element(find.byType(Scaffold)),
      correct: 8,
      wrong: 2,
      elapsed: '01:23',
      bookWrongs: false,
      onSaveWrongs: () async => saved++,
      onBookWrongs: (value) async => choice = value,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();
    expect(saved, 0);
    expect(choice, isFalse);

    showTrainingReport(
      tester.element(find.byType(Scaffold)),
      correct: 7,
      wrong: 3,
      elapsed: '02:00',
      onSaveWrongs: () async => saved++,
      onBookWrongs: (value) async => choice = value,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('正确率 70%'), findsOneWidget);
    expect(find.text('再练一次'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.text('返回首页'));
    await tester.pumpAndSettle();
    expect(saved, 1);
    expect(choice, isTrue);
  });

  test('catalog acceptance items agree with the engine', () async {
    final raw = await rootBundle.loadString('assets/tricks/catalog.json');
    final catalog = Catalog.parse(raw);
    expect(catalog.tricks, hasLength(15));
    expect(catalog.tricks.every((trick) => trick.ready), isTrue);
    expect(catalog.byId('g1-make-10')?.title, 'Make 10');
    expect(avatarIdFor('owl', 'child-a'), 'owl');
    expect(avatarIdFor('nope', 'child-a'), avatarIdFor(null, 'child-a'));
    expect(learnerAvatarIds, hasLength(12));
    expect(learnerAvatarIds.toSet(), hasLength(12));
  });

  test('store ignores a second submit and keeps learners apart', () async {
    final directory = await Directory.systemTemp.createTemp('stepmath');
    final store = HiveAppStore();
    await store.init(path: directory.path);
    final now = DateTime.utc(2026, 11, 19);
    final learner = Learner(
      id: 'child-a',
      displayName: 'Ava',
      grade: '1',
      isGuest: false,
      streakCount: 0,
      lastPracticeDate: null,
      streakSkipWeek: null,
      streakSkipUsed: false,
      favorites: const [],
      seenLessons: const {},
      streakNotice: null,
      createdAt: now,
      updatedAt: now,
    );
    await store.saveLearner(learner);
    final attempt = Attempt(
      id: 'attempt-1',
      learnerId: 'child-a',
      trickId: 'g1-make-10',
      prompt: '8 + 7',
      userAnswer: '15',
      correctAnswer: '15',
      correct: true,
      failedStep: null,
      mode: 'final',
      createdAt: now,
    );
    await store.putAttempt(attempt);
    await store.putAttempt(attempt);
    expect(await store.attempts('child-a'), hasLength(1));
    store.setSession(childMode: true, learnerId: 'child-a');
    expect(
      () => store.attempts('child-b'),
      throwsStateError,
    );
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    expect(await store.readLearners(), isEmpty);
    expect((await store.readSettings()).telemetryEnabled, isFalse);
    await store.close();
    await directory.delete(recursive: true);
  });

  test('a photographed page counts wrong answers and drills that operation', () {
    const page = '8 + 7 = 15\n9 + 6 = 14 x\n12 − 5 = 7\n6 × 4 = 22';
    final facts = parseWorksheet(page);
    expect(facts, hasLength(4));
    expect(facts[0].countedWrong, isFalse);
    expect(facts[1].countedWrong, isTrue);
    expect(facts[1].computed, '15');
    expect(facts[3].countedWrong, isTrue);
    expect(facts[3].operation, 'multiplication');
    final tally = tallyFacts(facts);
    expect(tally.counts['addition'], 1);
    expect(tally.counts['multiplication'], 1);
    expect(tally.focus, 'addition');
    final drill = targetedProblems(facts, rng: Random(1));
    expect(drill, hasLength(5));
    expect(drill.every((problem) => problem.prompt.contains('+')), isTrue);
  });

  test('a problem is spoken in the system language', () {
    expect(spokenPrompt('8 + 7'), '八加七');
    expect(spokenPrompt('12 − 5'), '十二减五');
    expect(spokenPrompt('6 × 4'), '六乘四');
    expect(spokenPrompt('20 ÷ 4'), '二十除以四');
    expect(spokenPrompt('15²'), '十五的平方');
    expect(spokenPrompt('8 + ? = 10'), '八加几等于十');
    expect(spokenPrompt('10% of \$80'), '八十美元的百分之十');
    expect(spokenPrompt('8 + 7', language: 'en'), 'eight plus seven');
    expect(spokenPrompt('10% of \$80', language: 'en'), 'ten percent of eighty dollars');
    expect(ttsLanguageTag('zh'), 'zh-CN');
    expect(ttsLanguageTag('zh', countryCode: 'TW'), 'zh-TW');
    expect(ttsLanguageTag('en', countryCode: 'GB'), 'en-GB');
    expect(ttsLanguageTag('en', countryCode: 'US'), 'en-US');
  });

  test('each grade stays inside its operations', () {
    final kindergarten = speedDefault('K');
    for (var i = 0; i < 20; i++) {
      final problem = nextSpeedProblem(kindergarten, 'K', Random(i));
      final match = RegExp(r'^(\d+) ([+−]) (\d+)$').firstMatch(problem.prompt);
      expect(match, isNotNull);
      final a = int.parse(match!.group(1)!);
      final b = int.parse(match.group(3)!);
      expect(a, lessThanOrEqualTo(10));
      expect(b, lessThanOrEqualTo(10));
      if (match.group(2) == '+') {
        expect(a + b, lessThanOrEqualTo(10));
      } else {
        expect(b, lessThanOrEqualTo(a));
      }
    }

    final third = <String>{};
    for (var i = 0; i < 20; i++) {
      third.add(pickSpeedOperation('mixed', '3', Random(i)));
    }
    expect(third, {'multiplication', 'division'});

    final fifth = speedDefault('5');
    for (var i = 0; i < 30; i++) {
      final problem = nextSpeedProblem(fifth, '5', Random(i));
      expect(problem.finalAnswer.length, lessThanOrEqualTo(8));
      expect(problem.finalAnswer.contains('-'), isFalse);
      final parts = problem.finalAnswer.split('.');
      expect(parts.length, lessThanOrEqualTo(2));
      if (parts.length == 2) expect(parts[1].length, 1);
      final op = pickSpeedOperation('mixed', '5', Random(i));
      expect(['percent', 'decimal', 'fraction'], contains(op));
    }
    expect(spokenPrompt('1/2 + 3/10'), '二分之一加十分之三');
  });
}

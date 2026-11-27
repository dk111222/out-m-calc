import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/app/session.dart';
import 'package:stepmath/pages/sign_in_page.dart';
import 'package:stepmath/app/theme.dart';
import 'package:stepmath/ui/handwriting.dart';
import 'package:stepmath/ui/kit.dart';
import 'package:stepmath/data/hive_store.dart';
import 'package:stepmath/domain/catalog.dart';
import 'package:stepmath/domain/scan.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/domain/digit_ink.dart';
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
    expect(sameNumber('1/2', '0.5'), isTrue);
    expect(sameNumber('-1/2', '-0.5'), isTrue);
    expect(sameNumber('-3', '-3.0'), isTrue);
    expect(legalDraft('1/2'), isTrue);
    expect(legalDraft('-12.5'), isTrue);
    expect(legalDraft('1/2/3'), isFalse);
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

  test('handwriting reads a number and replaces the draft', () {
    expect(readHandAnswer('36'), '36');
    expect(readHandAnswer('8'), '8');
    expect(readHandAnswer('1O'), '10');
    expect(readHandAnswer('S'), '5');
    expect(readHandAnswer('6.5'), '6.5');
    expect(readHandAnswer('hello'), '');
    expect(readHandAnswer('-12'), '-12');
    expect(readHandAnswer('−3.5'), '-3.5');
    expect(readHandAnswer('3/10'), '3/10');
    expect(readHandAnswer('-1/2'), '-1/2');
    expect(pickInkAnswer(['-1/2']), '-1/2');
    expect(pickInkAnswer(['hello', '12']), '12');
    List<InkPoint> stroke(double x0, double y0, double x1, double y1) {
      return [InkPoint(x0, y0), InkPoint(x1, y1)];
    }

    expect(
      segmentInk([
        stroke(8, 40, 40, 41),
        stroke(58, 10, 60, 72),
        stroke(100, 12, 102, 70),
      ]).map((glyph) => glyph.kind),
      [InkKind.minus, InkKind.digit, InkKind.digit],
    );
    expect(
      segmentInk([
        stroke(10, 8, 12, 70),
        [InkPoint(30, 62), InkPoint(33, 65)],
        stroke(48, 8, 50, 70),
      ]).map((glyph) => glyph.kind),
      [InkKind.digit, InkKind.dot, InkKind.digit],
    );
    expect(
      segmentInk([
        stroke(10, 8, 14, 72),
        stroke(24, 8, 52, 74),
        stroke(66, 8, 70, 72),
      ]).map((glyph) => glyph.kind),
      [InkKind.digit, InkKind.slash, InkKind.digit],
    );
    expect(
      segmentInk([
        stroke(30, 6, 34, 26),
        stroke(16, 40, 54, 42),
        stroke(30, 56, 34, 80),
      ]).map((glyph) => glyph.kind),
      [InkKind.digit, InkKind.slash, InkKind.digit],
    );
    expect(
      segmentInk([
        stroke(40, 8, 42, 78),
        stroke(12, 40, 50, 42),
        stroke(14, 40, 40, 10),
      ]),
      hasLength(1),
    );
    expect(
      segmentInk([
        stroke(12, 8, 16, 80),
        stroke(36, 12, 70, 14),
        stroke(70, 14, 72, 70),
        stroke(72, 70, 34, 74),
        stroke(34, 74, 32, 16),
      ]).where((glyph) => glyph.kind == InkKind.digit),
      hasLength(2),
    );
    final net = DigitNet.fromBytes(
      File('assets/models/digits.f32').readAsBytesSync(),
    );
    final zero = [
      for (var i = 0; i <= 40; i++)
        InkPoint(
          50 + 32 * cos(2 * pi * i / 40),
          50 + 42 * sin(2 * pi * i / 40),
        ),
    ];
    expect(recognizeInk([zero], net), '0');
    expect(
      recognizeInk([stroke(50, 8, 50, 92), stroke(34, 22, 50, 8)], net),
      '1',
    );
    final one = [stroke(50, 8, 50, 92), stroke(34, 22, 50, 8)];
    expect(recognizeInk([stroke(2, 48, 32, 49), ...one], net), '-1');
    expect(
      recognizeInk([
        ...one,
        [InkPoint(78, 78), InkPoint(82, 82)],
        [for (final point in zero) InkPoint(point.x + 70, point.y)],
      ], net),
      '1.0',
    );
    expect(
      recognizeInk([
        zero,
        stroke(96, 12, 128, 88),
        ...one.map(
          (stroke) => [
            for (final point in stroke) InkPoint(point.x + 110, point.y),
          ],
        ),
      ], net),
      '0/1',
    );
    expect(
      decodeInk([
        stroke(8, 40, 40, 41),
        stroke(58, 10, 60, 72),
        stroke(100, 12, 102, 70),
      ], (_) => const DigitScore(1, 0.95)),
      '-11',
    );
    expect(
      decodeInk([
        stroke(10, 8, 12, 70),
        [InkPoint(30, 62), InkPoint(33, 65)],
        stroke(48, 8, 50, 70),
      ], (_) => const DigitScore(1, 0.95)),
      '1.1',
    );
    expect(
      decodeInk([
        stroke(10, 8, 14, 72),
        stroke(24, 8, 52, 74),
        stroke(66, 8, 70, 72),
      ], (_) => const DigitScore(1, 0.95)),
      '1/1',
    );
    expect(
      decodeInk([
        stroke(30, 6, 34, 26),
        stroke(16, 40, 54, 42),
        stroke(30, 56, 34, 80),
      ], (_) => const DigitScore(1, 0.95)),
      '1/1',
    );
    expect(
      decodeInk([
        stroke(40, 8, 42, 78),
        stroke(12, 40, 50, 42),
        stroke(14, 40, 40, 10),
      ], (_) => const DigitScore(4, 0.8)),
      '4',
    );
    expect(
      decodeInk([
        [InkPoint(20, 62), InkPoint(23, 65)],
        stroke(48, 8, 50, 70),
      ], (_) => const DigitScore(5, 0.9)),
      '0.5',
    );
    expect(pickInkAnswer(['.']), isNull);
    final view = PracticeView.start(
      learnerId: 'a',
      trickId: 't',
      items: const [
        Problem(
          trickId: 't',
          prompt: '8 + 7',
          finalAnswer: '15',
          steps: [StepAsk(1, '8 + 7', '15')],
        ),
      ],
    );
    expect(practiceReplace(view, '15').view.draft, '15');
    expect(identical(practiceReplace(view, 'no').view, view), isTrue);
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
      expect(items, hasLength(20));
      expect(items.map((item) => item.prompt).toSet().length, greaterThan(1));
      expect(isDailyPractice(config, grade), isTrue);
    }
  });

  test('today\'s daily practice tally', () {
    const grade = '1';
    final daily = dailyPractice(grade);
    final today = DateTime(2026, 11, 26, 9, 30);
    final todayKey = formatYmd(today);
    final rounds = [
      SpeedRound(
        id: 'daily',
        learnerId: 'learner',
        operation: daily.operation,
        digitMin: daily.digitMin,
        digitMax: daily.digitMax,
        limitMode: 'count',
        limitValue: daily.limitValue,
        correctCount: 16,
        durationMs: 40000,
        createdAt: today.toUtc(),
      ),
      SpeedRound(
        id: 'other-operation',
        learnerId: 'learner',
        operation: 'addition',
        digitMin: daily.digitMin,
        digitMax: daily.digitMax,
        limitMode: 'count',
        limitValue: 10,
        correctCount: 10,
        durationMs: 1111,
        createdAt: today.toUtc(),
      ),
      SpeedRound(
        id: 'other-day',
        learnerId: 'learner',
        operation: daily.operation,
        digitMin: daily.digitMin,
        digitMax: daily.digitMax,
        limitMode: 'count',
        limitValue: daily.limitValue,
        correctCount: 10,
        durationMs: 99999,
        createdAt: DateTime(2026, 11, 25, 9, 30).toUtc(),
      ),
      SpeedRound(
        id: 'timed',
        learnerId: 'learner',
        operation: daily.operation,
        digitMin: daily.digitMin,
        digitMax: daily.digitMax,
        limitMode: 'time',
        limitValue: 60,
        correctCount: 3,
        durationMs: 5000,
        createdAt: today.toUtc(),
      ),
    ];

    final finished = tallyDailyPractice(
      rounds: rounds,
      grade: grade,
      today: todayKey,
    );
    expect(finished.answered, daily.limitValue);
    expect(finished.correct, 16);
    expect(finished.durationMs, 40000);
    expect(finished.accuracyLabel, '80%');
    expect(dailyRoundStars(correct: 20, asked: 20), 3);
    expect(dailyRoundStars(correct: 19, asked: 20), 2);
    expect(dailyRoundStars(correct: 16, asked: 20), 2);
    expect(dailyRoundStars(correct: 12, asked: 20), 1);
    expect(dailyRoundStars(correct: 11, asked: 20), 0);
    expect(dailyRoundStars(correct: 0, asked: 0), 0);
    expect(bestDailyStars(rounds: rounds, grade: grade, today: todayKey), 2);
    expect(
      bestDailyStars(
        rounds: [
          rounds.first,
          SpeedRound(
            id: 'perfect',
            learnerId: 'learner',
            operation: daily.operation,
            digitMin: daily.digitMin,
            digitMax: daily.digitMax,
            limitMode: 'count',
            limitValue: daily.limitValue,
            correctCount: 20,
            durationMs: 30000,
            createdAt: today.toUtc(),
          ),
        ],
        grade: grade,
        today: todayKey,
      ),
      3,
    );

    final withOpen = tallyDailyPractice(
      rounds: rounds,
      grade: grade,
      today: todayKey,
      openAnswered: 5,
      openCorrect: 4,
      openDurationMs: 20000,
    );
    expect(withOpen.answered, daily.limitValue + 5);
    expect(withOpen.correct, 20);
    expect(withOpen.durationMs, 60000);
    expect(withOpen.accuracyLabel, '80%');

    expect(
      tallyDailyPractice(
        rounds: const [],
        grade: grade,
        today: todayKey,
      ).accuracyLabel,
      '—',
    );

    SessionSnapshot snap({
      required String module,
      required String day,
      required Map<String, Object?> payload,
    }) {
      return SessionSnapshot(
        learnerId: 'learner',
        module: module,
        trickId: null,
        localDate: day,
        payload: jsonEncode(payload),
        updatedAt: today.toUtc(),
      );
    }

    final open = openDailyPractice(
      snap(
        module: 'speed',
        day: todayKey,
        payload: {
          'done': false,
          'answered': 0,
          'correct': 0,
          'elapsedMs': 0,
          'config': daily.toJson(),
        },
      ),
      grade,
      todayKey,
    );
    expect(open, isNotNull);
    expect(
      tallyDailyPractice(
        rounds: const [],
        grade: grade,
        today: todayKey,
        openAnswered: open!.answered,
        openCorrect: open.correct,
        openDurationMs: open.durationMs,
      ).accuracyLabel,
      '—',
    );
    expect(
      openDailyPractice(
        snap(
          module: 'speed',
          day: todayKey,
          payload: {
            'done': true,
            'answered': 10,
            'correct': 10,
            'elapsedMs': 1000,
            'config': daily.toJson(),
          },
        ),
        grade,
        todayKey,
      ),
      isNull,
    );
    expect(
      openDailyPractice(
        snap(
          module: 'learn',
          day: todayKey,
          payload: {
            'done': false,
            'answered': 4,
            'correct': 4,
            'elapsedMs': 1000,
            'config': daily.toJson(),
          },
        ),
        grade,
        todayKey,
      ),
      isNull,
    );
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

  test(
    'a correct step waits, then moves, and the attempt is recorded once',
    () {
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
    },
  );

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
    answerByHandwriting = false;
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
    final submit = tester.getCenter(
      find.descendant(
        of: find.byType(Keypad),
        matching: find.byIcon(Icons.check),
      ),
    );
    expect(submit.dx, greaterThan(zero.dx));
    expect((submit.dy - zero.dy).abs(), lessThan(24));
    expect(find.text('删除'), findsNothing);
    expect(find.widgetWithText(FilledButton, '提交'), findsNothing);
    expect(find.byIcon(Icons.onetwothree), findsOneWidget);
    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });

  testWidgets('training can switch between numbers and handwriting', (
    tester,
  ) async {
    addTearDown(() => answerByHandwriting = false);
    answerByHandwriting = false;
    await tester.binding.setSurfaceSize(const Size(390, 800));
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
            onReplace: (_) {},
            onSubmit: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.draw_outlined));
    await tester.pump();
    expect(find.byType(Keypad), findsNothing);
    expect(find.byType(HandwritingPad), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HandwritingPad),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.onetwothree_outlined));
    await tester.pump();
    expect(find.byType(Keypad), findsOneWidget);
    expect(find.byType(HandwritingPad), findsNothing);
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
    final keypad = tester.getRect(find.byType(Keypad)).top;
    await show(previous: '6 + 6');
    expect(find.textContaining('6 + 6'), findsOneWidget);
    expect(tester.getRect(find.text('8 + 7')).top, current);
    expect(tester.getRect(find.textContaining('9 + 8')).top, next);
    expect(tester.getRect(find.byType(Keypad)).top, keypad);
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
    expect(avatarIdFor('maple', 'child-a'), 'maple');
    expect(avatarIdFor('nope', 'child-a'), avatarIdFor(null, 'child-a'));
    expect(kidAvatarIds, hasLength(12));
    expect(animalAvatarIds, hasLength(12));
    expect(learnerAvatarIds, hasLength(24));
    expect(learnerAvatarIds.toSet(), hasLength(24));
    expect(learnerAvatarIds, containsAll(animalAvatarIds));
  });

  test('boot lands on home and finishes under three seconds', () async {
    final directory = await Directory.systemTemp.createTemp('stepmath-boot');
    final store = HiveAppStore();
    final catalog = Catalog.parse(
      await File('assets/tricks/catalog.json').readAsString(),
    );
    final started = Stopwatch()..start();
    await store.init(path: directory.path);
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    started.stop();
    expect(app.ready, isTrue);
    expect(app.bootError, isNull);
    expect(app.openLocation(), '/sign-in');
    expect(app.redirect('/child'), '/sign-in');
    expect(app.redirect('/sign-in'), isNull);
    expect(await app.signInAsGuest(), isNull);
    expect(app.openLocation(), '/child');
    expect(started.elapsedMilliseconds, lessThan(3000));
    await store.ensureFull();
    await store.close();
    await directory.delete(recursive: true);
  });

  test(
    'a parent can sign in with a provider and then delete the account',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stepmath-account',
      );
      final store = HiveAppStore();
      await store.init(path: directory.path);
      final catalog = Catalog.parse(
        await File('assets/tricks/catalog.json').readAsString(),
      );
      final app = AppController(store: store, catalog: catalog);
      await app.boot();
      expect(
        await app.signInWithIdentity(
          provider: 'google',
          subject: 'google-user-1',
          email: 'ada@example.com',
          name: 'Ada',
        ),
        isNull,
      );
      expect(app.settings.signedIn, isTrue);
      expect(app.settings.accountProvider, 'google');
      await app.signOut();
      expect(
        await app.signInWithIdentity(
          provider: 'apple',
          subject: 'apple-user-2',
          email: 'other@example.com',
        ),
        app.copy.accountAlreadyOnDevice,
      );
      expect(await app.deleteAccount('1234', again: '1234'), isTrue);
      expect(app.settings.signedIn, isFalse);
      expect(app.settings.accountSubject, isNull);
      expect(app.settings.accountEmail, isNull);
      await store.close();
      await directory.delete(recursive: true);
    },
  );

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
    await expectLater(store.attempts('child-b'), throwsStateError);
    store.setSession(childMode: false, learnerId: null);
    await store.wipe();
    expect(await store.readLearners(), isEmpty);
    expect((await store.readSettings()).telemetryEnabled, isFalse);
    await store.close();
    await directory.delete(recursive: true);
  });

  testWidgets('sign-in offers Google, Apple, and guest', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<void> show(TargetPlatform platform) {
      return tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.light).copyWith(platform: platform),
            themeAnimationDuration: Duration.zero,
            home: const SignInPage(),
          ),
        ),
      );
    }

    await show(TargetPlatform.android);
    await tester.pump(const Duration(milliseconds: 300));
    final headline = tester.widget<Text>(find.text("Let's practice math!"));
    expect(headline.textAlign, TextAlign.center);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Play as Guest'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('使用 Google 登录'), findsNothing);
    expect(find.text('通过 Apple 登录'), findsNothing);

    await show(TargetPlatform.iOS);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text("Let's practice math!"), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.text('Play as Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'a local guest signs in on this device and a child can open it',
    () async {
      final directory = await Directory.systemTemp.createTemp('stepmath-login');
      final store = HiveAppStore();
      await store.init(path: directory.path);
      final catalog = Catalog.parse(
        File('assets/tricks/catalog.json').readAsStringSync(),
      );
      final app = AppController(store: store, catalog: catalog);
      await app.boot();
      expect(await app.signInAsGuest(), isNull);
      expect(app.settings.signedIn, isTrue);
      expect(app.settings.accountProvider, 'guest');
      expect(app.settings.accountName, '本地游客');
      final subject = app.settings.accountSubject;
      await app.signOut();
      expect(app.settings.signedIn, isFalse);
      expect(await app.signInAsGuest(), isNull);
      expect(app.settings.accountSubject, subject);
      expect(
        await app.signInWithIdentity(
          provider: 'google',
          subject: 'someone-else',
        ),
        app.copy.accountAlreadyOnDevice,
      );
      expect(
        await app.createLearner(name: '访客', grade: '1', guest: true),
        isNull,
      );
      await app.enterChild(app.learners.single.id);
      expect(app.redirect('/sign-in'), isNull);
      expect(app.redirect('/terms'), isNull);
      expect(app.redirect('/settings/privacy'), isNull);
      expect(app.redirect('/settings'), '/child');
      await store.close();
      await directory.delete(recursive: true);
    },
  );

  test('a guest keeps one child and Google keeps three', () async {
    final directory = await Directory.systemTemp.createTemp('stepmath-cap');
    final store = HiveAppStore();
    await store.init(path: directory.path);
    final catalog = Catalog.parse(
      File('assets/tricks/catalog.json').readAsStringSync(),
    );
    final guest = AppController(store: store, catalog: catalog);
    await guest.boot();
    expect(await guest.signInAsGuest(), isNull);
    expect(await guest.createLearner(name: 'Ava', grade: '1'), isNull);
    expect(await guest.createLearner(name: 'Ben', grade: '1'), isNotNull);
    expect(guest.learners, hasLength(1));
    await store.close();
    await directory.delete(recursive: true);

    final other = await Directory.systemTemp.createTemp('stepmath-cap-google');
    final googleStore = HiveAppStore();
    await googleStore.init(path: other.path);
    final google = AppController(store: googleStore, catalog: catalog);
    await google.boot();
    expect(
      await google.signInWithIdentity(
        provider: 'google',
        subject: 'google-1',
        name: 'Ada',
      ),
      isNull,
    );
    for (final name in ['Ava', 'Ben', 'Cleo']) {
      expect(await google.createLearner(name: name, grade: '1'), isNull);
    }
    expect(await google.createLearner(name: 'Dee', grade: '1'), isNotNull);
    expect(google.learners, hasLength(3));
    final ava = google.learners.firstWhere(
      (learner) => learner.displayName == 'Ava',
    );
    await google.enterChild(ava.id);
    expect(
      await google.updateLearner(
        id: ava.id,
        name: 'Ava B',
        grade: '3',
        avatar: 'fox',
      ),
      isNull,
    );
    expect(google.learnerById(ava.id)?.displayName, 'Ava B');
    expect(google.learnerById(ava.id)?.grade, '3');
    expect(google.learnerById(ava.id)?.avatar, 'fox');
    expect(google.activeLearnerId, ava.id);
    final ben = google.learners.firstWhere(
      (learner) => learner.displayName == 'Ben',
    );
    expect(
      await google.updateLearner(id: ben.id, name: 'Ben B', grade: '2'),
      isNull,
    );
    expect(google.learnerById(ben.id)?.displayName, 'Ben B');
    expect(google.activeLearnerId, ava.id);
    expect(google.redirect('/learner/edit/${ben.id}'), isNull);
    await googleStore.close();
    await other.delete(recursive: true);
  });

  test('a guest session can add a learner without a parent code', () async {
    final directory = await Directory.systemTemp.createTemp('stepmath-guest');
    final store = HiveAppStore();
    await store.init(path: directory.path);
    final catalog = Catalog.parse(
      File('assets/tricks/catalog.json').readAsStringSync(),
    );
    final app = AppController(store: store, catalog: catalog);
    await app.boot();
    expect(
      await app.createLearner(name: '访客', grade: '1', guest: true),
      isNull,
    );
    await app.enterChild(app.learners.single.id);
    expect(await app.createLearner(name: 'Mia', grade: '2'), isNull);
    expect(app.learners.map((learner) => learner.displayName), ['访客', 'Mia']);
    await store.close();
    await directory.delete(recursive: true);
  });

  test(
    'a photographed page counts wrong answers and drills that operation',
    () {
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
      final graded = gradeSheet([
        (
          text: '8 + 7 = 15',
          pieces: [
            const SheetPiece('8', 0, 0, 10, 20),
            const SheetPiece('+', 14, 0, 24, 20),
            const SheetPiece('7', 28, 0, 38, 20),
            const SheetPiece('=', 42, 0, 52, 20),
            const SheetPiece('15', 56, 0, 80, 20),
          ],
        ),
        (
          text: '6 × 4 = 22',
          pieces: [
            const SheetPiece('6', 0, 40, 10, 60),
            const SheetPiece('×', 14, 40, 28, 60),
            const SheetPiece('4', 32, 40, 42, 60),
            const SheetPiece('=', 46, 40, 56, 60),
            const SheetPiece('22', 60, 40, 84, 60),
          ],
        ),
      ]);
      expect(graded, hasLength(2));
      expect(graded[0].correct, isTrue);
      expect(graded[0].right, 80);
      expect(graded[1].correct, isFalse);
      expect(graded[1].fact.computed, '24');
      expect(graded[1].left, 0);
      expect(graded[1].bottom, 60);
      expect(drill.every((problem) => problem.prompt.contains('+')), isTrue);
    },
  );

  test('a problem is spoken in the system language', () {
    expect(spokenPrompt('8 + 7'), '八加七');
    expect(spokenPrompt('12 − 5'), '十二减五');
    expect(spokenPrompt('6 × 4'), '六乘四');
    expect(spokenPrompt('20 ÷ 4'), '二十除以四');
    expect(spokenPrompt('15²'), '十五的平方');
    expect(spokenPrompt('8 + ? = 10'), '八加几等于十');
    expect(spokenPrompt('10% of \$80'), '八十美元的百分之十');
    expect(spokenPrompt('8 + 7', language: 'en'), 'eight plus seven');
    expect(
      spokenPrompt('10% of \$80', language: 'en'),
      'ten percent of eighty dollars',
    );
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

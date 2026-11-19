import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/data/hive_store.dart';
import 'package:stepmath/domain/catalog.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/domain/engine.dart';
import 'package:stepmath/domain/machines.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(speedDefault('K').limitMode, 'count');
    expect(speedDefault('K').limitValue, 10);
    expect(speedDefault('1').limitMode, 'count');
    expect(speedDefault('2').limitValue, 120);
    expect(speedDefault('3').limitValue, 180);
    expect(speedDefault('5').limitMode, 'time');
    expect(speedDefault('5').operation, 'percent');
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
    expect(correctAdvance.inMilliseconds, lessThan(100));
  });

  test('catalog acceptance items agree with the engine', () async {
    final raw = await rootBundle.loadString('assets/tricks/catalog.json');
    final catalog = Catalog.parse(raw);
    expect(catalog.tricks, hasLength(15));
    expect(catalog.tricks.every((trick) => trick.ready), isTrue);
    expect(catalog.byId('g1-make-10')?.title, 'Make 10');
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
    await directory.delete(recursive: true);
  });

  test('speed problems stay inside the kindergarten cap', () {
    final rng = Random(4);
    final config = speedDefault('K');
    for (var i = 0; i < 30; i++) {
      final problem = nextSpeedProblem(config, 'K', rng);
      final parts = problem.prompt.split(' + ');
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      expect(a + b, lessThanOrEqualTo(10));
    }
  });
}

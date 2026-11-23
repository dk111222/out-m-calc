import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/catalog.dart';
import '../domain/core.dart';
import '../domain/engine.dart';
import '../domain/machines.dart';
import '../domain/store.dart';
import '../l10n/copy.dart';
import '../l10n/trick_zh.dart';
import 'voice.dart';

class AppClock {
  DateTime now() => DateTime.now();
  String get today => formatYmd(now().toLocal());
  String get week => weekKey(now().toLocal());
}

class AppController extends ChangeNotifier {
  AppController({
    required this.store,
    required this.catalog,
    AppClock? clock,
    VoiceCue? voice,
  }) : clock = clock ?? AppClock(),
       voice = voice ?? VoiceCue();

  final AppStore store;
  final Catalog catalog;
  final AppClock clock;
  final VoiceCue voice;

  bool ready = false;
  String? bootError;
  bool childMode = false;
  String? activeLearnerId;
  DeviceSettings settings = DeviceSettings.fresh();
  Copy get copy => Copy(settings.language);
  List<Learner> learners = [];
  final Map<String, Assignment?> today = {};
  SessionSnapshot? snapshot;
  String? banner;

  Learner? learnerById(String? id) {
    if (id == null) return null;
    for (final learner in learners) {
      if (learner.id == id) return learner;
    }
    return null;
  }

  Learner? get active => learnerById(activeLearnerId);

  bool get errorTrainingOpen => errorTrainingAllowed(
    signedIn: settings.signedIn,
    subscribed: settings.subscriptionActive,
  );

  void _session() {
    store.setSession(childMode: childMode, learnerId: activeLearnerId);
  }

  String openLocation() {
    if (!ready || bootError != null) return '/loading';
    if (learners.isEmpty || childMode) return '/child';
    return '/adult';
  }

  String? redirect(String loc) {
    if (!ready || bootError != null) {
      return loc == '/loading' ? null : '/loading';
    }
    const childOk = [
      '/child',
      '/tricks',
      '/practice',
      '/speed',
      '/review',
      '/scan',
      '/prefs',
      '/report',
      '/export',
      '/assign',
      '/learner/new',
    ];
    if (learners.isEmpty) {
      const open = ['/child', '/prefs', '/learner/new', '/settings'];
      final allowed = open.any(
        (prefix) => loc == prefix || loc.startsWith('$prefix/'),
      );
      return allowed ? null : '/child';
    }
    if (childMode) {
      final allowed = childOk.any(
        (prefix) => loc == prefix || loc.startsWith('$prefix/'),
      );
      return allowed ? null : '/child';
    }
    if (loc == '/loading' || loc == '/start') return '/adult';
    return null;
  }

  Future<void> boot() async {
    bootError = null;
    try {
      settings = await store.readSettings();
      // Streak rolls need adult access across every learner.
      childMode = false;
      activeLearnerId = settings.activeLearnerId;
      _session();
      learners = await store.readLearners();
      if (activeLearnerId == null && learners.isNotEmpty) {
        activeLearnerId = learners.first.id;
      }
      if (learners.every((learner) => learner.id != activeLearnerId)) {
        activeLearnerId = learners.isEmpty ? null : learners.first.id;
      }
      await _roll();
      // Enter the child session once, then load today's card a single time.
      if (activeLearnerId != null) {
        childMode = true;
        _session();
      }
      await Future.wait([refreshToday(), refreshSnapshot()]);
      ready = true;
    } catch (_) {
      bootError = copy.couldNotSave;
      ready = true;
    }
    notifyListeners();
  }

  Future<void> _roll() async {
    final today = clock.today;
    final week = clock.week;
    final updates = <Learner>[];
    await Future.wait([
      for (final learner in [...learners])
        () async {
          final rolled = rollStreak(
            count: learner.streakCount,
            lastDate: learner.lastPracticeDate,
            skipWeek: learner.streakSkipWeek,
            skipUsed: learner.streakSkipUsed,
            notice: learner.streakNotice,
            today: today,
            thisWeek: week,
          );
          if (rolled.changed) {
            final next = learner.copyWith(
              streakCount: rolled.count,
              lastPracticeDate: rolled.lastDate,
              clearLastDate: rolled.lastDate == null,
              streakSkipWeek: rolled.skipWeek,
              streakSkipUsed: rolled.skipUsed,
              streakNotice: rolled.notice,
              clearNotice: rolled.notice == null,
              updatedAt: clock.now().toUtc(),
            );
            await store.saveLearner(next);
            updates.add(next);
          }
          final snap = await store.snapshot(learner.id);
          if (snap != null && snap.localDate != today) {
            await store.clearSnapshot(learner.id);
          }
        }(),
    ]);
    for (final next in updates) {
      _replace(next);
    }
  }

  void _replace(Learner learner) {
    var found = false;
    learners = [
      for (final item in learners)
        if (item.id == learner.id)
          () {
            found = true;
            return learner;
          }()
        else
          item,
    ];
    if (!found) learners = [...learners, learner];
  }

  Future<void> refreshToday() async {
    final ids = childMode && activeLearnerId != null
        ? [activeLearnerId!]
        : learners.map((learner) => learner.id).toList();
    final date = clock.today;
    final loaded = await Future.wait([
      for (final id in ids) store.openAssignment(id, date),
    ]);
    for (var i = 0; i < ids.length; i++) {
      today[ids[i]] = loaded[i];
    }
  }

  Future<void> refreshSnapshot() async {
    final id = activeLearnerId;
    snapshot = id == null ? null : await store.snapshot(id);
  }

  String _nextName({required bool guest}) {
    final stem = guest ? copy.guest : copy.learnerStem;
    final taken = learners.map((learner) => learner.displayName).toSet();
    if (!taken.contains(stem)) return stem;
    var n = 2;
    while (taken.contains('$stem $n')) {
      n += 1;
    }
    return '$stem $n';
  }

  Future<String?> createLearner({
    required String name,
    required String grade,
    String? avatar,
    bool guest = false,
  }) async {
    if (childMode) return copy.parentNeedsThis;
    grade = canonicalGrade(grade);
    if (!grades.contains(grade)) return copy.chooseGrade;
    if (learners.isNotEmpty && !settings.extraLearnersUnlocked) {
      return copy.anotherLearner;
    }
    final trimmed = name.trim();
    final display = trimmed.isEmpty
        ? _nextName(guest: guest)
        : trimmed.substring(0, min(60, trimmed.length));
    final now = clock.now().toUtc();
    final learner = Learner(
      id: newId(),
      displayName: display,
      grade: grade,
      avatar: avatarIdFor(
        avatar,
        '${learners.length}-${display.hashCode}',
      ),
      isGuest: guest,
      streakCount: 0,
      lastPracticeDate: null,
      streakSkipWeek: clock.week,
      streakSkipUsed: false,
      favorites: const [],
      seenLessons: const {},
      streakNotice: null,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await store.saveLearner(learner);
      _replace(learner);
      activeLearnerId = learner.id;
      settings = settings.copyWith(activeLearnerId: learner.id, updatedAt: now);
      await store.saveSettings(settings);
      await refreshToday();
      banner = null;
      notifyListeners();
      return null;
    } catch (_) {
      banner = copy.couldNotSave;
      notifyListeners();
      return banner;
    }
  }

  Future<void> enterChild(String id) async {
    activeLearnerId = id;
    childMode = true;
    _session();
    settings = settings.copyWith(
      activeLearnerId: id,
      updatedAt: clock.now().toUtc(),
    );
    try {
      await store.saveSettings(settings);
      await refreshToday();
      await refreshSnapshot();
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
    }
    notifyListeners();
  }

  Future<bool> submitPin(String pin, {String? again}) async {
    final now = clock.now();
    if (!looksLikePin(pin)) return false;
    if (settings.parentPinHash == null) {
      if (pin != again) return false;
      final salt = newSalt();
      settings = settings.copyWith(
        parentPinHash: hashPin(pin, salt),
        pinSalt: salt,
        pinFailCount: 0,
        clearLock: true,
        updatedAt: now.toUtc(),
      );
      await store.saveSettings(settings);
      notifyListeners();
      return true;
    }
    final verdict = checkPin(settings, pin, now);
    settings = verdict.settings.copyWith(updatedAt: now.toUtc());
    await store.saveSettings(settings);
    notifyListeners();
    return verdict.ok;
  }

  Future<String?> createAccount({
    required String email,
    required String password,
    required String again,
  }) async {
    final normalized = email.trim().toLowerCase();
    final emailError = accountEmailError(normalized);
    if (emailError != null) return emailError;
    final passwordError = newPasswordError(password, again);
    if (passwordError != null) return passwordError;
    if (settings.accountEmail != null) {
      return 'This device already has an account.';
    }
    final salt = newSalt();
    settings = settings.copyWith(
      accountEmail: normalized,
      accountPasswordHash: hashPin(password, salt),
      accountSalt: salt,
      signedIn: true,
      updatedAt: clock.now().toUtc(),
    );
    try {
      await store.saveSettings(settings);
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
      notifyListeners();
      return banner;
    }
    notifyListeners();
    return null;
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final emailError = accountEmailError(normalized);
    if (emailError != null) return emailError;
    if (settings.accountEmail == null) return 'Create an account first.';
    if (normalized != settings.accountEmail) {
      return 'That email is not the account on this device.';
    }
    if (settings.accountSalt == null ||
        hashPin(password, settings.accountSalt!) !=
            settings.accountPasswordHash) {
      return 'That password does not match.';
    }
    settings = settings.copyWith(
      signedIn: true,
      updatedAt: clock.now().toUtc(),
    );
    await store.saveSettings(settings);
    notifyListeners();
    return null;
  }

  Future<void> signOut() async {
    if (!settings.signedIn) return;
    settings = settings.copyWith(
      signedIn: false,
      updatedAt: clock.now().toUtc(),
    );
    await store.saveSettings(settings);
    notifyListeners();
  }

  Future<String?> subscribe() async {
    if (!settings.signedIn) return 'Sign in first.';
    settings = settings.copyWith(
      subscriptionActive: true,
      updatedAt: clock.now().toUtc(),
    );
    await store.saveSettings(settings);
    notifyListeners();
    return null;
  }

  /// Replaces a code that was already checked. A mismatched repeat keeps the old code.
  Future<bool> setNewPin(String pin, String? again) async {
    if (!looksLikePin(pin) || pin != again) return false;
    settings = settings.copyWith(clearPin: true);
    return submitPin(pin, again: again);
  }

  Future<bool> leaveChild(String pin, {String? again}) async {
    final ok = await submitPin(pin, again: again);
    if (!ok) return false;
    childMode = false;
    _session();
    learners = await store.readLearners();
    await refreshToday();
    notifyListeners();
    return true;
  }

  Future<bool> wipeAll(String pin, {String? again}) async {
    if (childMode) return false;
    final ok = await submitPin(pin, again: again);
    if (!ok) return false;
    await store.wipe();
    settings = await store.readSettings();
    learners = [];
    today.clear();
    snapshot = null;
    activeLearnerId = null;
    childMode = false;
    _session();
    notifyListeners();
    return true;
  }

  Future<bool> removeLearner(String id, String pin, {String? again}) async {
    if (childMode) return false;
    final ok = await submitPin(pin, again: again);
    if (!ok) return false;
    await store.deleteLearner(id);
    learners = await store.readLearners();
    if (activeLearnerId == id) {
      activeLearnerId = learners.isEmpty ? null : learners.first.id;
    }
    settings = await store.readSettings();
    await refreshToday();
    notifyListeners();
    return true;
  }

  Future<void> updateSettings(DeviceSettings next) async {
    settings = next.copyWith(updatedAt: clock.now().toUtc());
    try {
      await store.saveSettings(settings);
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String learnerId, String trickId) async {
    final learner = learnerById(learnerId);
    if (learner == null) return;
    final next = [...learner.favorites];
    if (next.contains(trickId)) {
      next.remove(trickId);
    } else {
      next.add(trickId);
    }
    await _saveLearner(learner.copyWith(favorites: next));
  }

  Future<void> markLessonSeen(String learnerId, String trickId) async {
    final learner = learnerById(learnerId);
    if (learner == null) return;
    final seen = {...learner.seenLessons, trickId: clock.today};
    await _saveLearner(learner.copyWith(seenLessons: seen));
  }

  Future<void> _saveLearner(Learner learner) async {
    try {
      final next = learner.copyWith(updatedAt: clock.now().toUtc());
      await store.saveLearner(next);
      _replace(next);
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
    }
    notifyListeners();
  }

  Future<void> saveAssignment(Assignment assignment) async {
    try {
      await store.saveAssignment(assignment);
      today[assignment.learnerId] = assignment.status == 'open'
          ? assignment
          : today[assignment.learnerId];
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
    }
    notifyListeners();
  }

  Future<List<Problem>> dueReviews(String learnerId, String trickId) async {
    final items = await store.masteries(learnerId);
    final today = clock.today;
    final reviews = <Problem>[];
    for (final item in items) {
      if (item.trickId != trickId) continue;
      if (reviewIsDue(
        masteredOn: item.masteredOn,
        offsetDays: 3,
        today: today,
        done: item.review3Done,
      )) {
        reviews.add(
          generateTrick(
            trickId,
            standard: true,
            rng: Random(),
            guided: true,
            review: true,
            reviewSlot: 3,
          ),
        );
      }
      if (reviewIsDue(
        masteredOn: item.masteredOn,
        offsetDays: 14,
        today: today,
        done: item.review14Done,
      )) {
        reviews.add(
          generateTrick(
            trickId,
            standard: true,
            rng: Random(),
            guided: true,
            review: true,
            reviewSlot: 14,
          ),
        );
      }
    }
    return reviews;
  }

  Future<void> rememberSnapshot(SessionSnapshot value) async {
    try {
      await store.saveSnapshot(value);
      if (value.learnerId == activeLearnerId) snapshot = value;
      banner = null;
    } catch (_) {
      banner = copy.couldNotSave;
      notifyListeners();
    }
  }

  Future<void> recordAttempt(AttemptDraft draft) async {
    final learner = active;
    if (learner == null) return;
    final now = clock.now().toUtc();
    final id = newId();
    await store.putAttempt(
      Attempt(
        id: id,
        learnerId: learner.id,
        trickId: draft.trickId,
        prompt: draft.prompt,
        userAnswer: draft.userAnswer,
        correctAnswer: draft.correctAnswer,
        correct: draft.correct,
        failedStep: draft.failedStep,
        mode: draft.mode,
        createdAt: now,
      ),
    );
    if (!draft.correct && draft.bookWrong) {
      await store.putWrong(
        WrongItem(
          id: newId(),
          learnerId: learner.id,
          attemptId: id,
          trickId: draft.trickId,
          prompt: draft.prompt,
          userAnswer: draft.userAnswer,
          correctAnswer: draft.correctAnswer,
          failedStep: draft.failedStep,
          stepsJson: jsonEncode(
            draft.steps.map((step) => step.toJson()).toList(),
          ),
          reviewedOk: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (draft.repairWrongId != null) {
      final wrongs = await store.wrongs(learner.id);
      for (final item in wrongs) {
        if (item.id == draft.repairWrongId) {
          await store.saveWrong(
            item.copyWith(reviewedOk: true, updatedAt: now),
          );
        }
      }
    }
    if (draft.mode == 'final') {
      await _mastery(learner, draft, id, now);
    } else if (draft.reviewSlot != null) {
      await _markReview(learner.id, draft.trickId, draft.reviewSlot!, now);
    }
  }

  Future<void> _mastery(
    Learner learner,
    AttemptDraft draft,
    String attemptId,
    DateTime now,
  ) async {
    final previous = await store.mastery(learner.id, draft.trickId);
    final history = (await store.attempts(learner.id))
        .where(
          (attempt) =>
              attempt.trickId == draft.trickId &&
              attempt.mode == 'final' &&
              attempt.id != attemptId,
        )
        .map((attempt) => attempt.correct)
        .toList();
    final score = scoreFinals(
      history,
      latestCorrect: draft.correct,
      previousConsecutive: previous?.consecutive ?? 0,
    );
    final became = score.mastered && (previous == null || !previous.mastered);
    await store.saveMastery(
      Mastery(
        learnerId: learner.id,
        trickId: draft.trickId,
        rate: score.rate,
        mastered: score.mastered,
        masteredAt: score.mastered
            ? (previous?.masteredAt ?? now)
            : previous?.masteredAt,
        masteredOn: score.mastered
            ? (previous?.masteredOn ?? clock.today)
            : previous?.masteredOn,
        consecutive: score.consecutive,
        review3Done: previous?.review3Done ?? false,
        review14Done: previous?.review14Done ?? false,
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    if (draft.reviewSlot != null) {
      await _markReview(learner.id, draft.trickId, draft.reviewSlot!, now);
    }
    if (became) {
      final trick = catalog.byId(draft.trickId);
      await store.saveCertificate(
        Certificate(
          id: newId(),
          learnerId: learner.id,
          kind: 'trick',
          trickId: draft.trickId,
          speedRoundId: null,
          title: copy.masteredTitle(
            trick == null
                ? copy.pick('一个技巧', 'a trick')
                : localizeTrick(trick, copy).title,
          ),
          issuedAt: now,
        ),
      );
    }
  }

  Future<void> _markReview(
    String learnerId,
    String trickId,
    int slot,
    DateTime now,
  ) async {
    final current = await store.mastery(learnerId, trickId);
    if (current == null) return;
    await store.saveMastery(
      Mastery(
        learnerId: current.learnerId,
        trickId: current.trickId,
        rate: current.rate,
        mastered: current.mastered,
        masteredAt: current.masteredAt,
        masteredOn: current.masteredOn,
        consecutive: current.consecutive,
        review3Done: slot == 3 ? true : current.review3Done,
        review14Done: slot == 14 ? true : current.review14Done,
        createdAt: current.createdAt,
        updatedAt: now,
      ),
    );
  }

  Future<void> finishRound(String learnerId) async {
    final learner = learnerById(learnerId);
    if (learner == null) return;
    final rolled = completeStreak(
      count: learner.streakCount,
      lastDate: learner.lastPracticeDate,
      skipWeek: learner.streakSkipWeek,
      skipUsed: learner.streakSkipUsed,
      today: clock.today,
      thisWeek: clock.week,
    );
    if (rolled.changed) {
      await store.saveLearner(
        learner.copyWith(
          streakCount: rolled.count,
          lastPracticeDate: rolled.lastDate,
          clearLastDate: rolled.lastDate == null,
          streakSkipWeek: rolled.skipWeek,
          streakSkipUsed: rolled.skipUsed,
          clearNotice: true,
          updatedAt: clock.now().toUtc(),
        ),
      );
      learners = childMode
          ? [learnerById(learnerId) ?? learner]
          : await store.readLearners();
      if (childMode) {
        final fresh = await store.readLearners();
        if (fresh.isNotEmpty) _replace(fresh.first);
      }
    }
    await store.clearSnapshot(learnerId);
    if (activeLearnerId == learnerId) snapshot = null;
    if (!childMode) learners = await store.readLearners();
    notifyListeners();
  }

  Future<void> finishSpeed(SpeedView view, {required int durationMs}) async {
    final now = clock.now().toUtc();
    final round = SpeedRound(
      id: newId(),
      learnerId: view.learnerId,
      operation: view.config.operation,
      digitMin: view.config.digitMin,
      digitMax: view.config.digitMax,
      limitMode: view.config.limitMode,
      limitValue: view.config.limitValue,
      correctCount: view.correct,
      durationMs: durationMs,
      createdAt: now,
    );
    await store.saveSpeed(round);
    if (view.correct > view.previousBest && view.correct > 0) {
      await store.saveCertificate(
        Certificate(
          id: newId(),
          learnerId: view.learnerId,
          kind: 'speed',
          trickId: null,
          speedRoundId: round.id,
          title: copy.speedBestTitle(view.correct),
          issuedAt: now,
        ),
      );
    }
    await finishRound(view.learnerId);
  }

  Future<void> bookRoundMisses(List<RoundMiss> misses) async {
    final learner = active;
    if (learner == null || misses.isEmpty) return;
    final existing = await store.wrongs(learner.id);
    final seen = {
      for (final item in existing)
        '${item.prompt}\u0000${item.userAnswer}\u0000${item.correctAnswer}',
    };
    final now = clock.now().toUtc();
    for (final miss in misses) {
      final key =
          '${miss.prompt}\u0000${miss.userAnswer}\u0000${miss.correctAnswer}';
      if (!seen.add(key)) continue;
      await store.putWrong(
        WrongItem(
          id: newId(),
          learnerId: learner.id,
          attemptId: '',
          trickId: miss.trickId,
          prompt: miss.prompt,
          userAnswer: miss.userAnswer,
          correctAnswer: miss.correctAnswer,
          failedStep: miss.failedStep,
          stepsJson: jsonEncode(miss.steps.map((step) => step.toJson()).toList()),
          reviewedOk: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future<int> bestFor(String learnerId, SpeedConfig config) async {
    final rounds = await store.speeds(learnerId);
    return personalBest(
      rounds
          .where(
            (round) =>
                round.operation == config.operation &&
                round.limitMode == config.limitMode &&
                round.limitValue == config.limitValue,
          )
          .map((round) => round.correctCount),
    );
  }

  void clearBanner() {
    banner = null;
    notifyListeners();
  }

  @override
  void dispose() {
    voice.dispose();
    super.dispose();
  }
}

class PracticeController extends ChangeNotifier {
  PracticeController(this.app);

  final AppController app;
  PracticeView? view;
  Timer? _timer;
  DateTime? _clockAt;
  int _bankedMs = 0;
  bool reportDue = false;

  Future<void> startLearn(String trickId) async {
    final learner = app.active;
    final trick = app.catalog.byId(trickId);
    if (learner == null || trick == null || !trick.ready) return;
    if (_gradeRank(trick.grade) > _gradeRank(learner.grade) && app.childMode) {
      return;
    }
    final mastery = await app.store.mastery(learner.id, trickId);
    final items = buildLearnRound(
      trickId: trickId,
      standard: (mastery?.consecutive ?? 0) >= 10,
      reviews: await app.dueReviews(learner.id, trickId),
      rng: Random(),
    );
    view = PracticeView.start(
      learnerId: learner.id,
      trickId: trickId,
      items: items,
    );
    _beginClock();
    await _persist();
    notifyListeners();
    final prompt = view?.current?.prompt;
    if (prompt != null && app.settings.readAloudEnabled) {
      unawaited(app.voice.speak(prompt));
    }
  }

  Future<void> startScanDrill(List<Problem> items) async {
    final learner = app.active;
    if (learner == null || items.isEmpty) return;
    view = PracticeView.start(
      learnerId: learner.id,
      trickId: items.first.trickId,
      items: items,
    );
    _beginClock();
    await _persist();
    notifyListeners();
  }

  Future<void> startRepair(WrongItem item) async {
    if (!app.errorTrainingOpen) return;
    final learner = app.active;
    if (learner == null) return;
    final steps = (jsonDecode(item.stepsJson) as List)
        .map((entry) => StepAsk.fromJson(entry as Map<String, dynamic>))
        .toList();
    final problem = Problem(
      trickId: item.trickId,
      prompt: item.prompt,
      finalAnswer: item.correctAnswer,
      steps: steps.isEmpty
          ? [StepAsk(1, 'What is ${item.prompt}?', item.correctAnswer)]
          : steps,
      guided: true,
      review: true,
      repairWrongId: item.id,
    );
    view = PracticeView.start(
      learnerId: learner.id,
      trickId: item.trickId,
      items: [problem],
      repairWrongId: item.id,
    );
    _beginClock();
    await _persist();
    notifyListeners();
  }

  Future<void> resume(SessionSnapshot snapshot) async {
    final decoded = jsonDecode(snapshot.payload) as Map<String, dynamic>;
    view = PracticeView.fromJson(decoded);
    _resumeClock();
    if (view!.repairWrongId != null && !app.errorTrainingOpen) {
      view = null;
      notifyListeners();
      return;
    }
    if (view!.pending != null) {
      view = practiceAdvance(view!).view;
      if (view!.phase == 'done') {
        _captureElapsed();
        view = view!.copy(elapsedMs: _bankedMs);
        reportDue = true;
        await app.finishRound(view!.learnerId);
      } else {
        await _persist();
      }
    }
    notifyListeners();
  }

  void key(String key) {
    final current = view;
    if (current == null) return;
    final effect = practiceKey(current, key);
    if (identical(effect.view, current)) return;
    view = effect.view;
    notifyListeners();
    _persist();
  }

  Future<void> submit() async {
    final current = view;
    if (current == null) return;
    final effect = practiceSubmit(current);
    view = effect.view;
    notifyListeners();
    if (identical(effect.view, current) && effect.attempt == null) return;
    try {
      if (effect.attempt != null) {
        await app.recordAttempt(effect.attempt!);
      }
      await _persist();
    } catch (_) {
      view = current;
      app.banner = app.copy.couldNotSave;
      app.notifyListeners();
      notifyListeners();
      return;
    }
    if (effect.view.mark == 'correct' && app.settings.soundEnabled) {
      unawaited(app.voice.cue('correct'));
    } else if (effect.view.mark == 'wrong' && app.settings.soundEnabled) {
      unawaited(app.voice.cue('wrong'));
    }
    if (!effect.wait) return;
    _timer?.cancel();
    _timer = Timer(correctAdvance, () async {
      final latest = view;
      if (latest == null) return;
      view = practiceAdvance(latest).view;
      if (view!.phase == 'done') {
        _captureElapsed();
        view = view!.copy(elapsedMs: _bankedMs);
        reportDue = true;
        await app.finishRound(view!.learnerId);
      } else {
        await _persist();
        if (app.settings.readAloudEnabled) {
          final prompt = view!.current?.prompt;
          if (prompt != null) unawaited(app.voice.speak(prompt));
        }
      }
      notifyListeners();
    });
  }

  Future<void> _persist() async {
    final current = view;
    if (current == null || current.phase == 'done') return;
    await app.rememberSnapshot(
      SessionSnapshot(
        learnerId: current.learnerId,
        module: 'learn',
        trickId: current.trickId,
        localDate: app.clock.today,
        payload: jsonEncode(current.toJson()),
        updatedAt: app.clock.now().toUtc(),
      ),
    );
  }

  Future<void> leave() async {
    _timer?.cancel();
    _captureElapsed();
    if (view != null) view = view!.copy(elapsedMs: _bankedMs);
    await _persist();
  }

  void _beginClock() {
    _bankedMs = 0;
    _clockAt = DateTime.now();
    reportDue = false;
  }

  void _resumeClock() {
    _bankedMs = view?.elapsedMs ?? 0;
    _clockAt = DateTime.now();
  }

  void _captureElapsed() {
    if (_clockAt == null) return;
    _bankedMs += DateTime.now().difference(_clockAt!).inMilliseconds;
    _clockAt = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SpeedController extends ChangeNotifier {
  SpeedController(this.app);

  final AppController app;
  SpeedView? view;
  Timer? _flash;
  Timer? _ticker;
  DateTime? _clockAt;
  int _bankedMs = 0;
  bool reportDue = false;
  final Random _rng = Random();

  Future<void> start(SpeedConfig config) async {
    final learner = app.active;
    if (learner == null) return;
    final counted = config.limitMode == 'time'
        ? config.copyWith(limitMode: 'count', limitValue: 10)
        : config;
    final items = buildSpeedQueue(counted, learner.grade, _rng);
    final best = await app.bestFor(learner.id, counted);
    view = SpeedView.start(
      learnerId: learner.id,
      grade: learner.grade,
      config: counted,
      items: items,
      previousBest: best,
    );
    _bankedMs = 0;
    _clockAt = DateTime.now();
    reportDue = false;
    await _persist();
    _ensureTicker();
    notifyListeners();
    if (app.settings.readAloudEnabled) {
      final prompt = view?.current?.prompt;
      if (prompt != null) unawaited(app.voice.speak(prompt));
    }
  }

  Future<void> resume(SessionSnapshot snapshot) async {
    view = SpeedView.fromJson(
      jsonDecode(snapshot.payload) as Map<String, dynamic>,
    );
    _bankedMs = view?.elapsedMs ?? 0;
    _clockAt = view != null && !view!.paused && !view!.done
        ? DateTime.now()
        : null;
    if (view != null && !view!.paused && !view!.done) _ensureTicker();
    notifyListeners();
  }

  void key(String value) {
    final current = view;
    if (current == null) return;
    final effect = speedKey(current, value);
    if (identical(effect.view, current)) return;
    view = effect.view;
    notifyListeners();
  }

  Future<void> submit() async {
    final current = view;
    if (current == null) return;
    final effect = speedSubmit(current);
    view = effect.view;
    notifyListeners();
    if (effect.attempt == null) return;
    try {
      await app.recordAttempt(effect.attempt!);
      await _persist();
    } catch (_) {
      view = current;
      app.banner = app.copy.couldNotSave;
      app.notifyListeners();
      notifyListeners();
      return;
    }
    if (app.settings.soundEnabled) {
      unawaited(app.voice.cue(effect.attempt!.correct ? 'correct' : 'wrong'));
    }
    if (effect.finished) {
      await _finish();
      return;
    }
    _flash?.cancel();
    _flash = Timer(correctAdvance, () async {
      final latest = view;
      if (latest == null) return;
      view = speedReveal(latest, _rng).view;
      await _persist();
      notifyListeners();
      if (app.settings.readAloudEnabled) {
        final prompt = view?.current?.prompt;
        if (prompt != null) unawaited(app.voice.speak(prompt));
      }
    });
  }

  void pause() {
    final current = view;
    if (current == null || current.done) return;
    _captureElapsed();
    view = speedPause(current, paused: true).view.copy(elapsedMs: _bankedMs);
    _ticker?.cancel();
    _ticker = null;
    _clockAt = null;
    notifyListeners();
    _persist();
    unawaited(app.voice.stop());
  }

  void resumeRunning() {
    final current = view;
    if (current == null || current.done) return;
    view = speedPause(current, paused: false).view;
    _clockAt = DateTime.now();
    _ensureTicker();
    notifyListeners();
    _persist();
  }

  void onBackground(Duration away) {
    if (away > const Duration(seconds: 3)) pause();
  }

  void _ensureTicker() {
    if (_ticker != null && _ticker!.isActive) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _tick(),
    );
  }

  void _tick() {
    final current = view;
    if (current == null || current.paused || current.done) return;
    final elapsed = _elapsedNow();
    if (elapsed == current.elapsedMs) return;
    view = current.copy(elapsedMs: elapsed);
    notifyListeners();
  }

  void _captureElapsed() {
    if (_clockAt != null) {
      _bankedMs += DateTime.now().difference(_clockAt!).inMilliseconds;
      _clockAt = null;
    }
  }

  int _elapsedNow() {
    final extra = _clockAt == null
        ? 0
        : DateTime.now().difference(_clockAt!).inMilliseconds;
    return _bankedMs + extra;
  }

  Future<void> _finish() async {
    final current = view;
    if (current == null) return;
    _ticker?.cancel();
    _ticker = null;
    _flash?.cancel();
    _captureElapsed();
    view = current.copy(done: true, elapsedMs: _bankedMs);
    reportDue = true;
    notifyListeners();
    try {
      await app.finishSpeed(view!, durationMs: _bankedMs);
    } catch (_) {
      app.banner = app.copy.couldNotSave;
      app.notifyListeners();
    }
    notifyListeners();
  }

  Future<void> leave() async {
    _captureElapsed();
    if (view != null) view = view!.copy(elapsedMs: _bankedMs);
    await _persist();
  }

  Future<void> _persist() async {
    final current = view;
    if (current == null || current.done) return;
    await app.rememberSnapshot(
      SessionSnapshot(
        learnerId: current.learnerId,
        module: 'speed',
        trickId: null,
        localDate: app.clock.today,
        payload: jsonEncode(current.toJson()),
        updatedAt: app.clock.now().toUtc(),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _flash?.cancel();
    super.dispose();
  }
}

int _gradeRank(String grade) {
  final index = grades.indexOf(canonicalGrade(grade));
  return index < 0 ? 0 : index;
}

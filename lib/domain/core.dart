import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Product rules that do not depend on Flutter or Hive.

const correctAdvance = Duration(milliseconds: 90);

const grades = ['K', '1', '2', '3', '4', '5'];

String gradeLabel(String grade) {
  switch (grade) {
    case 'K':
      return 'Kindergarten';
    case '1':
      return 'Grade 1';
    case '2':
      return 'Grade 2';
    case '3':
      return 'Grade 3';
    case '4':
      return 'Grade 4';
    case '5':
      return 'Grade 5';
    default:
      return 'Grade';
  }
}

String operationLabel(String operation) {
  switch (operation) {
    case 'addition':
      return 'Addition';
    case 'subtraction':
      return 'Subtraction';
    case 'multiplication':
      return 'Multiplication';
    case 'division':
      return 'Division';
    case 'percent':
      return 'Percent';
    case 'mixed':
      return 'Mixed';
    default:
      return operation;
  }
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String formatYmd(DateTime value) {
  final d = dateOnly(value);
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime parseYmd(String value) {
  final parts = value.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime _civil(String ymd) {
  final parts = ymd.split('-');
  return DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String addDays(String ymd, int days) {
  final next = _civil(ymd).add(Duration(days: days));
  final month = next.month.toString().padLeft(2, '0');
  final day = next.day.toString().padLeft(2, '0');
  return '${next.year}-$month-$day';
}

int dayGap(String from, String to) =>
    _civil(to).difference(_civil(from)).inDays;

String weekKey(DateTime value) {
  final day = dateOnly(value);
  return formatYmd(day.subtract(Duration(days: day.weekday - 1)));
}

String formatNum(num value) {
  final number = value.toDouble();
  if ((number - number.round()).abs() < 1e-9) {
    return number.round().toString();
  }
  final fixed = number.toStringAsFixed(2);
  if (fixed.endsWith('0')) return number.toStringAsFixed(1);
  return fixed;
}

bool sameNumber(String user, String expected) {
  final left = double.tryParse(user.trim());
  final right = double.tryParse(expected.trim());
  if (left == null || right == null) return false;
  return (left - right).abs() < 0.001;
}

/// Returns the next draft, the same draft for delete-on-empty, or null when
/// the key must be ignored.
String? applyKey(String current, String key) {
  if (key == 'delete') {
    if (current.isEmpty) return current;
    return current.substring(0, current.length - 1);
  }
  if (current.length >= 8) return null;
  if (key == '.') {
    if (current.contains('.')) return null;
    if (current.isEmpty) return '0.';
    return '$current.';
  }
  if (key.length != 1 || key.codeUnitAt(0) < 48 || key.codeUnitAt(0) > 57) {
    return null;
  }
  if (current == '0') return key;
  return current + key;
}

class MasteryScore {
  const MasteryScore({
    required this.rate,
    required this.window,
    required this.correctInWindow,
    required this.mastered,
    required this.consecutive,
  });

  final double rate;
  final int window;
  final int correctInWindow;
  final bool mastered;
  final int consecutive;
}

MasteryScore scoreFinals(
  List<bool> previousOldestFirst, {
  required bool latestCorrect,
  required int previousConsecutive,
}) {
  final all = [...previousOldestFirst, latestCorrect];
  final window = all.length > 20 ? all.sublist(all.length - 20) : all;
  final correct = window.where((item) => item).length;
  final rate = window.isEmpty ? 0.0 : correct / window.length;
  return MasteryScore(
    rate: rate,
    window: window.length,
    correctInWindow: correct,
    mastered: window.length >= 20 && rate + 1e-9 >= 0.90,
    consecutive: latestCorrect ? previousConsecutive + 1 : 0,
  );
}

class StreakState {
  const StreakState({
    required this.count,
    required this.lastDate,
    required this.skipWeek,
    required this.skipUsed,
    required this.notice,
    required this.changed,
  });

  final int count;
  final String? lastDate;
  final String? skipWeek;
  final bool skipUsed;
  final String? notice;
  final bool changed;
}

StreakState rollStreak({
  required int count,
  required String? lastDate,
  required String? skipWeek,
  required bool skipUsed,
  required String? notice,
  required String today,
  required String thisWeek,
}) {
  var used = skipWeek == thisWeek && skipUsed;
  if (lastDate == null || lastDate == today) {
    if (skipWeek == thisWeek) {
      return StreakState(
        count: count,
        lastDate: lastDate,
        skipWeek: skipWeek,
        skipUsed: used,
        notice: notice,
        changed: false,
      );
    }
    return StreakState(
      count: count,
      lastDate: lastDate,
      skipWeek: thisWeek,
      skipUsed: false,
      notice: notice,
      changed: true,
    );
  }
  final gap = dayGap(lastDate, today);
  if (gap <= 1) {
    return StreakState(
      count: count,
      lastDate: lastDate,
      skipWeek: thisWeek,
      skipUsed: used && skipWeek == thisWeek,
      notice: notice,
      changed: skipWeek != thisWeek,
    );
  }
  if (gap == 2 && !used) {
    return StreakState(
      count: count,
      lastDate: addDays(today, -1),
      skipWeek: thisWeek,
      skipUsed: true,
      notice: 'held',
      changed: true,
    );
  }
  return StreakState(
    count: 0,
    lastDate: null,
    skipWeek: thisWeek,
    skipUsed: false,
    notice: count == 0 ? null : 'reset',
    changed: true,
  );
}

StreakState completeStreak({
  required int count,
  required String? lastDate,
  required String? skipWeek,
  required bool skipUsed,
  required String today,
  required String thisWeek,
}) {
  if (lastDate == today) {
    return StreakState(
      count: count,
      lastDate: lastDate,
      skipWeek: thisWeek,
      skipUsed: skipUsed,
      notice: null,
      changed: false,
    );
  }
  return StreakState(
    count: lastDate == null ? 1 : count + 1,
    lastDate: today,
    skipWeek: thisWeek,
    skipUsed: skipWeek == thisWeek && skipUsed,
    notice: null,
    changed: true,
  );
}

bool reviewIsDue({
  required String? masteredOn,
  required int offsetDays,
  required String today,
  required bool done,
}) {
  if (done || masteredOn == null) return false;
  return today.compareTo(addDays(masteredOn, offsetDays)) >= 0;
}

class SpeedConfig {
  const SpeedConfig({
    required this.operation,
    required this.digitMin,
    required this.digitMax,
    required this.limitMode,
    required this.limitValue,
  });

  final String operation;
  final int digitMin;
  final int digitMax;
  final String limitMode;
  final int limitValue;

  SpeedConfig copyWith({
    String? operation,
    int? digitMin,
    int? digitMax,
    String? limitMode,
    int? limitValue,
  }) {
    return SpeedConfig(
      operation: operation ?? this.operation,
      digitMin: digitMin ?? this.digitMin,
      digitMax: digitMax ?? this.digitMax,
      limitMode: limitMode ?? this.limitMode,
      limitValue: limitValue ?? this.limitValue,
    );
  }

  String get limitLabel {
    if (limitMode == 'count') {
      return limitValue == 1 ? '1 problem' : '$limitValue problems';
    }
    if (limitValue % 60 == 0) {
      final minutes = limitValue ~/ 60;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }
    return '$limitValue seconds';
  }

  String get summary => '$limitLabel · ${operationLabel(operation)}';

  Map<String, Object> toJson() => {
    'operation': operation,
    'digitMin': digitMin,
    'digitMax': digitMax,
    'limitMode': limitMode,
    'limitValue': limitValue,
  };

  factory SpeedConfig.fromJson(Map<String, dynamic> json) {
    return SpeedConfig(
      operation: json['operation'] as String? ?? 'addition',
      digitMin: json['digitMin'] as int? ?? 1,
      digitMax: json['digitMax'] as int? ?? 1,
      limitMode: json['limitMode'] as String? ?? 'count',
      limitValue: json['limitValue'] as int? ?? 10,
    );
  }
}

SpeedConfig speedDefault(String grade) {
  switch (grade) {
    case 'K':
      return const SpeedConfig(
        operation: 'addition',
        digitMin: 1,
        digitMax: 1,
        limitMode: 'count',
        limitValue: 10,
      );
    case '1':
      return const SpeedConfig(
        operation: 'mixed',
        digitMin: 1,
        digitMax: 2,
        limitMode: 'count',
        limitValue: 10,
      );
    case '2':
      return const SpeedConfig(
        operation: 'mixed',
        digitMin: 2,
        digitMax: 2,
        limitMode: 'time',
        limitValue: 120,
      );
    case '3':
      return const SpeedConfig(
        operation: 'mixed',
        digitMin: 1,
        digitMax: 1,
        limitMode: 'time',
        limitValue: 180,
      );
    case '4':
      return const SpeedConfig(
        operation: 'mixed',
        digitMin: 2,
        digitMax: 2,
        limitMode: 'time',
        limitValue: 180,
      );
    default:
      return const SpeedConfig(
        operation: 'percent',
        digitMin: 2,
        digitMax: 3,
        limitMode: 'time',
        limitValue: 180,
      );
  }
}

class FactDrill {
  const FactDrill({
    required this.title,
    required this.sample,
    required this.config,
  });

  final String title;
  final String sample;
  final SpeedConfig config;
}

SpeedConfig dailyPractice(String grade) {
  return speedDefault(grade).copyWith(limitMode: 'count', limitValue: 10);
}

List<FactDrill> factDrills(String grade) {
  SpeedConfig drill(
    String operation, {
    int digits = 1,
    String mode = 'count',
    int limit = 10,
  }) {
    return SpeedConfig(
      operation: operation,
      digitMin: 1,
      digitMax: digits,
      limitMode: mode,
      limitValue: limit,
    );
  }

  switch (grade) {
    case 'K':
      return [
        FactDrill(
          title: 'Adding within 10',
          sample: '4 + 3 = ?',
          config: drill('addition'),
        ),
        FactDrill(
          title: 'Subtracting within 10',
          sample: '10 − 6 = ?',
          config: drill('subtraction'),
        ),
        FactDrill(
          title: 'Mixed within 10',
          sample: '8 + 2 = ?',
          config: drill('mixed'),
        ),
      ];
    case '1':
      return [
        FactDrill(
          title: 'Adding within 20',
          sample: '9 + 6 = ?',
          config: drill('addition', digits: 2),
        ),
        FactDrill(
          title: 'Subtracting within 20',
          sample: '15 − 7 = ?',
          config: drill('subtraction', digits: 2),
        ),
        FactDrill(
          title: 'Mixed within 20',
          sample: '13 − 5 = ?',
          config: drill('mixed', digits: 2),
        ),
      ];
    case '2':
      return [
        FactDrill(
          title: 'Adding within 100',
          sample: '27 + 16 = ?',
          config: drill('addition', digits: 2, mode: 'time', limit: 120),
        ),
        FactDrill(
          title: 'Subtracting within 100',
          sample: '53 − 18 = ?',
          config: drill('subtraction', digits: 2, mode: 'time', limit: 120),
        ),
        FactDrill(
          title: 'Mixed within 100',
          sample: '40 + 25 = ?',
          config: drill('mixed', digits: 2, mode: 'time', limit: 120),
        ),
      ];
    case '3':
      return [
        FactDrill(
          title: 'Multiplication facts',
          sample: '6 × 5 = ?',
          config: drill('multiplication', mode: 'time', limit: 180),
        ),
        FactDrill(
          title: 'Division facts',
          sample: '35 ÷ 5 = ?',
          config: drill('division', mode: 'time', limit: 180),
        ),
        FactDrill(
          title: 'Mixed facts',
          sample: '8 × 4 = ?',
          config: drill('mixed', mode: 'time', limit: 180),
        ),
      ];
    case '4':
      return [
        FactDrill(
          title: 'Two-digit multiplication',
          sample: '26 × 4 = ?',
          config: drill('multiplication', digits: 2, mode: 'time', limit: 180),
        ),
        FactDrill(
          title: 'Division',
          sample: '72 ÷ 8 = ?',
          config: drill('division', digits: 2, mode: 'time', limit: 180),
        ),
        FactDrill(
          title: 'Mixed within 100',
          sample: '36 + 48 = ?',
          config: drill('mixed', digits: 2, mode: 'time', limit: 180),
        ),
      ];
    default:
      return [
        FactDrill(
          title: '10%, 5%, and 1%',
          sample: '10% of \$80 = ?',
          config: drill('percent', digits: 3, mode: 'time', limit: 180),
        ),
        FactDrill(
          title: 'Mixed review',
          sample: '5% of \$40 = ?',
          config: drill('percent', digits: 3, mode: 'time', limit: 180),
        ),
      ];
  }
}

int personalBest(Iterable<int> scores) {
  var best = 0;
  for (final score in scores) {
    if (score > best) best = score;
  }
  return best;
}

class WeeklyReport {
  const WeeklyReport({
    required this.days,
    required this.problems,
    required this.correct,
    required this.newMastered,
    required this.mostMissedStep,
    required this.missedStepCount,
    required this.correctPerMinute,
  });

  final int days;
  final int problems;
  final int correct;
  final int newMastered;
  final int? mostMissedStep;
  final int missedStepCount;
  final double? correctPerMinute;

  double get accuracy => problems == 0 ? 0 : correct / problems;
}

WeeklyReport buildWeeklyReport({
  required String today,
  required List<Attempt> attempts,
  required List<SpeedRound> rounds,
  required List<Mastery> mastery,
}) {
  final start = addDays(today, -6);
  bool inside(DateTime created) {
    final day = formatYmd(created.toLocal());
    return day.compareTo(start) >= 0 && day.compareTo(today) <= 0;
  }

  final recentAttempts = attempts.where((item) => inside(item.createdAt));
  final recentRounds = rounds.where((item) => inside(item.createdAt));
  final days = <String>{};
  var problems = 0;
  var correct = 0;
  final misses = <int, int>{};
  for (final attempt in recentAttempts) {
    days.add(formatYmd(attempt.createdAt.toLocal()));
    problems += 1;
    if (attempt.correct) correct += 1;
    final step = attempt.failedStep;
    if (!attempt.correct && step != null) {
      misses[step] = (misses[step] ?? 0) + 1;
    }
  }
  for (final round in recentRounds) {
    days.add(formatYmd(round.createdAt.toLocal()));
  }
  int? topStep;
  var topCount = 0;
  for (final entry in misses.entries) {
    if (entry.value > topCount ||
        (entry.value == topCount && (topStep == null || entry.key < topStep))) {
      topStep = entry.key;
      topCount = entry.value;
    }
  }
  var newMastered = 0;
  for (final item in mastery) {
    final on = item.masteredOn;
    if (item.mastered &&
        on != null &&
        on.compareTo(start) >= 0 &&
        on.compareTo(today) <= 0) {
      newMastered += 1;
    }
  }
  var durationMs = 0;
  var speedCorrect = 0;
  for (final round in recentRounds) {
    if (round.durationMs <= 0) continue;
    durationMs += round.durationMs;
    speedCorrect += round.correctCount;
  }
  return WeeklyReport(
    days: days.length,
    problems: problems,
    correct: correct,
    newMastered: newMastered,
    mostMissedStep: topCount == 0 ? null : topStep,
    missedStepCount: topCount,
    correctPerMinute: durationMs == 0
        ? null
        : speedCorrect / (durationMs / 60000),
  );
}

String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

final _accountEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? accountEmailError(String email) {
  if (!_accountEmail.hasMatch(email.trim().toLowerCase())) {
    return 'Enter an email address.';
  }
  return null;
}

String? newPasswordError(String password, String again) {
  if (password.length < 8) return 'Use at least 8 characters.';
  if (password != again) return 'Those passwords do not match.';
  return null;
}

/// Wrong-problem practice stays closed until a parent is signed in and subscribed.
bool errorTrainingAllowed({required bool signedIn, required bool subscribed}) {
  return signedIn && subscribed;
}

String newSalt([Random? random]) {
  final source = random ?? Random.secure();
  return List.generate(
    16,
    (_) => source.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

bool looksLikePin(String value) => RegExp(r'^\d{4}$').hasMatch(value);

class PinVerdict {
  const PinVerdict({
    required this.ok,
    required this.locked,
    required this.waitSeconds,
    required this.settings,
  });

  final bool ok;
  final bool locked;
  final int waitSeconds;
  final DeviceSettings settings;
}

PinVerdict checkPin(DeviceSettings settings, String pin, DateTime now) {
  final lockedUntil = settings.pinLockedUntil;
  if (lockedUntil != null && now.isBefore(lockedUntil)) {
    return PinVerdict(
      ok: false,
      locked: true,
      waitSeconds: lockedUntil.difference(now).inSeconds + 1,
      settings: settings,
    );
  }
  if (settings.parentPinHash == null || settings.pinSalt == null) {
    return PinVerdict(
      ok: false,
      locked: false,
      waitSeconds: 0,
      settings: settings,
    );
  }
  if (hashPin(pin, settings.pinSalt!) == settings.parentPinHash) {
    return PinVerdict(
      ok: true,
      locked: false,
      waitSeconds: 0,
      settings: settings.copyWith(pinFailCount: 0, clearLock: true),
    );
  }
  final fails = settings.pinFailCount + 1;
  if (fails >= 4) {
    return PinVerdict(
      ok: false,
      locked: true,
      waitSeconds: 60,
      settings: settings.copyWith(
        pinFailCount: 0,
        pinLockedUntil: now.add(const Duration(seconds: 60)),
      ),
    );
  }
  return PinVerdict(
    ok: false,
    locked: false,
    waitSeconds: 0,
    settings: settings.copyWith(pinFailCount: fails, clearLock: true),
  );
}

String newId([Random? random]) {
  final source = random ?? Random();
  final time = DateTime.now().microsecondsSinceEpoch;
  return '$time-${source.nextInt(1 << 32)}';
}

class Learner {
  const Learner({
    required this.id,
    required this.displayName,
    required this.grade,
    required this.isGuest,
    required this.streakCount,
    required this.lastPracticeDate,
    required this.streakSkipWeek,
    required this.streakSkipUsed,
    required this.favorites,
    required this.seenLessons,
    required this.streakNotice,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String grade;
  final bool isGuest;
  final int streakCount;
  final String? lastPracticeDate;
  final String? streakSkipWeek;
  final bool streakSkipUsed;
  final List<String> favorites;
  final Map<String, String> seenLessons;
  final String? streakNotice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Learner copyWith({
    String? displayName,
    String? grade,
    bool? isGuest,
    int? streakCount,
    String? lastPracticeDate,
    bool clearLastDate = false,
    String? streakSkipWeek,
    bool? streakSkipUsed,
    List<String>? favorites,
    Map<String, String>? seenLessons,
    String? streakNotice,
    bool clearNotice = false,
    DateTime? updatedAt,
  }) {
    return Learner(
      id: id,
      displayName: displayName ?? this.displayName,
      grade: grade ?? this.grade,
      isGuest: isGuest ?? this.isGuest,
      streakCount: streakCount ?? this.streakCount,
      lastPracticeDate:
          clearLastDate ? null : (lastPracticeDate ?? this.lastPracticeDate),
      streakSkipWeek: streakSkipWeek ?? this.streakSkipWeek,
      streakSkipUsed: streakSkipUsed ?? this.streakSkipUsed,
      favorites: favorites ?? this.favorites,
      seenLessons: seenLessons ?? this.seenLessons,
      streakNotice: clearNotice ? null : (streakNotice ?? this.streakNotice),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DeviceSettings {
  const DeviceSettings({
    required this.parentPinHash,
    required this.pinSalt,
    required this.telemetryEnabled,
    required this.activeLearnerId,
    required this.extraLearnersUnlocked,
    required this.printUnlocked,
    required this.accountEmail,
    required this.accountPasswordHash,
    required this.accountSalt,
    required this.signedIn,
    required this.subscriptionActive,
    required this.themeMode,
    required this.textScale,
    required this.soundEnabled,
    required this.readAloudEnabled,
    required this.pinFailCount,
    required this.pinLockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? parentPinHash;
  final String? pinSalt;
  final bool telemetryEnabled;
  final String? activeLearnerId;
  final bool extraLearnersUnlocked;
  final bool printUnlocked;
  final String? accountEmail;
  final String? accountPasswordHash;
  final String? accountSalt;
  final bool signedIn;
  final bool subscriptionActive;
  final String themeMode;
  final String textScale;
  final bool soundEnabled;
  final bool readAloudEnabled;
  final int pinFailCount;
  final DateTime? pinLockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get textScaleFactor {
    switch (textScale) {
      case 'small':
        return 0.9;
      case 'large':
        return 1.15;
      default:
        return 1;
    }
  }

  factory DeviceSettings.fresh([DateTime? now]) {
    final time = now ?? DateTime.now().toUtc();
    return DeviceSettings(
      parentPinHash: null,
      pinSalt: null,
      telemetryEnabled: false,
      activeLearnerId: null,
      extraLearnersUnlocked: true,
      printUnlocked: true,
      accountEmail: null,
      accountPasswordHash: null,
      accountSalt: null,
      signedIn: false,
      subscriptionActive: false,
      themeMode: 'system',
      textScale: 'medium',
      soundEnabled: true,
      readAloudEnabled: false,
      pinFailCount: 0,
      pinLockedUntil: null,
      createdAt: time,
      updatedAt: time,
    );
  }

  DeviceSettings copyWith({
    String? parentPinHash,
    String? pinSalt,
    bool? telemetryEnabled,
    String? activeLearnerId,
    bool clearActive = false,
    bool? extraLearnersUnlocked,
    bool? printUnlocked,
    String? accountEmail,
    String? accountPasswordHash,
    String? accountSalt,
    bool? signedIn,
    bool? subscriptionActive,
    String? themeMode,
    String? textScale,
    bool? soundEnabled,
    bool? readAloudEnabled,
    int? pinFailCount,
    DateTime? pinLockedUntil,
    bool clearLock = false,
    bool clearPin = false,
    DateTime? updatedAt,
  }) {
    return DeviceSettings(
      parentPinHash: clearPin ? null : (parentPinHash ?? this.parentPinHash),
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      activeLearnerId:
          clearActive ? null : (activeLearnerId ?? this.activeLearnerId),
      extraLearnersUnlocked:
          extraLearnersUnlocked ?? this.extraLearnersUnlocked,
      printUnlocked: printUnlocked ?? this.printUnlocked,
      accountEmail: accountEmail ?? this.accountEmail,
      accountPasswordHash: accountPasswordHash ?? this.accountPasswordHash,
      accountSalt: accountSalt ?? this.accountSalt,
      signedIn: signedIn ?? this.signedIn,
      subscriptionActive: subscriptionActive ?? this.subscriptionActive,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      readAloudEnabled: readAloudEnabled ?? this.readAloudEnabled,
      pinFailCount: pinFailCount ?? this.pinFailCount,
      pinLockedUntil: clearLock ? null : (pinLockedUntil ?? this.pinLockedUntil),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Attempt {
  const Attempt({
    required this.id,
    required this.learnerId,
    required this.trickId,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.correct,
    required this.failedStep,
    required this.mode,
    required this.createdAt,
  });

  final String id;
  final String learnerId;
  final String trickId;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final bool correct;
  final int? failedStep;
  final String mode;
  final DateTime createdAt;
}

class WrongItem {
  const WrongItem({
    required this.id,
    required this.learnerId,
    required this.attemptId,
    required this.trickId,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.failedStep,
    required this.stepsJson,
    required this.reviewedOk,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String learnerId;
  final String attemptId;
  final String trickId;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final int? failedStep;
  final String stepsJson;
  final bool reviewedOk;
  final DateTime createdAt;
  final DateTime updatedAt;

  WrongItem copyWith({bool? reviewedOk, DateTime? updatedAt}) {
    return WrongItem(
      id: id,
      learnerId: learnerId,
      attemptId: attemptId,
      trickId: trickId,
      prompt: prompt,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      failedStep: failedStep,
      stepsJson: stepsJson,
      reviewedOk: reviewedOk ?? this.reviewedOk,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SpeedRound {
  const SpeedRound({
    required this.id,
    required this.learnerId,
    required this.operation,
    required this.digitMin,
    required this.digitMax,
    required this.limitMode,
    required this.limitValue,
    required this.correctCount,
    required this.durationMs,
    required this.createdAt,
  });

  final String id;
  final String learnerId;
  final String operation;
  final int digitMin;
  final int digitMax;
  final String limitMode;
  final int limitValue;
  final int correctCount;
  final int durationMs;
  final DateTime createdAt;
}

class Mastery {
  const Mastery({
    required this.learnerId,
    required this.trickId,
    required this.rate,
    required this.mastered,
    required this.masteredAt,
    required this.masteredOn,
    required this.consecutive,
    required this.review3Done,
    required this.review14Done,
    required this.createdAt,
    required this.updatedAt,
  });

  final String learnerId;
  final String trickId;
  final double rate;
  final bool mastered;
  final DateTime? masteredAt;
  final String? masteredOn;
  final int consecutive;
  final bool review3Done;
  final bool review14Done;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get key => '$learnerId:$trickId';
}

class Assignment {
  const Assignment({
    required this.id,
    required this.learnerId,
    required this.localDate,
    required this.kind,
    required this.trickId,
    required this.speedConfig,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String learnerId;
  final String localDate;
  final String kind;
  final String? trickId;
  final String? speedConfig;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpeedConfig? get parsedSpeed {
    if (speedConfig == null || speedConfig!.isEmpty) return null;
    return SpeedConfig.fromJson(
      jsonDecode(speedConfig!) as Map<String, dynamic>,
    );
  }
}

class Certificate {
  const Certificate({
    required this.id,
    required this.learnerId,
    required this.kind,
    required this.trickId,
    required this.speedRoundId,
    required this.title,
    required this.issuedAt,
  });

  final String id;
  final String learnerId;
  final String kind;
  final String? trickId;
  final String? speedRoundId;
  final String title;
  final DateTime issuedAt;
}

class SessionSnapshot {
  const SessionSnapshot({
    required this.learnerId,
    required this.module,
    required this.trickId,
    required this.localDate,
    required this.payload,
    required this.updatedAt,
  });

  final String learnerId;
  final String module;
  final String? trickId;
  final String localDate;
  final String payload;
  final DateTime updatedAt;
}

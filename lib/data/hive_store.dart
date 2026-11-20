import 'package:hive_flutter/hive_flutter.dart';

import '../domain/core.dart';
import '../domain/store.dart';

class HiveAppStore implements AppStore {
  static bool _hiveReady = false;
  bool _ready = false;
  bool childMode = false;
  String? sessionLearnerId;

  late Box<Map> _learners;
  late Box<Map> _settings;
  late Box<Map> _attempts;
  late Box<Map> _wrongs;
  late Box<Map> _speeds;
  late Box<Map> _mastery;
  late Box<Map> _assignments;
  late Box<Map> _snapshots;
  late Box<Map> _certificates;

  @override
  void setSession({required bool childMode, String? learnerId}) {
    this.childMode = childMode;
    sessionLearnerId = learnerId;
  }

  void _check(String learnerId) {
    if (childMode && sessionLearnerId != learnerId) {
      throw StateError('This session cannot open that learner.');
    }
  }

  void _adult() {
    if (childMode) throw StateError('A parent needs to open this.');
  }

  @override
  Future<void> init({String? path}) async {
    if (_ready) return;
    if (!_hiveReady) {
      if (path == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(path);
      }
      _hiveReady = true;
    }
    _learners = await Hive.openBox<Map>('learners');
    _settings = await Hive.openBox<Map>('device_settings');
    _attempts = await Hive.openBox<Map>('attempts');
    _wrongs = await Hive.openBox<Map>('wrong_items');
    _speeds = await Hive.openBox<Map>('speed_rounds');
    _mastery = await Hive.openBox<Map>('mastery');
    _assignments = await Hive.openBox<Map>('assignments');
    _snapshots = await Hive.openBox<Map>('session_snapshots');
    _certificates = await Hive.openBox<Map>('certificates');
    if (_settings.get('device') == null) {
      final fresh = DeviceSettings.fresh();
      await _settings.put('device', _settingsToMap(fresh));
    }
    _ready = true;
  }

  @override
  Future<DeviceSettings> readSettings() async {
    final raw = _settings.get('device');
    if (raw == null) return DeviceSettings.fresh();
    return _settingsFromMap(raw);
  }

  @override
  Future<void> saveSettings(DeviceSettings settings) async {
    await _settings.put('device', _settingsToMap(settings));
  }

  @override
  Future<void> wipe() async {
    _adult();
    await _attempts.clear();
    await _wrongs.clear();
    await _speeds.clear();
    await _mastery.clear();
    await _assignments.clear();
    await _snapshots.clear();
    await _certificates.clear();
    await _learners.clear();
    await _settings.delete('device');
    await _settings.put('device', _settingsToMap(DeviceSettings.fresh()));
  }

  @override
  Future<List<Learner>> readLearners() async {
    final all = _learners.values.map(_learnerFromMap).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (!childMode) return all;
    return all.where((learner) => learner.id == sessionLearnerId).toList();
  }

  @override
  Future<void> saveLearner(Learner learner) async {
    _check(learner.id);
    await _learners.put(learner.id, _learnerToMap(learner));
  }

  @override
  Future<void> deleteLearner(String id) async {
    _adult();
    await _deleteWhere(_attempts, (map) => map['learnerId'] == id);
    await _deleteWhere(_wrongs, (map) => map['learnerId'] == id);
    await _deleteWhere(_speeds, (map) => map['learnerId'] == id);
    await _deleteWhere(_mastery, (map) => map['learnerId'] == id);
    await _deleteWhere(_assignments, (map) => map['learnerId'] == id);
    await _snapshots.delete(id);
    await _deleteWhere(_certificates, (map) => map['learnerId'] == id);
    await _learners.delete(id);
    final settings = await readSettings();
    if (settings.activeLearnerId == id) {
      await saveSettings(settings.copyWith(clearActive: true, updatedAt: DateTime.now().toUtc()));
    }
  }

  Future<void> _deleteWhere(Box<Map> box, bool Function(Map map) test) async {
    final keys = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null && test(value)) keys.add(key);
    }
    await box.deleteAll(keys);
  }

  @override
  Future<void> putAttempt(Attempt attempt) async {
    _check(attempt.learnerId);
    if (_attempts.containsKey(attempt.id)) return;
    await _attempts.put(attempt.id, {
      'id': attempt.id,
      'learnerId': attempt.learnerId,
      'trickId': attempt.trickId,
      'prompt': attempt.prompt,
      'userAnswer': attempt.userAnswer,
      'correctAnswer': attempt.correctAnswer,
      'correct': attempt.correct,
      'failedStep': attempt.failedStep,
      'mode': attempt.mode,
      'createdAt': attempt.createdAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Attempt>> attempts(String learnerId) async {
    _check(learnerId);
    return _attempts.values
        .where((map) => map['learnerId'] == learnerId)
        .map(_attemptFromMap)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<void> putWrong(WrongItem item) async {
    _check(item.learnerId);
    if (_wrongs.containsKey(item.id)) return;
    await _wrongs.put(item.id, _wrongToMap(item));
  }

  @override
  Future<void> saveWrong(WrongItem item) async {
    _check(item.learnerId);
    await _wrongs.put(item.id, _wrongToMap(item));
  }

  @override
  Future<List<WrongItem>> wrongs(String learnerId) async {
    _check(learnerId);
    return _wrongs.values
        .where((map) => map['learnerId'] == learnerId)
        .map(_wrongFromMap)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> saveMastery(Mastery mastery) async {
    _check(mastery.learnerId);
    await _mastery.put(mastery.key, {
      'learnerId': mastery.learnerId,
      'trickId': mastery.trickId,
      'rate': mastery.rate,
      'mastered': mastery.mastered,
      'masteredAt': mastery.masteredAt?.toUtc().toIso8601String(),
      'masteredOn': mastery.masteredOn,
      'consecutive': mastery.consecutive,
      'review3Done': mastery.review3Done,
      'review14Done': mastery.review14Done,
      'createdAt': mastery.createdAt.toUtc().toIso8601String(),
      'updatedAt': mastery.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<Mastery?> mastery(String learnerId, String trickId) async {
    _check(learnerId);
    final raw = _mastery.get('$learnerId:$trickId');
    if (raw == null) return null;
    return _masteryFromMap(raw);
  }

  @override
  Future<List<Mastery>> masteries(String learnerId) async {
    _check(learnerId);
    return _mastery.values
        .where((map) => map['learnerId'] == learnerId)
        .map(_masteryFromMap)
        .toList();
  }

  @override
  Future<void> saveSpeed(SpeedRound round) async {
    _check(round.learnerId);
    await _speeds.put(round.id, {
      'id': round.id,
      'learnerId': round.learnerId,
      'operation': round.operation,
      'digitMin': round.digitMin,
      'digitMax': round.digitMax,
      'limitMode': round.limitMode,
      'limitValue': round.limitValue,
      'correctCount': round.correctCount,
      'durationMs': round.durationMs,
      'createdAt': round.createdAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<SpeedRound>> speeds(String learnerId) async {
    _check(learnerId);
    return _speeds.values
        .where((map) => map['learnerId'] == learnerId)
        .map(
          (map) => SpeedRound(
            id: map['id'] as String,
            learnerId: map['learnerId'] as String,
            operation: map['operation'] as String,
            digitMin: map['digitMin'] as int,
            digitMax: map['digitMax'] as int,
            limitMode: map['limitMode'] as String,
            limitValue: map['limitValue'] as int,
            correctCount: map['correctCount'] as int,
            durationMs: map['durationMs'] as int,
            createdAt: DateTime.parse(map['createdAt'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveAssignment(Assignment assignment) async {
    _check(assignment.learnerId);
    if (assignment.status == 'open') {
      final stale = <dynamic>[];
      for (final key in _assignments.keys) {
        final map = _assignments.get(key);
        if (map == null) continue;
        if (map['learnerId'] == assignment.learnerId &&
            map['localDate'] == assignment.localDate &&
            map['status'] == 'open' &&
            map['id'] != assignment.id) {
          stale.add(key);
        }
      }
      for (final key in stale) {
        final map = Map<String, dynamic>.from(_assignments.get(key)!);
        map['status'] = 'replaced';
        map['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        await _assignments.put(key, map);
      }
    }
    await _assignments.put(assignment.id, {
      'id': assignment.id,
      'learnerId': assignment.learnerId,
      'localDate': assignment.localDate,
      'kind': assignment.kind,
      'trickId': assignment.trickId,
      'speedConfig': assignment.speedConfig,
      'status': assignment.status,
      'createdAt': assignment.createdAt.toUtc().toIso8601String(),
      'updatedAt': assignment.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<Assignment?> openAssignment(String learnerId, String localDate) async {
    _check(learnerId);
    for (final map in _assignments.values) {
      if (map['learnerId'] == learnerId &&
          map['localDate'] == localDate &&
          map['status'] == 'open') {
        return _assignmentFromMap(map);
      }
    }
    return null;
  }

  @override
  Future<void> saveSnapshot(SessionSnapshot snapshot) async {
    _check(snapshot.learnerId);
    await _snapshots.put(snapshot.learnerId, {
      'learnerId': snapshot.learnerId,
      'module': snapshot.module,
      'trickId': snapshot.trickId,
      'localDate': snapshot.localDate,
      'payload': snapshot.payload,
      'updatedAt': snapshot.updatedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<SessionSnapshot?> snapshot(String learnerId) async {
    _check(learnerId);
    final map = _snapshots.get(learnerId);
    if (map == null) return null;
    return SessionSnapshot(
      learnerId: map['learnerId'] as String,
      module: map['module'] as String,
      trickId: map['trickId'] as String?,
      localDate: map['localDate'] as String,
      payload: map['payload'] as String,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  Future<void> clearSnapshot(String learnerId) async {
    _check(learnerId);
    await _snapshots.delete(learnerId);
  }

  @override
  Future<void> saveCertificate(Certificate certificate) async {
    _check(certificate.learnerId);
    await _certificates.put(certificate.id, {
      'id': certificate.id,
      'learnerId': certificate.learnerId,
      'kind': certificate.kind,
      'trickId': certificate.trickId,
      'speedRoundId': certificate.speedRoundId,
      'title': certificate.title,
      'issuedAt': certificate.issuedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<Certificate>> certificates(String learnerId) async {
    _check(learnerId);
    return _certificates.values
        .where((map) => map['learnerId'] == learnerId)
        .map(
          (map) => Certificate(
            id: map['id'] as String,
            learnerId: map['learnerId'] as String,
            kind: map['kind'] as String,
            trickId: map['trickId'] as String?,
            speedRoundId: map['speedRoundId'] as String?,
            title: map['title'] as String,
            issuedAt: DateTime.parse(map['issuedAt'] as String),
          ),
        )
        .toList();
  }
}

Map<String, dynamic> _learnerToMap(Learner learner) => {
  'id': learner.id,
  'displayName': learner.displayName,
  'grade': learner.grade,
  'isGuest': learner.isGuest,
  'streakCount': learner.streakCount,
  'lastPracticeDate': learner.lastPracticeDate,
  'streakSkipWeek': learner.streakSkipWeek,
  'streakSkipUsed': learner.streakSkipUsed,
  'favorites': learner.favorites,
  'seenLessons': learner.seenLessons.entries
      .map((entry) => '${entry.key}|${entry.value}')
      .toList(),
  'streakNotice': learner.streakNotice,
  'createdAt': learner.createdAt.toUtc().toIso8601String(),
  'updatedAt': learner.updatedAt.toUtc().toIso8601String(),
};

Learner _learnerFromMap(Map map) {
  final seen = <String, String>{};
  for (final item in (map['seenLessons'] as List?) ?? const []) {
    final text = item.toString();
    final split = text.split('|');
    if (split.length == 2) seen[split[0]] = split[1];
  }
  return Learner(
    id: map['id'] as String,
    displayName: map['displayName'] as String? ?? 'Learner',
    grade: map['grade'] as String? ?? '1',
    isGuest: map['isGuest'] as bool? ?? false,
    streakCount: map['streakCount'] as int? ?? 0,
    lastPracticeDate: map['lastPracticeDate'] as String?,
    streakSkipWeek: map['streakSkipWeek'] as String?,
    streakSkipUsed: map['streakSkipUsed'] as bool? ?? false,
    favorites: ((map['favorites'] as List?) ?? const []).cast<String>(),
    seenLessons: seen,
    streakNotice: map['streakNotice'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );
}

Map<String, dynamic> _settingsToMap(DeviceSettings settings) => {
  'id': 'device',
  'parentPinHash': settings.parentPinHash,
  'pinSalt': settings.pinSalt,
  'telemetryEnabled': settings.telemetryEnabled,
  'activeLearnerId': settings.activeLearnerId,
  'extraLearnersUnlocked': settings.extraLearnersUnlocked,
  'printUnlocked': settings.printUnlocked,
  'accountEmail': settings.accountEmail,
  'accountPasswordHash': settings.accountPasswordHash,
  'accountSalt': settings.accountSalt,
  'signedIn': settings.signedIn,
  'subscriptionActive': settings.subscriptionActive,
  'themeMode': settings.themeMode,
  'textScale': settings.textScale,
  'soundEnabled': settings.soundEnabled,
  'readAloudEnabled': settings.readAloudEnabled,
  'pinFailCount': settings.pinFailCount,
  'pinLockedUntil': settings.pinLockedUntil?.toUtc().toIso8601String(),
  'createdAt': settings.createdAt.toUtc().toIso8601String(),
  'updatedAt': settings.updatedAt.toUtc().toIso8601String(),
};

DeviceSettings _settingsFromMap(Map map) => DeviceSettings(
  parentPinHash: map['parentPinHash'] as String?,
  pinSalt: map['pinSalt'] as String?,
  telemetryEnabled: map['telemetryEnabled'] as bool? ?? false,
  activeLearnerId: map['activeLearnerId'] as String?,
  extraLearnersUnlocked: map['extraLearnersUnlocked'] as bool? ?? true,
  printUnlocked: map['printUnlocked'] as bool? ?? true,
  accountEmail: map['accountEmail'] as String?,
  accountPasswordHash: map['accountPasswordHash'] as String?,
  accountSalt: map['accountSalt'] as String?,
  signedIn: map['signedIn'] as bool? ?? false,
  subscriptionActive: map['subscriptionActive'] as bool? ?? false,
  themeMode: map['themeMode'] as String? ?? 'system',
  textScale: map['textScale'] as String? ?? 'medium',
  soundEnabled: map['soundEnabled'] as bool? ?? true,
  readAloudEnabled: map['readAloudEnabled'] as bool? ?? false,
  pinFailCount: map['pinFailCount'] as int? ?? 0,
  pinLockedUntil: map['pinLockedUntil'] == null
      ? null
      : DateTime.parse(map['pinLockedUntil'] as String),
  createdAt: DateTime.parse(map['createdAt'] as String),
  updatedAt: DateTime.parse(map['updatedAt'] as String),
);

Attempt _attemptFromMap(Map map) => Attempt(
  id: map['id'] as String,
  learnerId: map['learnerId'] as String,
  trickId: map['trickId'] as String,
  prompt: map['prompt'] as String,
  userAnswer: map['userAnswer'] as String,
  correctAnswer: map['correctAnswer'] as String,
  correct: map['correct'] as bool,
  failedStep: map['failedStep'] as int?,
  mode: map['mode'] as String,
  createdAt: DateTime.parse(map['createdAt'] as String),
);

Map<String, dynamic> _wrongToMap(WrongItem item) => {
  'id': item.id,
  'learnerId': item.learnerId,
  'attemptId': item.attemptId,
  'trickId': item.trickId,
  'prompt': item.prompt,
  'userAnswer': item.userAnswer,
  'correctAnswer': item.correctAnswer,
  'failedStep': item.failedStep,
  'stepsJson': item.stepsJson,
  'reviewedOk': item.reviewedOk,
  'createdAt': item.createdAt.toUtc().toIso8601String(),
  'updatedAt': item.updatedAt.toUtc().toIso8601String(),
};

WrongItem _wrongFromMap(Map map) => WrongItem(
  id: map['id'] as String,
  learnerId: map['learnerId'] as String,
  attemptId: map['attemptId'] as String,
  trickId: map['trickId'] as String,
  prompt: map['prompt'] as String,
  userAnswer: map['userAnswer'] as String,
  correctAnswer: map['correctAnswer'] as String,
  failedStep: map['failedStep'] as int?,
  stepsJson: map['stepsJson'] as String? ?? '[]',
  reviewedOk: map['reviewedOk'] as bool? ?? false,
  createdAt: DateTime.parse(map['createdAt'] as String),
  updatedAt: DateTime.parse(map['updatedAt'] as String),
);

Mastery _masteryFromMap(Map map) => Mastery(
  learnerId: map['learnerId'] as String,
  trickId: map['trickId'] as String,
  rate: (map['rate'] as num?)?.toDouble() ?? 0,
  mastered: map['mastered'] as bool? ?? false,
  masteredAt: map['masteredAt'] == null
      ? null
      : DateTime.parse(map['masteredAt'] as String),
  masteredOn: map['masteredOn'] as String?,
  consecutive: map['consecutive'] as int? ?? 0,
  review3Done: map['review3Done'] as bool? ?? false,
  review14Done: map['review14Done'] as bool? ?? false,
  createdAt: DateTime.parse(map['createdAt'] as String),
  updatedAt: DateTime.parse(map['updatedAt'] as String),
);

Assignment _assignmentFromMap(Map map) => Assignment(
  id: map['id'] as String,
  learnerId: map['learnerId'] as String,
  localDate: map['localDate'] as String,
  kind: map['kind'] as String,
  trickId: map['trickId'] as String?,
  speedConfig: map['speedConfig'] as String?,
  status: map['status'] as String,
  createdAt: DateTime.parse(map['createdAt'] as String),
  updatedAt: DateTime.parse(map['updatedAt'] as String),
);

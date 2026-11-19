import 'dart:math';

import 'core.dart';
import 'engine.dart';

class PracticeView {
  const PracticeView({
    required this.learnerId,
    required this.trickId,
    required this.items,
    required this.index,
    required this.stepIndex,
    required this.draft,
    required this.phase,
    required this.locked,
    required this.mark,
    required this.correctCount,
    required this.failedStep,
    required this.dirtyMiss,
    required this.firstWrongInput,
    required this.shownWrongFinal,
    required this.pending,
    required this.missedNotes,
    required this.repairWrongId,
    required this.active,
  });

  final String learnerId;
  final String trickId;
  final List<Problem> items;
  final int index;
  final int stepIndex;
  final String draft;
  final String phase;
  final bool locked;
  final String? mark;
  final int correctCount;
  final int? failedStep;
  final bool dirtyMiss;
  final String? firstWrongInput;
  final String? shownWrongFinal;
  final String? pending;
  final List<String> missedNotes;
  final String? repairWrongId;
  final bool active;

  Problem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  bool get showingSteps =>
      phase == 'guided' || phase == 'locate' || phase == 'review';

  factory PracticeView.start({
    required String learnerId,
    required String trickId,
    required List<Problem> items,
    String? repairWrongId,
  }) {
    final first = items.first;
    final phase = first.review
        ? 'review'
        : (first.guided ? 'guided' : 'final');
    return PracticeView(
      learnerId: learnerId,
      trickId: trickId,
      items: items,
      index: 0,
      stepIndex: 0,
      draft: '',
      phase: phase,
      locked: false,
      mark: null,
      correctCount: 0,
      failedStep: null,
      dirtyMiss: false,
      firstWrongInput: null,
      shownWrongFinal: null,
      pending: null,
      missedNotes: const [],
      repairWrongId: repairWrongId,
      active: true,
    );
  }

  PracticeView copy({
    int? index,
    int? stepIndex,
    String? draft,
    String? phase,
    bool? locked,
    String? mark,
    bool clearMark = false,
    int? correctCount,
    int? failedStep,
    bool clearFailed = false,
    bool? dirtyMiss,
    String? firstWrongInput,
    bool clearFirst = false,
    String? shownWrongFinal,
    bool clearShown = false,
    String? pending,
    bool clearPending = false,
    List<String>? missedNotes,
    bool? active,
  }) {
    return PracticeView(
      learnerId: learnerId,
      trickId: trickId,
      items: items,
      index: index ?? this.index,
      stepIndex: stepIndex ?? this.stepIndex,
      draft: draft ?? this.draft,
      phase: phase ?? this.phase,
      locked: locked ?? this.locked,
      mark: clearMark ? null : (mark ?? this.mark),
      correctCount: correctCount ?? this.correctCount,
      failedStep: clearFailed ? null : (failedStep ?? this.failedStep),
      dirtyMiss: dirtyMiss ?? this.dirtyMiss,
      firstWrongInput:
          clearFirst ? null : (firstWrongInput ?? this.firstWrongInput),
      shownWrongFinal:
          clearShown ? null : (shownWrongFinal ?? this.shownWrongFinal),
      pending: clearPending ? null : (pending ?? this.pending),
      missedNotes: missedNotes ?? this.missedNotes,
      repairWrongId: repairWrongId,
      active: active ?? this.active,
    );
  }

  Map<String, Object?> toJson() => {
    'learnerId': learnerId,
    'trickId': trickId,
    'items': items.map((item) => item.toJson()).toList(),
    'index': index,
    'stepIndex': stepIndex,
    'draft': draft,
    'phase': phase,
    'locked': locked,
    'mark': mark,
    'correctCount': correctCount,
    'failedStep': failedStep,
    'dirtyMiss': dirtyMiss,
    'firstWrongInput': firstWrongInput,
    'shownWrongFinal': shownWrongFinal,
    'pending': pending,
    'missedNotes': missedNotes,
    'repairWrongId': repairWrongId,
    'active': active,
  };

  factory PracticeView.fromJson(Map<String, dynamic> json) {
    return PracticeView(
      learnerId: json['learnerId'] as String,
      trickId: json['trickId'] as String,
      items: (json['items'] as List)
          .map((item) => Problem.fromJson(item as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int,
      stepIndex: json['stepIndex'] as int,
      draft: json['draft'] as String? ?? '',
      phase: json['phase'] as String,
      locked: json['locked'] as bool? ?? false,
      mark: json['mark'] as String?,
      correctCount: json['correctCount'] as int? ?? 0,
      failedStep: json['failedStep'] as int?,
      dirtyMiss: json['dirtyMiss'] as bool? ?? false,
      firstWrongInput: json['firstWrongInput'] as String?,
      shownWrongFinal: json['shownWrongFinal'] as String?,
      pending: json['pending'] as String?,
      missedNotes: (json['missedNotes'] as List?)?.cast<String>() ?? const [],
      repairWrongId: json['repairWrongId'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class AttemptDraft {
  const AttemptDraft({
    required this.trickId,
    required this.prompt,
    required this.userAnswer,
    required this.correctAnswer,
    required this.correct,
    required this.failedStep,
    required this.mode,
    required this.steps,
    required this.reviewSlot,
    required this.repairWrongId,
  });

  final String trickId;
  final String prompt;
  final String userAnswer;
  final String correctAnswer;
  final bool correct;
  final int? failedStep;
  final String mode;
  final List<StepAsk> steps;
  final int? reviewSlot;
  final String? repairWrongId;
}

class PracticeEffect {
  const PracticeEffect(this.view, {this.attempt, this.wait = false});

  final PracticeView view;
  final AttemptDraft? attempt;
  final bool wait;
}

PracticeEffect practiceKey(PracticeView view, String key) {
  if (!view.active || view.locked || view.phase == 'done' || view.current == null) {
    return PracticeEffect(view);
  }
  final next = applyKey(view.draft, key);
  if (next == null) return PracticeEffect(view);
  return PracticeEffect(view.copy(draft: next, clearMark: true));
}

PracticeEffect practiceSubmit(PracticeView view) {
  if (!view.active || view.locked || view.phase == 'done' || view.current == null) {
    return PracticeEffect(view);
  }
  if (view.draft.trim().isEmpty) return PracticeEffect(view);
  final item = view.current!;
  if (view.showingSteps) {
    final step = item.steps[view.stepIndex];
    if (!sameNumber(view.draft, step.answer)) {
      return PracticeEffect(
        view.copy(
          mark: 'wrong',
          failedStep: view.failedStep ?? step.number,
          dirtyMiss: true,
          firstWrongInput: view.firstWrongInput ?? view.draft,
        ),
      );
    }
    final lastStep = view.stepIndex + 1 >= item.steps.length;
    if (!lastStep) {
      return PracticeEffect(
        view.copy(mark: 'correct', locked: true, pending: 'step'),
        wait: true,
      );
    }
    final correct = view.shownWrongFinal == null && !view.dirtyMiss;
    return PracticeEffect(
      _afterItem(view, item, correct: correct),
      attempt: _draft(view, item, correct: correct),
      wait: true,
    );
  }
  if (!sameNumber(view.draft, item.finalAnswer)) {
    return PracticeEffect(
      view.copy(
        phase: 'locate',
        stepIndex: 0,
        draft: '',
        mark: 'wrong',
        shownWrongFinal: view.draft,
        firstWrongInput: view.draft,
        locked: false,
      ),
    );
  }
  return PracticeEffect(
    _afterItem(view, item, correct: true),
    attempt: _draft(view, item, correct: true, mode: 'final'),
    wait: true,
  );
}

PracticeEffect practiceAdvance(PracticeView view) {
  if (view.pending == null) return PracticeEffect(view);
  if (view.pending == 'step') {
    return PracticeEffect(
      view.copy(
        stepIndex: view.stepIndex + 1,
        draft: '',
        clearMark: true,
        locked: false,
        clearPending: true,
      ),
    );
  }
  final next = view.index + 1;
  if (next >= view.items.length) {
    return PracticeEffect(
      view.copy(
        index: next,
        phase: 'done',
        draft: '',
        clearMark: true,
        locked: false,
        clearPending: true,
      ),
    );
  }
  final item = view.items[next];
  final phase = item.review ? 'review' : (item.guided ? 'guided' : 'final');
  return PracticeEffect(
    view.copy(
      index: next,
      stepIndex: 0,
      draft: '',
      phase: phase,
      clearMark: true,
      locked: false,
      clearFailed: true,
      dirtyMiss: false,
      clearShown: true,
      clearPending: true,
      clearFirst: true,
    ),
  );
}

PracticeView _afterItem(PracticeView view, Problem item, {required bool correct}) {
  final notes = [...view.missedNotes];
  if (!correct) {
    final step = view.failedStep;
    notes.add(
      step == null
          ? 'Final answer on ${item.prompt}'
          : 'Step $step on ${item.prompt}',
    );
  }
  return view.copy(
    mark: correct ? 'correct' : null,
    clearMark: !correct,
    locked: true,
    pending: 'item',
    correctCount: view.correctCount + (correct ? 1 : 0),
    missedNotes: notes,
  );
}

AttemptDraft _draft(
  PracticeView view,
  Problem item, {
  required bool correct,
  String? mode,
}) {
  final resolvedMode = mode ??
      (view.phase == 'final' || view.phase == 'locate' ? 'final' : 'guided');
  return AttemptDraft(
    trickId: item.trickId,
    prompt: item.prompt,
    userAnswer: correct
        ? item.finalAnswer
        : (view.firstWrongInput ?? view.shownWrongFinal ?? view.draft),
    correctAnswer: item.finalAnswer,
    correct: correct,
    failedStep: correct ? null : view.failedStep,
    mode: resolvedMode,
    steps: item.steps,
    reviewSlot: item.reviewSlot,
    repairWrongId: view.repairWrongId,
  );
}

class SpeedView {
  const SpeedView({
    required this.learnerId,
    required this.grade,
    required this.config,
    required this.items,
    required this.index,
    required this.draft,
    required this.correct,
    required this.answered,
    required this.remainingMs,
    required this.elapsedMs,
    required this.paused,
    required this.done,
    required this.locked,
    required this.mark,
    required this.active,
    required this.previousBest,
  });

  final String learnerId;
  final String grade;
  final SpeedConfig config;
  final List<Problem> items;
  final int index;
  final String draft;
  final int correct;
  final int answered;
  final int remainingMs;
  final int elapsedMs;
  final bool paused;
  final bool done;
  final bool locked;
  final String? mark;
  final bool active;
  final int previousBest;

  Problem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  int get problemsLeft =>
      config.limitMode == 'count' ? max(0, config.limitValue - answered) : 0;

  bool get warning => config.limitMode == 'time'
      ? remainingMs <= 30000
      : problemsLeft <= 3 && problemsLeft > 0;

  factory SpeedView.start({
    required String learnerId,
    required String grade,
    required SpeedConfig config,
    required List<Problem> items,
    required int previousBest,
  }) {
    return SpeedView(
      learnerId: learnerId,
      grade: grade,
      config: config,
      items: items,
      index: 0,
      draft: '',
      correct: 0,
      answered: 0,
      remainingMs: config.limitMode == 'time' ? config.limitValue * 1000 : 0,
      elapsedMs: 0,
      paused: false,
      done: false,
      locked: false,
      mark: null,
      active: true,
      previousBest: previousBest,
    );
  }

  SpeedView copy({
    List<Problem>? items,
    int? index,
    String? draft,
    int? correct,
    int? answered,
    int? remainingMs,
    int? elapsedMs,
    bool? paused,
    bool? done,
    bool? locked,
    String? mark,
    bool clearMark = false,
    bool? active,
  }) {
    return SpeedView(
      learnerId: learnerId,
      grade: grade,
      config: config,
      items: items ?? this.items,
      index: index ?? this.index,
      draft: draft ?? this.draft,
      correct: correct ?? this.correct,
      answered: answered ?? this.answered,
      remainingMs: remainingMs ?? this.remainingMs,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      paused: paused ?? this.paused,
      done: done ?? this.done,
      locked: locked ?? this.locked,
      mark: clearMark ? null : (mark ?? this.mark),
      active: active ?? this.active,
      previousBest: previousBest,
    );
  }

  Map<String, Object?> toJson() => {
    'learnerId': learnerId,
    'grade': grade,
    'config': config.toJson(),
    'items': items.map((item) => item.toJson()).toList(),
    'index': index,
    'draft': draft,
    'correct': correct,
    'answered': answered,
    'remainingMs': remainingMs,
    'elapsedMs': elapsedMs,
    'paused': paused,
    'done': done,
    'locked': locked,
    'mark': mark,
    'active': active,
    'previousBest': previousBest,
  };

  factory SpeedView.fromJson(Map<String, dynamic> json) {
    return SpeedView(
      learnerId: json['learnerId'] as String,
      grade: json['grade'] as String,
      config: SpeedConfig.fromJson(json['config'] as Map<String, dynamic>),
      items: (json['items'] as List)
          .map((item) => Problem.fromJson(item as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int? ?? 0,
      draft: json['draft'] as String? ?? '',
      correct: json['correct'] as int? ?? 0,
      answered: json['answered'] as int? ?? 0,
      remainingMs: json['remainingMs'] as int? ?? 0,
      elapsedMs: json['elapsedMs'] as int? ?? 0,
      paused: json['paused'] as bool? ?? false,
      done: json['done'] as bool? ?? false,
      locked: json['locked'] as bool? ?? false,
      mark: json['mark'] as String?,
      active: json['active'] as bool? ?? true,
      previousBest: json['previousBest'] as int? ?? 0,
    );
  }
}

class SpeedEffect {
  const SpeedEffect(this.view, {this.attempt, this.wait = false, this.finished = false});

  final SpeedView view;
  final AttemptDraft? attempt;
  final bool wait;
  final bool finished;
}

bool speedEnded(SpeedView view) {
  if (view.config.limitMode == 'count') {
    return view.answered >= view.config.limitValue;
  }
  return view.remainingMs <= 0;
}

SpeedEffect speedKey(SpeedView view, String key) {
  if (!view.active || view.locked || view.paused || view.done || view.current == null) {
    return SpeedEffect(view);
  }
  final next = applyKey(view.draft, key);
  if (next == null) return SpeedEffect(view);
  return SpeedEffect(view.copy(draft: next, clearMark: true));
}

SpeedEffect speedSubmit(SpeedView view) {
  if (!view.active || view.locked || view.paused || view.done || view.current == null) {
    return SpeedEffect(view);
  }
  if (view.draft.trim().isEmpty) return SpeedEffect(view);
  final item = view.current!;
  final correct = sameNumber(view.draft, item.finalAnswer);
  final answered = view.answered + 1;
  final next = view.copy(
    draft: '',
    correct: view.correct + (correct ? 1 : 0),
    answered: answered,
    mark: correct ? 'correct' : 'wrong',
    locked: true,
    index: view.index + 1,
  );
  final finished = speedEnded(next);
  return SpeedEffect(
    finished ? next.copy(done: true) : next,
    attempt: AttemptDraft(
      trickId: item.trickId,
      prompt: item.prompt,
      userAnswer: view.draft,
      correctAnswer: item.finalAnswer,
      correct: correct,
      failedStep: correct ? null : 1,
      mode: 'speed',
      steps: item.steps,
      reviewSlot: null,
      repairWrongId: null,
    ),
    wait: !finished,
    finished: finished,
  );
}

SpeedEffect speedTick(SpeedView view, int elapsedMs) {
  if (!view.active || view.paused || view.done || view.config.limitMode != 'time') {
    return SpeedEffect(view);
  }
  final remain = max(0, view.remainingMs - elapsedMs);
  final next = view.copy(
    remainingMs: remain,
    elapsedMs: view.elapsedMs + elapsedMs,
  );
  if (remain == 0) return SpeedEffect(next.copy(done: true), finished: true);
  return SpeedEffect(next);
}

SpeedEffect speedReveal(SpeedView view, Random rng) {
  if (!view.active || view.done) return SpeedEffect(view);
  var next = view.copy(locked: false, clearMark: true);
  if (next.current == null && next.config.limitMode == 'time') {
    final more = List.generate(
      10,
      (_) => nextSpeedProblem(next.config, next.grade, rng),
    );
    next = next.copy(items: [...next.items, ...more]);
  }
  return SpeedEffect(next);
}

SpeedEffect speedPause(SpeedView view, {required bool paused}) {
  if (!view.active || view.done) return SpeedEffect(view);
  return SpeedEffect(view.copy(paused: paused, clearMark: paused));
}

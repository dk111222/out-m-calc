import 'dart:math';

import 'core.dart';

class StepAsk {
  const StepAsk(this.number, this.ask, this.answer);

  final int number;
  final String ask;
  final String answer;

  Map<String, Object> toJson() => {'n': number, 'ask': ask, 'answer': answer};

  factory StepAsk.fromJson(Map<String, dynamic> json) => StepAsk(
    json['n'] as int,
    json['ask'] as String,
    json['answer'] as String,
  );
}

class Problem {
  const Problem({
    required this.trickId,
    required this.prompt,
    required this.finalAnswer,
    required this.steps,
    this.guided = false,
    this.review = false,
    this.reviewSlot,
    this.repairWrongId,
  });

  final String trickId;
  final String prompt;
  final String finalAnswer;
  final List<StepAsk> steps;
  final bool guided;
  final bool review;
  final int? reviewSlot;
  final String? repairWrongId;

  String get signature => '$trickId|$prompt';

  Problem copyWith({
    String? trickId,
    bool? guided,
    bool? review,
    int? reviewSlot,
    String? repairWrongId,
    bool clearRepair = false,
  }) {
    return Problem(
      trickId: trickId ?? this.trickId,
      prompt: prompt,
      finalAnswer: finalAnswer,
      steps: steps,
      guided: guided ?? this.guided,
      review: review ?? this.review,
      reviewSlot: reviewSlot ?? this.reviewSlot,
      repairWrongId: clearRepair ? null : (repairWrongId ?? this.repairWrongId),
    );
  }

  Map<String, Object?> toJson() => {
    'trickId': trickId,
    'prompt': prompt,
    'finalAnswer': finalAnswer,
    'guided': guided,
    'review': review,
    'reviewSlot': reviewSlot,
    'repairWrongId': repairWrongId,
    'steps': steps.map((step) => step.toJson()).toList(),
  };

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      trickId: json['trickId'] as String,
      prompt: json['prompt'] as String,
      finalAnswer: json['finalAnswer'] as String,
      guided: json['guided'] as bool? ?? false,
      review: json['review'] as bool? ?? false,
      reviewSlot: json['reviewSlot'] as int?,
      repairWrongId: json['repairWrongId'] as String?,
      steps: (json['steps'] as List)
          .map((item) => StepAsk.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

Problem pairsToTen(int n) {
  final gap = 10 - n;
  return Problem(
    trickId: 'k-pairs-10',
    prompt: '$n + ? = 10',
    finalAnswer: '$gap',
    steps: [
      StepAsk(1, 'How many more does $n need to make 10?', '$gap'),
      StepAsk(2, 'What is $n + $gap?', '10'),
    ],
  );
}

Problem makeTen(int a, int b, {String id = 'g1-make-10'}) {
  final need = 10 - a;
  final left = b - need;
  final sum = 10 + left;
  return Problem(
    trickId: id,
    prompt: '$a + $b',
    finalAnswer: '$sum',
    steps: [
      StepAsk(1, 'How many does $a need to make 10?', '$need'),
      StepAsk(2, 'After you take that from $b, what is left?', '$left'),
      StepAsk(3, 'What is 10 plus the leftover?', '$sum'),
    ],
  );
}

Problem nearHundredAdd(int a, int b) {
  final first = 100 - a;
  final second = 100 - b;
  final gaps = first + second;
  final sum = 200 - gaps;
  return Problem(
    trickId: 'g2-near-100',
    prompt: '$a + $b',
    finalAnswer: '$sum',
    steps: [
      StepAsk(1, 'How far is $a below 100?', '$first'),
      StepAsk(2, 'How far is $b below 100?', '$second'),
      StepAsk(3, 'What is the sum of those two gaps?', '$gaps'),
      StepAsk(4, 'What is 200 minus that sum?', '$sum'),
    ],
  );
}

Problem nearHundredSub(int minuend, int sub) {
  final gap = 100 - sub;
  final down = minuend - 100;
  final result = down + gap;
  return Problem(
    trickId: 'g2-sub-100',
    prompt: '$minuend − $sub',
    finalAnswer: '$result',
    steps: [
      StepAsk(1, 'How far is $sub below 100?', '$gap'),
      StepAsk(2, 'What is $minuend minus 100?', '$down'),
      StepAsk(3, 'Add the gap back. What is the result?', '$result'),
    ],
  );
}

Problem timesFive(int n) {
  final tens = n * 10;
  final half = tens ~/ 2;
  return Problem(
    trickId: 'g3-times-5',
    prompt: '$n × 5',
    finalAnswer: '$half',
    steps: [
      StepAsk(1, 'What is $n × 10?', '$tens'),
      StepAsk(2, 'What is half of that?', '$half'),
    ],
  );
}

Problem timesEleven(int n) {
  final a = n ~/ 10;
  final b = n % 10;
  final mid = a + b;
  final result = a * 100 + mid * 10 + b;
  return Problem(
    trickId: 'g3-times-11',
    prompt: '$n × 11',
    finalAnswer: '$result',
    steps: [
      StepAsk(1, 'What is $a + $b?', '$mid'),
      StepAsk(2, 'What number has $a, then $mid, then $b?', '$result'),
    ],
  );
}

Problem timesElevenCarry(int n) {
  final a = n ~/ 10;
  final b = n % 10;
  final sum = a + b;
  final mid = sum % 10;
  final result = (a + sum ~/ 10) * 100 + mid * 10 + b;
  return Problem(
    trickId: 'g4-times-11-carry',
    prompt: '$n × 11',
    finalAnswer: '$result',
    steps: [
      StepAsk(1, 'What is $a + $b?', '$sum'),
      StepAsk(2, 'What is the ones digit of that sum?', '$mid'),
      StepAsk(3, 'What is the whole product?', '$result'),
    ],
  );
}

Problem complements(int tens, int x, int y) {
  final a = tens * 10 + x;
  final b = tens * 10 + y;
  final front = tens * (tens + 1);
  final back = x * y;
  final result = front * 100 + back;
  return Problem(
    trickId: 'g4-complements',
    prompt: '$a × $b',
    finalAnswer: '$result',
    steps: [
      StepAsk(1, 'What is $x + $y?', '${x + y}'),
      StepAsk(2, 'What is $tens × ${tens + 1}?', '$front'),
      StepAsk(3, 'What is $x × $y?', '$back'),
      StepAsk(4, 'Join them. What is the product?', '$result'),
    ],
  );
}

Problem squareEndsFive(int tens) {
  final n = tens * 10 + 5;
  final front = tens * (tens + 1);
  final result = front * 100 + 25;
  return Problem(
    trickId: 'g4-square-5',
    prompt: '$n²',
    finalAnswer: '$result',
    steps: [
      StepAsk(1, 'What is $tens × ${tens + 1}?', '$front'),
      StepAsk(2, 'Write that in front of 25. What is the square?', '$result'),
    ],
  );
}

Problem divideByFive(int n) {
  final doubled = n * 2;
  final result = formatNum(doubled / 10);
  return Problem(
    trickId: 'g3-div-5',
    prompt: '$n ÷ 5',
    finalAnswer: result,
    steps: [
      StepAsk(1, 'What is $n × 2?', '$doubled'),
      StepAsk(2, 'Divide that by 10. What do you get?', result),
    ],
  );
}

Problem divideByTwentyFive(int n) {
  final quad = n * 4;
  final result = formatNum(quad / 100);
  return Problem(
    trickId: 'g4-div-25',
    prompt: '$n ÷ 25',
    finalAnswer: result,
    steps: [
      StepAsk(1, 'What is $n × 4?', '$quad'),
      StepAsk(2, 'Divide that by 100. What do you get?', result),
    ],
  );
}

Problem percentOf(int rate, int dollars) {
  if (rate == 10) {
    final part = formatNum(dollars / 10);
    return Problem(
      trickId: 'g5-percent-10',
      prompt: '10% of \$$dollars',
      finalAnswer: part,
      steps: [
        StepAsk(1, 'What number do you divide the price by?', '10'),
        StepAsk(2, 'What is $dollars ÷ 10?', part),
      ],
    );
  }
  if (rate == 5) {
    final ten = formatNum(dollars / 10);
    final half = formatNum(dollars / 20);
    return Problem(
      trickId: 'g5-percent-5',
      prompt: '5% of \$$dollars',
      finalAnswer: half,
      steps: [
        StepAsk(1, 'What is 10% of \$$dollars?', ten),
        StepAsk(2, 'What is half of that?', half),
      ],
    );
  }
  final part = formatNum(dollars / 100);
  return Problem(
    trickId: 'g5-percent-1',
    prompt: '1% of \$$dollars',
    finalAnswer: part,
    steps: [
      StepAsk(1, 'What number do you divide the price by?', '100'),
      StepAsk(2, 'What is $dollars ÷ 100?', part),
    ],
  );
}

Problem buildFixed(String trickId, Map<String, int> args) {
  switch (trickId) {
    case 'k-pairs-10':
      return pairsToTen(args['n']!);
    case 'g1-make-10':
      return makeTen(args['a']!, args['b']!);
    case 'g1-add-20':
      return makeTen(args['a']!, args['b']!, id: trickId);
    case 'g2-near-100':
      return nearHundredAdd(args['a']!, args['b']!);
    case 'g2-sub-100':
      return nearHundredSub(args['a']!, args['b']!);
    case 'g3-times-5':
      return timesFive(args['n']!);
    case 'g3-times-11':
      return timesEleven(args['n']!);
    case 'g3-div-5':
      return divideByFive(args['n']!);
    case 'g4-times-11-carry':
      return timesElevenCarry(args['n']!);
    case 'g4-complements':
      return complements(args['t']!, args['x']!, args['y']!);
    case 'g4-square-5':
      return squareEndsFive(args['t']!);
    case 'g4-div-25':
      return divideByTwentyFive(args['n']!);
    case 'g5-percent-10':
      return percentOf(10, args['n']!);
    case 'g5-percent-5':
      return percentOf(5, args['n']!);
    case 'g5-percent-1':
      return percentOf(1, args['n']!);
    default:
      throw ArgumentError('Unknown trick $trickId');
  }
}

final trickIds = [
  'k-pairs-10',
  'g1-make-10',
  'g1-add-20',
  'g2-near-100',
  'g2-sub-100',
  'g3-times-5',
  'g3-times-11',
  'g3-div-5',
  'g4-times-11-carry',
  'g4-complements',
  'g4-square-5',
  'g4-div-25',
  'g5-percent-10',
  'g5-percent-5',
  'g5-percent-1',
];

Problem generateTrick(
  String trickId, {
  required bool standard,
  required Random rng,
  bool guided = false,
  bool review = false,
  int? reviewSlot,
}) {
  final problem = switch (trickId) {
    'k-pairs-10' => pairsToTen(standard ? rng.nextInt(10) : 1 + rng.nextInt(5)),
    'g1-make-10' => _bridgePair(rng, standard, eightOrNine: !standard),
    'g1-add-20' => _bridgePair(
      rng,
      standard,
      eightOrNine: !standard,
      id: 'g1-add-20',
    ),
    'g2-near-100' => nearHundredAdd(
      standard ? 91 + rng.nextInt(9) : 95 + rng.nextInt(5),
      standard ? 91 + rng.nextInt(9) : 95 + rng.nextInt(5),
    ),
    'g2-sub-100' => nearHundredSub(
      (standard ? 100 : 100) + rng.nextInt(standard ? 100 : 31),
      91 + rng.nextInt(9),
    ),
    'g3-times-5' => timesFive(
      standard ? 12 + rng.nextInt(88) : 10 + rng.nextInt(31),
    ),
    'g3-times-11' => timesEleven(_eleven(rng, standard, carry: false)),
    'g3-div-5' => divideByFive(
      standard ? 10 + rng.nextInt(90) : 5 * (2 + rng.nextInt(8)),
    ),
    'g4-times-11-carry' => timesElevenCarry(_eleven(rng, standard, carry: true)),
    'g4-complements' => _complement(rng, standard),
    'g4-square-5' => squareEndsFive(standard ? 1 + rng.nextInt(9) : 1 + rng.nextInt(4)),
    'g4-div-25' => divideByTwentyFive(
      standard ? 5 * (1 + rng.nextInt(50)) : 25 * (1 + rng.nextInt(5)),
    ),
    'g5-percent-10' => percentOf(10, _dollars(rng, standard, rate: 10)),
    'g5-percent-5' => percentOf(5, _dollars(rng, standard, rate: 5)),
    'g5-percent-1' => percentOf(1, _dollars(rng, standard, rate: 1)),
    _ => throw ArgumentError('Unknown trick $trickId'),
  };
  return problem.copyWith(guided: guided, review: review, reviewSlot: reviewSlot);
}

Problem _bridgePair(
  Random rng,
  bool standard, {
  required bool eightOrNine,
  String id = 'g1-make-10',
}) {
  var a = eightOrNine
      ? (rng.nextBool() ? 8 : 9)
      : (standard ? 2 + rng.nextInt(8) : 6 + rng.nextInt(4));
  var low = 11 - a;
  if (low > 9) {
    a = 8;
    low = 3;
  }
  final b = low + rng.nextInt(10 - low);
  return makeTen(a, b, id: id);
}

int _eleven(Random rng, bool standard, {required bool carry}) {
  final tens = carry
      ? (standard ? 2 + rng.nextInt(8) : 2 + rng.nextInt(3))
      : (standard ? 1 + rng.nextInt(8) : 1 + rng.nextInt(3));
  if (carry) {
    final onesLow = max(0, 10 - tens);
    return tens * 10 + onesLow + rng.nextInt(10 - onesLow);
  }
  final onesHigh = 9 - tens;
  return tens * 10 + rng.nextInt(onesHigh + 1);
}

Problem _complement(Random rng, bool standard) {
  const pairs = [
    [1, 9],
    [2, 8],
    [3, 7],
    [4, 6],
    [5, 5],
    [6, 4],
    [7, 3],
    [8, 2],
    [9, 1],
  ];
  final tens = standard ? 1 + rng.nextInt(9) : 1 + rng.nextInt(3);
  final pair = pairs[rng.nextInt(pairs.length)];
  return complements(tens, pair[0], pair[1]);
}

int _dollars(Random rng, bool standard, {required int rate}) {
  if (!standard && rate == 10) return rng.nextBool() ? 100 : 200;
  if (!standard && rate == 1) return 100 * (1 + rng.nextInt(2));
  if (!standard && rate == 5) return 20 * (1 + rng.nextInt(5));
  return 10 * (1 + rng.nextInt(20));
}

List<Problem> buildLearnRound({
  required String trickId,
  required bool standard,
  required List<Problem> reviews,
  required Random rng,
}) {
  final fresh = <Problem>[];
  final seen = <String>{};
  var guard = 0;
  while (fresh.length < 10 && guard < 60) {
    guard += 1;
    final guided = fresh.length < 3;
    final problem = generateTrick(
      trickId,
      standard: standard,
      rng: rng,
      guided: guided,
    );
    if (seen.add(problem.signature) || guard > 40) fresh.add(problem);
  }
  return [...reviews.take(5), ...fresh];
}

Problem speedAdd(int a, int b) => Problem(
  trickId: 'speed:addition',
  prompt: '$a + $b',
  finalAnswer: '${a + b}',
  steps: [StepAsk(1, 'What is $a + $b?', '${a + b}')],
);

Problem speedSub(int a, int b) => Problem(
  trickId: 'speed:subtraction',
  prompt: '$a − $b',
  finalAnswer: '${a - b}',
  steps: [StepAsk(1, 'What is $a − $b?', '${a - b}')],
);

Problem speedMul(int a, int b) => Problem(
  trickId: 'speed:multiplication',
  prompt: '$a × $b',
  finalAnswer: '${a * b}',
  steps: [StepAsk(1, 'What is $a × $b?', '${a * b}')],
);

Problem speedDiv(int a, int b) {
  final answer = formatNum(a / b);
  return Problem(
    trickId: 'speed:division',
    prompt: '$a ÷ $b',
    finalAnswer: answer,
    steps: [StepAsk(1, 'What is $a ÷ $b?', answer)],
  );
}

String pickSpeedOperation(String selected, String grade, Random rng) {
  if (selected != 'mixed') return selected;
  if (grade == '5') return 'percent';
  if (grade == '3' || grade == '4') {
    return rng.nextBool() ? 'multiplication' : 'division';
  }
  return rng.nextBool() ? 'addition' : 'subtraction';
}

int _rollDigits(Random rng, int digits, {int minValue = 0, int maxValue = 9999}) {
  final lower = digits <= 1 ? 0 : pow(10, digits - 1).toInt();
  final upper = pow(10, digits).toInt() - 1;
  var start = max(lower, minValue);
  var end = min(upper, maxValue);
  if (end < start) {
    start = minValue;
    end = max(minValue, maxValue);
  }
  if (end == start) return start;
  return start + rng.nextInt(end - start + 1);
}

Problem nextSpeedProblem(SpeedConfig config, String grade, Random rng) {
  final operation = pickSpeedOperation(config.operation, grade, rng);
  switch (operation) {
    case 'subtraction':
      return _speedSub(config, grade, rng);
    case 'multiplication':
      return _speedMul(config, grade, rng);
    case 'division':
      return _speedDiv(config, grade, rng);
    case 'percent':
      final rate = [10, 5, 1][rng.nextInt(3)];
      final dollars = 10 * (1 + rng.nextInt(20));
      return percentOf(rate, dollars).copyWith(trickId: 'speed:percent');
    default:
      return _speedAdd(config, grade, rng);
  }
}

Problem _speedAdd(SpeedConfig config, String grade, Random rng) {
  if (grade == 'K') {
    final a = rng.nextInt(11);
    return speedAdd(a, rng.nextInt(11 - a));
  }
  if (grade == '1') {
    final a = _rollDigits(rng, config.digitMax, minValue: 0, maxValue: 20);
    final room = 20 - a;
    final b = room == 0 ? 0 : rng.nextInt(room + 1);
    return speedAdd(a, b);
  }
  if (grade == '2') {
    final a = _rollDigits(rng, 2, minValue: 10, maxValue: 90);
    final room = 100 - a;
    var b = rng.nextInt(room + 1);
    if (b < 10 && room >= 10) b = 10 + rng.nextInt(room - 9);
    return speedAdd(a, b);
  }
  final a = _rollDigits(rng, config.digitMin);
  final b = _rollDigits(rng, config.digitMax);
  return speedAdd(a, b);
}

Problem _speedSub(SpeedConfig config, String grade, Random rng) {
  if (grade == 'K') {
    final a = rng.nextInt(11);
    return speedSub(a, rng.nextInt(a + 1));
  }
  if (grade == '1') {
    final a = _rollDigits(rng, config.digitMax, maxValue: 20);
    return speedSub(a, rng.nextInt(a + 1));
  }
  if (grade == '2') {
    final a = _rollDigits(rng, 2, minValue: 20, maxValue: 99);
    var b = _rollDigits(rng, 2, minValue: 10, maxValue: a);
    if (b > a) b = a;
    return speedSub(a, b);
  }
  final a = _rollDigits(rng, config.digitMax, minValue: 1);
  final b = _rollDigits(rng, config.digitMin, maxValue: a);
  return speedSub(max(a, b), min(a, b));
}

Problem _speedMul(SpeedConfig config, String grade, Random rng) {
  if (grade == '4' || config.digitMax >= 2) {
    final a = 10 + rng.nextInt(90);
    final b = 2 + rng.nextInt(8);
    return speedMul(a, b);
  }
  final a = rng.nextInt(11);
  final b = rng.nextInt(5) == 0 ? 5 : rng.nextInt(11);
  return speedMul(a, b);
}

Problem _speedDiv(SpeedConfig config, String grade, Random rng) {
  if (grade == '4' || config.digitMax >= 2) {
    final divisor = 2 + rng.nextInt(8);
    final quotient = 2 + rng.nextInt(10);
    final dividend = divisor * quotient;
    if (dividend <= 99) return speedDiv(dividend, divisor);
  }
  final divisor = 1 + rng.nextInt(10);
  final quotient = rng.nextInt(11);
  return speedDiv(divisor * quotient, divisor);
}

List<Problem> buildSpeedQueue(SpeedConfig config, String grade, Random rng) {
  final count = config.limitMode == 'count' ? config.limitValue : 40;
  return List.generate(
    count,
    (_) => nextSpeedProblem(config, grade, rng),
  );
}

List<String> speechClips(String prompt) {
  final normalized = prompt
      .replaceAll('×', ' times ')
      .replaceAll('−', ' minus ')
      .replaceAll('÷', ' divided by ')
      .replaceAll('²', ' squared ')
      .replaceAll('%', ' percent ')
      .replaceAll('\$', ' dollars ')
      .replaceAll('?', ' what ')
      .replaceAll('=', ' equals ')
      .replaceAll('+', ' plus ');
  final clips = <String>[];
  final pattern = RegExp(r'\d+\.\d+|\d+|[A-Za-z]+');
  for (final match in pattern.allMatches(normalized)) {
    final token = match.group(0)!;
    if (RegExp(r'^\d').hasMatch(token)) {
      clips.addAll(_numberClips(token));
    } else {
      clips.add(token.toLowerCase());
    }
  }
  return clips;
}

List<String> _numberClips(String token) {
  if (token.contains('.')) {
    final parts = token.split('.');
    return [
      ..._integerClips(int.parse(parts[0])),
      'point',
      ...parts[1].split('').map((digit) => 'n$digit'),
    ];
  }
  return _integerClips(int.parse(token));
}

List<String> _integerClips(int value) {
  if (value < 0) return ['minus', ..._integerClips(-value)];
  if (value < 20) return ['n$value'];
  if (value < 100) {
    final tens = value ~/ 10 * 10;
    final ones = value % 10;
    return ones == 0 ? ['n$tens'] : ['n$tens', 'n$ones'];
  }
  if (value < 1000) {
    final hundreds = value ~/ 100;
    final rest = value % 100;
    return [
      'n$hundreds',
      'hundred',
      if (rest != 0) ..._integerClips(rest),
    ];
  }
  if (value < 10000) {
    final thousands = value ~/ 1000;
    final rest = value % 1000;
    return [
      'n$thousands',
      'thousand',
      if (rest != 0) ..._integerClips(rest),
    ];
  }
  return value.toString().split('').map((digit) => 'n$digit').toList();
}

/// Spoken form of a problem. `language` is `zh` or `en`.
String spokenPrompt(String prompt, {String language = 'zh'}) {
  final zh = language != 'en';
  final percentOf = RegExp(r'^(\d+)% of \$(\d+)$').firstMatch(prompt.trim());
  if (percentOf != null) {
    final percent = int.parse(percentOf.group(1)!);
    final dollars = int.parse(percentOf.group(2)!);
    return zh
        ? '${_zhInt(dollars)}美元的百分之${_zhInt(percent)}'
        : '${_enInt(percent)} percent of ${_enInt(dollars)} dollars';
  }
  final withPercent = prompt.replaceAllMapped(
    RegExp(r'(\d+(?:\.\d+)?)%'),
    (match) => zh
        ? '百分之${_spokenNumber(match.group(1)!, true)}'
        : '${_spokenNumber(match.group(1)!, false)} percent',
  );
  final withMoney = withPercent.replaceAllMapped(
    RegExp(r'\$(\d+(?:\.\d+)?)'),
    (match) => zh
        ? '${_spokenNumber(match.group(1)!, true)}美元'
        : '${_spokenNumber(match.group(1)!, false)} dollars',
  );
  final mapped = withMoney
      .replaceAll('×', zh ? ' 乘 ' : ' times ')
      .replaceAll('−', zh ? ' 减 ' : ' minus ')
      .replaceAll('–', zh ? ' 减 ' : ' minus ')
      .replaceAll('÷', zh ? ' 除以 ' : ' divided by ')
      .replaceAll('²', zh ? '的平方' : ' squared')
      .replaceAll('+', zh ? ' 加 ' : ' plus ')
      .replaceAll('=', zh ? ' 等于 ' : ' equals ')
      .replaceAll('?', zh ? '几' : ' what ');
  final spoken = mapped.replaceAllMapped(
    RegExp(r'\d+(?:\.\d+)?'),
    (match) => _spokenNumber(match.group(0)!, zh),
  );
  if (zh) return spoken.replaceAll(RegExp(r'\s+'), '');
  return spoken.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _spokenNumber(String token, bool zh) {
  if (!token.contains('.')) {
    return zh ? _zhInt(int.parse(token)) : _enInt(int.parse(token));
  }
  final parts = token.split('.');
  final whole = zh ? _zhInt(int.parse(parts[0])) : _enInt(int.parse(parts[0]));
  final fraction = parts[1].split('').map((digit) {
    final value = int.parse(digit);
    return zh ? _zhInt(value) : _enInt(value);
  }).join(zh ? '' : ' ');
  return zh ? '$whole点$fraction' : '$whole point $fraction';
}

String _zhInt(int value) {
  const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
  if (value < 0) return '负${_zhInt(-value)}';
  if (value < 10) return digits[value];
  if (value < 20) return value == 10 ? '十' : '十${digits[value % 10]}';
  if (value < 100) {
    final ones = value % 10;
    return '${digits[value ~/ 10]}十${ones == 0 ? '' : digits[ones]}';
  }
  if (value < 1000) {
    final rest = value % 100;
    final head = '${digits[value ~/ 100]}百';
    if (rest == 0) return head;
    if (rest < 10) return '$head零${digits[rest]}';
    return '$head${_zhInt(rest)}';
  }
  if (value < 10000) {
    final rest = value % 1000;
    final head = '${digits[value ~/ 1000]}千';
    if (rest == 0) return head;
    if (rest < 100) return '$head零${_zhInt(rest)}';
    return '$head${_zhInt(rest)}';
  }
  return '$value';
}

String _enInt(int value) {
  const small = [
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
    'sixteen', 'seventeen', 'eighteen', 'nineteen',
  ];
  const tens = [
    '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty',
    'ninety',
  ];
  if (value < 0) return 'negative ${_enInt(-value)}';
  if (value < 20) return small[value];
  if (value < 100) {
    final name = tens[value ~/ 10];
    final ones = value % 10;
    return ones == 0 ? name : '$name ${small[ones]}';
  }
  if (value < 1000) {
    final head = '${small[value ~/ 100]} hundred';
    final rest = value % 100;
    return rest == 0 ? head : '$head ${_enInt(rest)}';
  }
  if (value < 10000) {
    final head = '${small[value ~/ 1000]} thousand';
    final rest = value % 1000;
    return rest == 0 ? head : '$head ${_enInt(rest)}';
  }
  return '$value';
}

String ttsLanguageTag(
  String languageCode, {
  String? countryCode,
  String? scriptCode,
}) {
  final language = languageCode.toLowerCase();
  final country = countryCode?.toUpperCase();
  if (language == 'zh') {
    if (country == 'TW' || scriptCode == 'Hant') return 'zh-TW';
    return 'zh-CN';
  }
  if (language == 'en') return country == 'GB' ? 'en-GB' : 'en-US';
  if (country != null && country.isNotEmpty) return '$language-$country';
  return language;
}

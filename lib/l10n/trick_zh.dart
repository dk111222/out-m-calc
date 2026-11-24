import '../domain/catalog.dart';
import 'copy.dart';

class _Zh {
  const _Zh({
    required this.title,
    required this.applies,
    required this.notFor,
    required this.steps,
    required this.bodies,
    required this.notes,
    required this.shortRange,
    required this.standardRange,
  });

  final String title;
  final String applies;
  final String notFor;
  final List<String> steps;
  final List<String> bodies;
  final List<String> notes;
  final String shortRange;
  final String standardRange;
}

/// Short Chinese lines so the trick page can be scanned in a glance.
const _rows = <String, _Zh>{
  'k-pairs-10': _Zh(
    title: '凑成 10',
    applies: '找凑成 10 的另一半。',
    notFor: '和不是 10。',
    steps: ['算差', '核对'],
    bodies: ['10 − 已知数。', '两数相加得 10。'],
    notes: ['3 还差 7', '3 + 7 = 10'],
    shortRange: '1–5',
    standardRange: '0–9',
  ),
  'g1-make-10': _Zh(
    title: '凑十法',
    applies: '两位数相加，和超过 10。',
    notFor: '和 ≤ 10。',
    steps: ['先到 10', '拆开', '加上剩余'],
    bodies: ['看还差几到 10。', '从另一个数里拿走。', '10 + 剩余。'],
    notes: ['8 还差 2', '7 剩 5', '10 + 5 = 15'],
    shortRange: '第一个是 8/9',
    standardRange: '2–9，和 > 10',
  ),
  'g1-add-20': _Zh(
    title: '20 以内加法',
    applies: '过 10，和不超过 20。',
    notFor: '和 ≤ 10。',
    steps: ['先到 10', '算剩余', '加完'],
    bodies: ['看还差几到 10。', '另一个数减去这个差。', '10 + 剩余。'],
    notes: ['9 还差 1', '6 剩 5', '10 + 5 = 15'],
    shortRange: '有一个是 8/9',
    standardRange: '和 11–18',
  ),
  'g2-near-100': _Zh(
    title: '接近 100',
    applies: '两个数都在 91–99。',
    notFor: '有一个 ≤ 90。',
    steps: ['差一', '差二', '差相加', '200 减'],
    bodies: ['100 − 第一个。', '100 − 第二个。', '两个差相加。', '200 − 这个和。'],
    notes: ['97 → 少 3', '96 → 少 4', '差和 7', '200 − 7 = 193'],
    shortRange: '95–99',
    standardRange: '91–99',
  ),
  'g2-sub-100': _Zh(
    title: '接近 100 的减法',
    applies: '从 ≥100 里减去 91–99。',
    notFor: '减数很小。',
    steps: ['算差', '先减 100', '加回差'],
    bodies: ['100 − 减数。', '被减数 − 100。', '剩余 + 差。'],
    notes: ['97 → 少 3', '150 − 100 = 50', '50 + 3 = 53'],
    shortRange: '被减数 100–130',
    standardRange: '被减数 100–199',
  ),
  'g3-times-5': _Zh(
    title: '× 5',
    applies: '乘以 5。',
    notFor: '×10 或 ×50。',
    steps: ['先 ×10', '再取半'],
    bodies: ['先乘 10。', '再取一半。'],
    notes: ['48 × 10 = 480', '一半是 240'],
    shortRange: '10–40',
    standardRange: '12–99',
  ),
  'g3-times-11': _Zh(
    title: '× 11',
    applies: '两位数 ×11，数字和 < 10。',
    notFor: '数字和 ≥ 10（要进位）。',
    steps: ['数字相加', '夹中间'],
    bodies: ['十位 + 个位。', '十位 · 和 · 个位。'],
    notes: ['3 + 5 = 8', '积 385'],
    shortRange: '十位 1–3',
    standardRange: '数字和 < 10',
  ),
  'g3-div-5': _Zh(
    title: '÷ 5',
    applies: '除以 5。',
    notFor: '÷10 或 ÷2。',
    steps: ['先 ×2', '再 ÷10'],
    bodies: ['先乘 2。', '再除以 10。'],
    notes: ['35 × 2 = 70', '70 ÷ 10 = 7'],
    shortRange: '5 的倍数',
    standardRange: '10–99',
  ),
  'g4-times-11-carry': _Zh(
    title: '× 11 进位',
    applies: '两位数 ×11，数字和 ≥ 10。',
    notFor: '数字和 < 10。',
    steps: ['数字相加', '留个位', '写出积'],
    bodies: ['十位 + 个位。', '和的个位留下。', '进位 + 中间 + 个位。'],
    notes: ['4 + 8 = 12', '中间 2', '积 528'],
    shortRange: '十位 2–4',
    standardRange: '数字和 ≥ 10',
  ),
  'g4-complements': _Zh(
    title: '个位凑 10',
    applies: '十位相同，个位凑 10。',
    notFor: '个位和不等于 10。',
    steps: ['看个位', '算前半', '算后半', '接起来'],
    bodies: ['个位和应是 10。', '十位 × 下一个。', '个位 × 个位。', '前半接两位后半。'],
    notes: ['6 + 4 = 10', '2 × 3 = 6', '6 × 4 = 24', '积 624'],
    shortRange: '十位 1–3',
    standardRange: '十位 1–9',
  ),
  'g4-square-5': _Zh(
    title: '尾数 5 的平方',
    applies: '求尾数是 5 的平方。',
    notFor: '不以 5 结尾。',
    steps: ['算前半', '接 25'],
    bodies: ['十位 × 下一个。', '前面接 25。'],
    notes: ['4 × 5 = 20', '2025'],
    shortRange: '15、25、35、45',
    standardRange: '任意尾数 5',
  ),
  'g4-div-25': _Zh(
    title: '÷ 25',
    applies: '除以 25。',
    notFor: '÷5 或 ÷50。',
    steps: ['先 ×4', '再 ÷100'],
    bodies: ['先乘 4。', '再除以 100。'],
    notes: ['75 × 4 = 300', '300 ÷ 100 = 3'],
    shortRange: '25、50、75、100、125',
    standardRange: '≤250 的 5 的倍数',
  ),
  'g5-percent-10': _Zh(
    title: '10%',
    applies: '求价格的 10%。',
    notFor: '15% 或 20%。',
    steps: ['÷10', '得答案'],
    bodies: ['10% = 除以 10。', '价格 ÷ 10。'],
    notes: ['÷10', '80 的 10% = 8'],
    shortRange: '100、200 美元',
    standardRange: '10–200 美元（×10）',
  ),
  'g5-percent-5': _Zh(
    title: '5%',
    applies: '求价格的 5%。',
    notFor: '不是求 5%。',
    steps: ['先 10%', '再取半'],
    bodies: ['先求 10%。', '再取一半。'],
    notes: ['80 的 10% = 8', '一半 = 4'],
    shortRange: '20 美元倍数',
    standardRange: '10–200 美元（×10）',
  ),
  'g5-percent-1': _Zh(
    title: '1%',
    applies: '求价格的 1%。',
    notFor: '求的是 10%。',
    steps: ['÷100', '得答案'],
    bodies: ['1% = 除以 100。', '价格 ÷ 100。'],
    notes: ['÷100', '80 的 1% = 0.8'],
    shortRange: '100 美元倍数',
    standardRange: '10–200 美元（×10）',
  ),
};

Trick localizeTrick(Trick trick, Copy copy) {
  if (!copy.zh) return trick;
  final row = _rows[trick.id];
  if (row == null) return trick;
  return Trick(
    id: trick.id,
    grade: trick.grade,
    operation: trick.operation,
    title: row.title,
    appliesWhen: row.applies,
    notWhen: row.notFor,
    steps: [
      for (var i = 0; i < trick.steps.length; i++)
        LessonStep(
          trick.steps[i].number,
          i < row.steps.length ? row.steps[i] : trick.steps[i].title,
          i < row.bodies.length ? row.bodies[i] : trick.steps[i].body,
        ),
    ],
    example: LessonExample(
      trick.example.prompt,
      trick.example.pieces,
      [
        for (var i = 0; i < trick.example.notes.length; i++)
          ExampleNote(
            trick.example.notes[i].step,
            i < row.notes.length ? row.notes[i] : trick.example.notes[i].text,
          ),
      ],
    ),
    shortRange: row.shortRange,
    standardRange: row.standardRange,
    ready: trick.ready,
    blockReason: trick.blockReason,
  );
}

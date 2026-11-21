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

const _rows = <String, _Zh>{
  'k-pairs-10': _Zh(
    title: '凑成 10',
    applies: '已知 0 到 9 里的一个数，要找和它凑成 10 的另一个数。',
    notFor: '两个数加起来不是 10，比如 6 + 6。这类题直接相加。',
    steps: ['找差', '核对一对'],
    bodies: ['用 10 减去你已有的数。', '把你的数和这个差相加，结果是 10。'],
    notes: ['3 还差 7', '3 + 7 = 10'],
    shortRange: '1 到 5 的搭档。',
    standardRange: '0 到 9 的搭档。',
  ),
  'g1-make-10': _Zh(
    title: '凑十法',
    applies: '两个一位数相加，和超过 10。',
    notFor: '和是 10 或更小，比如 4 + 5。这类题一步就算完。',
    steps: ['先到 10', '拆另一个数', '加上剩下的'],
    bodies: ['看第一个数还差几到 10。', '从第二个数里拿走这么多。', '把剩下的加到 10 上。'],
    notes: ['8 还差 2', '7 剩下 5', '10 + 5 = 15'],
    shortRange: '第一个数是 8 或 9。',
    standardRange: '两个数都在 2 到 9，而且和超过 10。',
  ),
  'g1-add-20': _Zh(
    title: '20 以内加法',
    applies: '两个一位数相加，和不超过 20，而且要跨过 10。',
    notFor: '和是 10 或更小。这类题不用拆。',
    steps: ['先到 10', '剩下的', '算完'],
    bodies: ['看第一个数到 10 还差几。', '用第二个数减去这个差。', '把剩下的加到 10 上。和仍小于 20。'],
    notes: ['9 还差 1', '6 剩下 5', '10 + 5 = 15'],
    shortRange: '其中一个数是 8 或 9。',
    standardRange: '和从 11 到 18。',
  ),
  'g2-near-100': _Zh(
    title: '接近 100',
    applies: '两个数都在 91 到 99。',
    notFor: '某个数离 100 超过 10，比如 80 + 70。',
    steps: ['第一个差', '第二个差', '把差加起来', '从 200 里去掉'],
    bodies: ['看第一个数比 100 少几。', '看第二个数比 100 少几。', '把两个差相加。', '用 200 减去这个和。'],
    notes: ['97 比 100 少 3', '96 比 100 少 4', '两个差加起来是 7', '200 − 7 = 193'],
    shortRange: '两个数都在 95 到 99。',
    standardRange: '两个数都在 91 到 99。',
  ),
  'g2-sub-100': _Zh(
    title: '接近 100 的减法',
    applies: '从一个至少是 100 的数里，减去 91 到 99 的数。',
    notFor: '减数很小，比如 150 − 6。',
    steps: ['离 100 还差几', '先去掉 100', '把差加回去'],
    bodies: ['看减数比 100 少几。', '从被减数里去掉 100。', '把这个差加到剩下的数上。'],
    notes: ['97 比 100 少 3', '150 − 100 = 50', '50 + 3 = 53'],
    shortRange: '被减数在 100 到 130。',
    standardRange: '被减数在 100 到 199。',
  ),
  'g3-times-5': _Zh(
    title: '乘以 5',
    applies: '一个整数乘以 5。',
    notFor: '乘以 10 或乘以 50。那是另外的算法。',
    steps: ['先乘 10', '再取一半'],
    bodies: ['先把这个数乘以 10。', '再取一半。这一半就是积。'],
    notes: ['48 × 10 = 480', '480 的一半是 240'],
    shortRange: '这个数在 10 到 40。',
    standardRange: '这个数在 12 到 99。',
  ),
  'g3-times-11': _Zh(
    title: '乘以 11',
    applies: '两位数乘以 11，而且两个数字相加小于 10。',
    notFor: '两个数字相加是 10 或更大，比如 48 × 11。那种要进位。',
    steps: ['数字相加', '把和放在中间'],
    bodies: ['把十位和个位相加。', '先写十位，再写这个和，最后写个位。'],
    notes: ['3 + 5 = 8', '积是 385'],
    shortRange: '十位是 1、2 或 3。',
    standardRange: '任意两个数字相加小于 10 的两位数。',
  ),
  'g3-div-5': _Zh(
    title: '除以 5',
    applies: '一个整数除以 5。',
    notFor: '除以 10 或除以 2。那些直接用口诀。',
    steps: ['先乘 2', '小数点移位'],
    bodies: ['先把这个数乘以 2。', '再把这个两倍除以 10。'],
    notes: ['35 × 2 = 70', '70 ÷ 10 = 7'],
    shortRange: '5 的倍数。',
    standardRange: '10 到 99 的整数。有的答案有一位小数。',
  ),
  'g4-times-11-carry': _Zh(
    title: '乘以 11 并进位',
    applies: '两位数乘以 11，而且两个数字相加是 10 或更大。',
    notFor: '两个数字相加小于 10。那些积不用进位。',
    steps: ['数字相加', '中间一位', '写出积'],
    bodies: ['把十位和个位相加。', '和的个位留下，十位是进位。', '把进位加到第一位，再写下中间和末位。'],
    notes: ['4 + 8 = 12', '中间一位是 2', '积是 528'],
    shortRange: '十位是 2、3 或 4。',
    standardRange: '任意两个数字相加是 10 或更大的两位数。',
  ),
  'g4-complements': _Zh(
    title: '个位相加得 10',
    applies: '两个两位数的十位相同，个位相加得 10。',
    notFor: '个位相加不是 10，比如 26 × 23。',
    steps: ['看个位', '前面部分', '后面部分', '接起来'],
    bodies: ['把个位相加，结果应当是 10。', '用十位乘下一个整数。', '把个位相乘。如果积只有一位，十位写 0。', '先写前面部分，再把后面部分写成两位。'],
    notes: ['6 + 4 = 10', '2 × 3 = 6', '6 × 4 = 24', '积是 624'],
    shortRange: '十位是 1、2 或 3。',
    standardRange: '十位从 1 到 9。',
  ),
  'g4-square-5': _Zh(
    title: '尾数是 5 的平方',
    applies: '求一个尾数是 5 的两位数的平方。',
    notFor: '这个数不以 5 结尾，比如 40² 或 46²。',
    steps: ['前面部分', '接上 25'],
    bodies: ['用十位乘下一个整数。', '把这个积写在 25 前面。'],
    notes: ['4 × 5 = 20', '20 后面接 25 是 2025'],
    shortRange: '15、25、35 和 45。',
    standardRange: '每一个以 5 结尾的两位数。',
  ),
  'g4-div-25': _Zh(
    title: '除以 25',
    applies: '一个整数除以 25。',
    notFor: '除以 5 或除以 50。那些用各自的算法。',
    steps: ['先乘 4', '移两位'],
    bodies: ['先把这个数乘以 4。', '再把这个积除以 100。'],
    notes: ['75 × 4 = 300', '300 ÷ 100 = 3'],
    shortRange: '25、50、75、100 和 125。',
    standardRange: '250 以内 5 的倍数，包括每一个 25 的倍数。',
  ),
  'g5-percent-10': _Zh(
    title: '百分之十',
    applies: '求一个整数美元价格的 10%。',
    notFor: '百分数是 15% 或 20%。那些不是十分之一。',
    steps: ['除数', '这一份'],
    bodies: ['10% 是十分之一，所以除以 10。', '用价格除以 10。这就是 10%。'],
    notes: ['除以 10', '80 的 10% 是 8'],
    shortRange: '价格是 100 美元和 200 美元。',
    standardRange: '10 美元到 200 美元里 10 的倍数。',
  ),
  'g5-percent-5': _Zh(
    title: '百分之五',
    applies: '求一个整数美元价格的 5%。',
    notFor: '题目只要 10%，或者要的不是 5%。',
    steps: ['先算 10%', '再取一半'],
    bodies: ['先求出价格的 10%。', '5% 是这个 10% 的一半。'],
    notes: ['80 的 10% 是 8', '一半是 4'],
    shortRange: '20 美元的倍数。',
    standardRange: '10 美元到 200 美元里 10 的倍数。',
  ),
  'g5-percent-1': _Zh(
    title: '百分之一',
    applies: '求一个整数美元价格的 1%。',
    notFor: '题目要的是 10%。百分之一是一百分之一，不是十分之一。',
    steps: ['除数', '这一份'],
    bodies: ['1% 是一百分之一，所以除以 100。', '用价格除以 100。'],
    notes: ['除以 100', '80 的 1% 是 0.8'],
    shortRange: '100 美元的倍数。',
    standardRange: '10 美元到 200 美元里 10 的倍数。',
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

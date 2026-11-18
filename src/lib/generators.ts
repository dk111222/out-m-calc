export type Problem = {
  id: string;
  skillId: string;
  skillName: string;
  prompt: string;
  answer: number;
  strategy: string;
};

type SkillDef = {
  id: string;
  name: string;
  strategy: string;
  make: (rng: () => number) => Omit<Problem, "id" | "skillId" | "skillName" | "strategy">;
};

function randInt(rng: () => number, min: number, max: number): number {
  return Math.floor(rng() * (max - min + 1)) + min;
}

function pick<T>(rng: () => number, items: T[]): T {
  return items[Math.floor(rng() * items.length)]!;
}

/** Mulberry32 — deterministic when seeded. */
export function createRng(seed: number): () => number {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let r = Math.imul(t ^ (t >>> 15), 1 | t);
    r ^= r + Math.imul(r ^ (r >>> 7), 61 | r);
    return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
  };
}

const SKILLS: SkillDef[] = [
  {
    id: "make10",
    name: "凑十",
    strategy: "先想凑成 10 还差几。",
    make: (rng) => {
      const a = randInt(rng, 1, 9);
      return { prompt: `${a} + ? = 10`, answer: 10 - a };
    },
  },
  {
    id: "split10",
    name: "拆十以内",
    strategy: "找出另一半是多少。",
    make: (rng) => {
      const total = randInt(rng, 2, 10);
      const a = randInt(rng, 1, total - 1);
      return { prompt: `${total} = ${a} + ?`, answer: total - a };
    },
  },
  {
    id: "teen",
    name: "十几",
    strategy: "十几就是 10 加几个一。",
    make: (rng) => {
      const ones = randInt(rng, 1, 9);
      return { prompt: `${10 + ones} = 10 + ?`, answer: ones };
    },
  },
  {
    id: "make10b",
    name: "先凑十再加",
    strategy: "先凑成 10，再加剩下的。",
    make: (rng) => {
      const a = randInt(rng, 6, 9);
      const b = randInt(rng, 11 - a, 9);
      return { prompt: `${a} + ${b}`, answer: a + b };
    },
  },
  {
    id: "near",
    name: "近双数",
    strategy: "先想双数，再加 1。",
    make: (rng) => {
      const a = randInt(rng, 3, 8);
      return { prompt: `${a} + ${a + 1}`, answer: a + a + 1 };
    },
  },
  {
    id: "three",
    name: "三数凑十",
    strategy: "先把能凑成 10 的两个加起来。",
    make: (rng) => {
      const pairs: [number, number][] = [
        [1, 9],
        [2, 8],
        [3, 7],
        [4, 6],
        [5, 5],
      ];
      const [x, y] = pick(rng, pairs);
      const z = randInt(rng, 1, 8);
      const order = [x, y, z].sort(() => rng() - 0.5);
      return {
        prompt: `${order[0]} + ${order[1]} + ${order[2]}`,
        answer: x + y + z,
      };
    },
  },
  {
    id: "pm10",
    name: "加减 10",
    strategy: "只改十位上的数字。",
    make: (rng) => {
      const tens = randInt(rng, 2, 8);
      const ones = randInt(rng, 0, 9);
      const n = tens * 10 + ones;
      const add = rng() < 0.5;
      return add
        ? { prompt: `${n} + 10`, answer: n + 10 }
        : { prompt: `${n} − 10`, answer: n - 10 };
    },
  },
  {
    id: "place",
    name: "整十加一位",
    strategy: "几十和几分开加。",
    make: (rng) => {
      const tens = randInt(rng, 1, 9) * 10;
      const ones = randInt(rng, 1, 9);
      return { prompt: `${tens} + ${ones}`, answer: tens + ones };
    },
  },
  {
    id: "split100",
    name: "百以内拆加",
    strategy: "先加几十，再加个位。",
    make: (rng) => {
      const a = randInt(rng, 21, 68);
      const bMax = Math.min(39, 100 - a);
      const b = randInt(rng, 12, Math.max(12, bMax));
      return { prompt: `${a} + ${b}`, answer: a + b };
    },
  },
  {
    id: "comp",
    name: "补偿",
    strategy: "先加减成整十，再调回来。",
    make: (rng) => {
      const kind = randInt(rng, 0, 2);
      if (kind === 0) {
        const a = randInt(rng, 21, 80);
        return { prompt: `${a} + 9`, answer: a + 9 };
      }
      if (kind === 1) {
        const a = randInt(rng, 21, 70);
        return { prompt: `${a} + 19`, answer: a + 19 };
      }
      const a = randInt(rng, 20, 90);
      return { prompt: `${a} − 9`, answer: a - 9 };
    },
  },
  {
    id: "x2",
    name: "乘 2",
    strategy: "乘 2 就是加倍。",
    make: (rng) => {
      const a = randInt(rng, 6, 50);
      return { prompt: `${a} × 2`, answer: a * 2 };
    },
  },
  {
    id: "x5",
    name: "乘 5",
    strategy: "先乘 10，再减半。",
    make: (rng) => {
      const a = randInt(rng, 3, 20);
      return { prompt: `${a} × 5`, answer: a * 5 };
    },
  },
  {
    id: "x10",
    name: "乘整十",
    strategy: "先乘，再补上 0。",
    make: (rng) => {
      const a = randInt(rng, 2, 9);
      const tens = randInt(rng, 2, 9) * 10;
      return { prompt: `${a} × ${tens}`, answer: a * tens };
    },
  },
  {
    id: "dbl",
    name: "连续加倍",
    strategy: "加倍，再加倍。",
    make: (rng) => {
      const a = randInt(rng, 12, 28);
      const by4 = rng() < 0.5;
      return by4
        ? { prompt: `${a} × 4`, answer: a * 4 }
        : { prompt: `${a} × 8`, answer: a * 8 };
    },
  },
  {
    id: "dist",
    name: "拆开相乘",
    strategy: "先算整十部分，再加个位部分。",
    make: (rng) => {
      const tens = randInt(rng, 2, 6) * 10;
      const ones = randInt(rng, 1, 9);
      const a = tens + ones;
      const b = randInt(rng, 3, 9);
      return { prompt: `${a} × ${b}`, answer: a * b };
    },
  },
  {
    id: "mul11",
    name: "乘 11",
    strategy: "先乘 10，再加它自己。",
    make: (rng) => {
      const a = randInt(rng, 12, 48);
      return { prompt: `${a} × 11`, answer: a * 11 };
    },
  },
  {
    id: "pow10",
    name: "乘除 10/100",
    strategy: "数字挪一位或两位。",
    make: (rng) => {
      const kind = randInt(rng, 0, 3);
      if (kind === 0) {
        const a = randInt(rng, 2, 9) + randInt(rng, 1, 9) / 10;
        const rounded = Math.round(a * 10) / 10;
        return { prompt: `${rounded} × 10`, answer: Math.round(rounded * 10) };
      }
      if (kind === 1) {
        const a = randInt(rng, 12, 89);
        return { prompt: `${a} × 10`, answer: a * 10 };
      }
      if (kind === 2) {
        const a = randInt(rng, 2, 9) * 100;
        return { prompt: `${a} ÷ 10`, answer: a / 10 };
      }
      const a = randInt(rng, 3, 9) * 100;
      return { prompt: `${a} ÷ 100`, answer: a / 100 };
    },
  },
  {
    id: "partial",
    name: "友好乘 25",
    strategy: "先乘 100，再除以 4。",
    make: (rng) => {
      const a = randInt(rng, 4, 24);
      return { prompt: `${a} × 25`, answer: a * 25 };
    },
  },
];

export function generateProblems(count = 20, seed?: number): Problem[] {
  const rng = createRng(seed ?? (Date.now() ^ (Math.random() * 0x100000000)));
  const problems: Problem[] = [];
  let lastPrompt = "";

  for (let i = 0; i < count; i++) {
    let attempts = 0;
    let problem: Problem | null = null;
    while (attempts < 20) {
      const skill = pick(rng, SKILLS);
      const made = skill.make(rng);
      if (made.prompt === lastPrompt) {
        attempts += 1;
        continue;
      }
      problem = {
        id: `p${i + 1}-${skill.id}`,
        skillId: skill.id,
        skillName: skill.name,
        strategy: skill.strategy,
        ...made,
      };
      break;
    }
    if (!problem) {
      const skill = SKILLS[0]!;
      const made = skill.make(rng);
      problem = {
        id: `p${i + 1}-${skill.id}`,
        skillId: skill.id,
        skillName: skill.name,
        strategy: skill.strategy,
        ...made,
      };
    }
    lastPrompt = problem.prompt;
    problems.push(problem);
  }

  return problems;
}

export function parseAnswer(raw: string): number | null {
  const trimmed = raw.trim().replace(/,/g, "");
  if (!trimmed) return null;
  if (!/^-?\d+(\.\d+)?$/.test(trimmed)) return null;
  const n = Number(trimmed);
  return Number.isFinite(n) ? n : null;
}

"use client";

import { useEffect, useMemo, useState } from "react";
import {
  generateProblems,
  parseAnswer,
  type Problem,
} from "@/lib/generators";

type Result = "idle" | "correct" | "wrong";

const TOTAL = 20;

function answersMatch(expected: number, given: number): boolean {
  return Math.abs(expected - given) < 1e-9;
}

export function PracticeDemo() {
  const [seed, setSeed] = useState(() => Date.now());
  const problems = useMemo(() => generateProblems(TOTAL, seed), [seed]);
  const [index, setIndex] = useState(0);
  const [input, setInput] = useState("");
  const [result, setResult] = useState<Result>("idle");
  const [correctCount, setCorrectCount] = useState(0);
  const [done, setDone] = useState(false);
  const [shake, setShake] = useState(false);

  const current: Problem | undefined = problems[index];
  const progress = done ? TOTAL : index;

  useEffect(() => {
    setIndex(0);
    setInput("");
    setResult("idle");
    setCorrectCount(0);
    setDone(false);
  }, [seed]);

  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (done) return;
      if (result === "idle") {
        if (event.key >= "0" && event.key <= "9") {
          event.preventDefault();
          onKey(event.key);
          return;
        }
        if (event.key === ".") {
          event.preventDefault();
          onKey(".");
          return;
        }
        if (event.key === "Backspace") {
          event.preventDefault();
          backspace();
          return;
        }
        if (event.key === "Enter") {
          event.preventDefault();
          submit();
        }
        return;
      }
      if (event.key === "Enter") {
        event.preventDefault();
        goNext();
      }
    }
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  });

  function restart() {
    setSeed(Date.now());
  }

  function submit() {
    if (!current || result !== "idle") return;
    const parsed = parseAnswer(input);
    if (parsed === null) {
      setShake(true);
      window.setTimeout(() => setShake(false), 320);
      return;
    }

    const ok = answersMatch(current.answer, parsed);
    setResult(ok ? "correct" : "wrong");
    if (ok) setCorrectCount((c) => c + 1);
  }

  function goNext() {
    if (!current) return;
    if (index >= TOTAL - 1) {
      setDone(true);
      setResult("idle");
      setInput("");
      return;
    }
    setIndex((i) => i + 1);
    setInput("");
    setResult("idle");
  }

  function onKey(digit: string) {
    if (result !== "idle") return;
    if (digit === "." && input.includes(".")) return;
    if (input.length >= 8) return;
    setInput((v) => v + digit);
  }

  function backspace() {
    if (result !== "idle") return;
    setInput((v) => v.slice(0, -1));
  }

  if (done) {
    return (
      <section className="practice" id="try" aria-labelledby="try-title">
        <div className="practice-shell practice-done">
          <p className="eyebrow">功能体验</p>
          <h2 id="try-title">本轮完成</h2>
          <p className="lede">
            20 题里做对了 <strong>{correctCount}</strong> 题。正式产品里，家长会按「技巧」看到哪一招还要练。
          </p>
          <button type="button" className="btn btn-primary" onClick={restart}>
            再来 20 题
          </button>
        </div>
      </section>
    );
  }

  if (!current) return null;

  return (
    <section className="practice" id="try" aria-labelledby="try-title">
      <div className="practice-shell">
        <div className="practice-head">
          <div>
            <p className="eyebrow">功能体验 · 无需登录</p>
            <h2 id="try-title">随机 20 题</h2>
          </div>
          <p className="practice-count">
            {progress + 1} / {TOTAL}
          </p>
        </div>

        <div
          className="progress-track"
          role="progressbar"
          aria-valuemin={0}
          aria-valuemax={TOTAL}
          aria-valuenow={progress}
        >
          <span style={{ width: `${(progress / TOTAL) * 100}%` }} />
        </div>

        <div className={`prompt-block ${shake ? "shake" : ""}`}>
          <p className="skill-tag">{current.skillName}</p>
          <p className="prompt" aria-live="polite">
            {current.prompt}
          </p>
          <div className="answer-line" aria-label="你的答案">
            {input || <span className="placeholder">?</span>}
          </div>
        </div>

        {result === "correct" && (
          <div className="feedback feedback-ok" role="status">
            <p>正确</p>
            <button type="button" className="btn btn-primary" onClick={goNext}>
              {index >= TOTAL - 1 ? "查看结果" : "下一题"}
            </button>
          </div>
        )}

        {result === "wrong" && (
          <div className="feedback feedback-bad" role="status">
            <p>
              {current.prompt} = <strong>{current.answer}</strong>
            </p>
            <p className="strategy">{current.strategy}</p>
            <button type="button" className="btn btn-primary" onClick={goNext}>
              {index >= TOTAL - 1 ? "查看结果" : "继续"}
            </button>
          </div>
        )}

        {result === "idle" && (
          <div className="keypad" aria-label="数字键盘">
            {["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"].map(
              (key) => (
                <button
                  key={key}
                  type="button"
                  className="key"
                  onClick={() => (key === "⌫" ? backspace() : onKey(key))}
                >
                  {key}
                </button>
              ),
            )}
            <button
              type="button"
              className="key key-submit"
              onClick={submit}
            >
              提交
            </button>
          </div>
        )}

        <button type="button" className="linkish" onClick={restart}>
          换一组新题
        </button>
      </div>
    </section>
  );
}

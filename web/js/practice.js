function mulberry32(seed) {
  var a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    var t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle(pool, rng) {
  var copy = pool.slice();
  for (var i = copy.length - 1; i > 0; i--) {
    var j = Math.floor(rng() * (i + 1));
    var tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy;
}

var SETS = {
  make10: {
    labelKey: "trick.make10",
    blurbKey: "blurb.make10",
    lesson: "tricks/make-10.html",
    pool: function () {
      var pool = [];
      for (var a = 2; a <= 9; a++) {
        for (var b = 2; b <= 9; b++) {
          if (a + b > 10) pool.push({ prompt: a + " + " + b, answer: String(a + b) });
        }
      }
      return pool;
    }
  },
  near100: {
    labelKey: "trick.near100",
    blurbKey: "blurb.near100",
    lesson: "tricks/near-100.html",
    pool: function () {
      var pool = [];
      for (var a = 91; a <= 99; a++) {
        for (var b = 91; b <= 99; b++) {
          pool.push({ prompt: a + " + " + b, answer: String(a + b) });
        }
      }
      return pool;
    }
  },
  times5: {
    labelKey: "trick.times5",
    blurbKey: "blurb.times5",
    lesson: "tricks/times-5.html",
    pool: function () {
      var pool = [];
      for (var n = 12; n <= 60; n++) {
        pool.push({ prompt: n + " × 5", answer: String(n * 5) });
      }
      return pool;
    }
  },
  times11: {
    labelKey: "trick.times11",
    blurbKey: "blurb.times11",
    lesson: "tricks/times-11.html",
    pool: function () {
      var pool = [];
      for (var n = 10; n <= 99; n++) {
        var tens = Math.floor(n / 10);
        var ones = n % 10;
        if (tens + ones < 10) pool.push({ prompt: n + " × 11", answer: String(n * 11) });
      }
      return pool;
    }
  }
};

function drawSet(setId, count, seed) {
  var set = SETS[setId] || SETS.make10;
  return shuffle(set.pool(), mulberry32(seed)).slice(0, count);
}

var round = {
  setId: "make10",
  seed: 1,
  items: [],
  index: 0,
  correct: 0,
  locked: false,
  timer: 0
};

function $(id) {
  return document.getElementById(id);
}

function showPanel(name) {
  ["gate", "round", "done"].forEach(function (id) {
    $(id).hidden = id !== name;
  });
}

function readSeed() {
  var raw = new URLSearchParams(location.search).get("seed");
  var n = Number(raw);
  if (Number.isInteger(n) && n > 0) return n;
  return Math.floor(Math.random() * 2147483646) + 1;
}

function selectedSet() {
  var input = document.querySelector('input[name="set"]:checked');
  return input && SETS[input.value] ? input.value : "make10";
}

function writeBlurb() {
  $("set-blurb").textContent = SM.t(SETS[selectedSet()].blurbKey);
}

function renderTicks() {
  var ticks = $("ticks");
  ticks.replaceChildren();
  for (var i = 0; i < 10; i++) {
    var mark = document.createElement("span");
    if (i < round.index) mark.className = "is-done";
    if (i === round.index) mark.className = "is-now";
    ticks.appendChild(mark);
  }
}

function renderProblem() {
  window.clearTimeout(round.timer);
  round.locked = false;
  var item = round.items[round.index];
  $("progress").textContent = SM.t("drill.progress", {
    i: String(round.index + 1),
    label: SM.t(SETS[round.setId].labelKey)
  });
  $("prompt").textContent = item.prompt;
  var answer = $("answer");
  answer.value = "";
  answer.classList.remove("is-bad");
  var feedback = $("feedback");
  feedback.textContent = "";
  feedback.className = "feedback";
  $("next").hidden = true;
  var submit = $("submit");
  submit.hidden = false;
  submit.disabled = true;
  renderTicks();
  answer.focus();
}

function begin() {
  round.setId = selectedSet();
  round.seed = readSeed();
  round.items = drawSet(round.setId, 10, round.seed);
  round.index = 0;
  round.correct = 0;
  showPanel("round");
  renderProblem();
}

function finish() {
  window.clearTimeout(round.timer);
  var key = "stepmath-demo-best-" + round.setId;
  var prev = 0;
  try {
    prev = Number(localStorage.getItem(key) || 0);
    if (round.correct > prev) localStorage.setItem(key, String(round.correct));
  } catch (error) {
    prev = 0;
  }
  var best = Math.max(prev, round.correct);
  showPanel("done");
  $("score").textContent = round.correct + " / 10";
  $("best").textContent = prev > 0 && round.correct > prev
    ? SM.t("drill.record", { n: String(prev) })
    : SM.t("drill.best", { n: String(best) });
  var lesson = $("done-lesson");
  lesson.href = SETS[round.setId].lesson;
  lesson.textContent = SM.t("drill.lesson", { label: SM.t(SETS[round.setId].labelKey) });
  $("again").focus();
}

function advance() {
  if (!round.locked) return;
  round.locked = false;
  window.clearTimeout(round.timer);
  if (round.index >= 9) finish();
  else {
    round.index += 1;
    renderProblem();
  }
}

function grade() {
  if (round.locked) return;
  var raw = $("answer").value.trim();
  if (!raw) return;
  round.locked = true;
  var item = round.items[round.index];
  var ok = raw === item.answer || Number(raw) === Number(item.answer);
  var feedback = $("feedback");
  var answer = $("answer");
  $("submit").disabled = true;
  if (ok) {
    round.correct += 1;
    feedback.className = "feedback is-ok";
    feedback.textContent = SM.t("msg.ok");
    round.timer = window.setTimeout(advance, 450);
  } else {
    answer.classList.add("is-bad");
    feedback.className = "feedback is-bad";
    feedback.textContent = SM.t("msg.bad", { n: item.answer });
    $("submit").hidden = true;
    var next = $("next");
    next.hidden = false;
    next.textContent = round.index === 9 ? SM.t("drill.results") : SM.t("drill.next");
    next.focus();
  }
}

function pushDigit(digit) {
  if (round.locked) return;
  var answer = $("answer");
  if (answer.value.length >= 8) return;
  answer.value += digit;
  answer.classList.remove("is-bad");
  $("submit").disabled = false;
}

function backspace() {
  if (round.locked) return;
  var answer = $("answer");
  answer.value = answer.value.slice(0, -1);
  $("submit").disabled = answer.value.length === 0;
}

function buildPad() {
  var pad = $("pad");
  ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "del"].forEach(function (key) {
    var button = document.createElement("button");
    button.type = "button";
    button.className = "key" + (key === "0" ? " key-zero" : "") + (key === "del" ? " key-del" : "");
    button.textContent = key === "del" ? SM.t("drill.delete") : key;
    button.setAttribute("aria-label", key === "del" ? SM.t("drill.delete") : key);
    button.addEventListener("click", function () {
      if (key === "del") backspace();
      else pushDigit(key);
    });
    pad.appendChild(button);
  });
}

document.addEventListener("keydown", function (event) {
  if ($("round").hidden) return;
  if (event.metaKey || event.ctrlKey || event.altKey) return;
  var digit = event.key >= "0" && event.key <= "9";
  if (!digit && event.key !== "Backspace" && event.key !== "Enter") return;
  event.preventDefault();
  if (digit) pushDigit(event.key);
  else if (event.key === "Backspace") backspace();
  else if (!$("next").hidden) $("next").click();
  else grade();
}, true);

var preset = new URLSearchParams(location.search).get("set");
if (preset && SETS[preset]) {
  document.querySelector('input[name="set"][value="' + preset + '"]').checked = true;
}
writeBlurb();
buildPad();
document.querySelectorAll('input[name="set"]').forEach(function (input) {
  input.addEventListener("change", writeBlurb);
});
$("answer").addEventListener("input", function () {
  if (round.locked) return;
  $("submit").disabled = $("answer").value.length === 0;
});
$("start").addEventListener("click", begin);
$("submit").addEventListener("click", grade);
$("next").addEventListener("click", advance);
$("again").addEventListener("click", function () {
  history.replaceState(null, "", location.pathname + "?set=" + round.setId);
  begin();
});
$("change-set").addEventListener("click", function () {
  showPanel("gate");
  $("start").focus();
});

document.addEventListener("stepmath-lang", function () {
  writeBlurb();
  var del = document.querySelector("#pad .key-del");
  if (del) {
    del.textContent = SM.t("drill.delete");
    del.setAttribute("aria-label", SM.t("drill.delete"));
  }
  if (!$("round").hidden && round.items.length) {
    $("progress").textContent = SM.t("drill.progress", {
      i: String(round.index + 1),
      label: SM.t(SETS[round.setId].labelKey)
    });
    if (!$("next").hidden) {
      $("next").textContent = round.index === 9 ? SM.t("drill.results") : SM.t("drill.next");
    }
    if (round.locked) {
      var item = round.items[round.index];
      var ok = $("feedback").classList.contains("is-ok");
      $("feedback").textContent = ok ? SM.t("msg.ok") : SM.t("msg.bad", { n: item.answer });
    }
  }
  if (!$("done").hidden) {
    var prev = 0;
    try { prev = Number(localStorage.getItem("stepmath-demo-best-" + round.setId) || 0); } catch (error) {}
    $("best").textContent = prev > 0 && round.correct > prev
      ? SM.t("drill.record", { n: String(prev) })
      : SM.t("drill.best", { n: String(Math.max(prev, round.correct)) });
    $("done-lesson").textContent = SM.t("drill.lesson", { label: SM.t(SETS[round.setId].labelKey) });
  }
});

window.StepMathDrill = {
  sets: SETS,
  draw: drawSet
};

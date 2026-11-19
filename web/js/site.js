/* 商店上架后，把空字符串换成 App Store / Google Play 的地址。 */
var STORE_URLS = {
  appStore: "",
  googlePlay: ""
};

function sameNumber(raw, expected) {
  if (raw === expected) return true;
  if (raw === "" || expected === "") return false;
  var a = Number(raw);
  var b = Number(expected);
  return Number.isFinite(a) && Number.isFinite(b) && a === b;
}

function applyStores() {
  var links = document.querySelectorAll("[data-store]");
  for (var i = 0; i < links.length; i++) {
    var link = links[i];
    var url = STORE_URLS[link.getAttribute("data-store")] || "";
    var soon = link.querySelector(".soon");
    if (url) {
      link.setAttribute("href", url);
      link.setAttribute("target", "_blank");
      link.setAttribute("rel", "noopener noreferrer");
      link.classList.remove("is-pending");
      link.removeAttribute("aria-disabled");
      if (soon) soon.hidden = true;
    } else {
      link.classList.add("is-pending");
      link.setAttribute("aria-disabled", "true");
      if (soon) soon.hidden = false;
    }
  }
}

function digitsOnly(input) {
  var clean = input.value.replace(/\D/g, "").slice(0, 8);
  if (clean !== input.value) input.value = clean;
}

document.addEventListener("click", function (event) {
  var link = event.target.closest("a.is-pending");
  if (!link) return;
  event.preventDefault();
  var row = link.closest(".store-row");
  var note = row && row.querySelector(".store-note");
  if (!note) return;
  note.hidden = false;
  note.textContent = window.SM ? SM.t("store.note") : "Store links open soon.";
});

document.addEventListener("input", function (event) {
  var input = event.target;
  if (input.matches && input.matches("input.digits")) digitsOnly(input);
});

document.addEventListener("submit", function (event) {
  var form = event.target;
  if (!form.matches || !form.matches("form.try")) return;
  event.preventDefault();
  var expected = form.getAttribute("data-answer") || "";
  var input = form.querySelector("input");
  var msg = form.querySelector(".try-msg");
  var steps = form.querySelector(".try-steps");
  var raw = (input.value || "").trim();
  msg.hidden = false;
  if (!raw) {
    msg.className = "try-msg";
    msg.textContent = SM.t("msg.empty");
    return;
  }
  var ok = sameNumber(raw, expected);
  input.classList.toggle("is-bad", !ok);
  msg.className = ok ? "try-msg is-ok" : "try-msg is-bad";
  msg.textContent = ok ? SM.t("msg.ok") : SM.t("msg.bad", { n: expected });
  if (steps) steps.hidden = false;
});

document.addEventListener("stepmath-lang", function () {
  document.querySelectorAll(".store-note").forEach(function (note) {
    if (!note.hidden) note.textContent = SM.t("store.note");
  });
});

applyStores();

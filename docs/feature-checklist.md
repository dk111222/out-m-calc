# v1 Feature Checklist

Status key: `[ ]` not started · `[~]` in progress · `[x]` done

Source of truth: [需求功能书.md](./需求功能书.md)

## Platform & auth

- [ ] Responsive English web app (mobile-first browser)
- [ ] Parent signup (email, password ≥10, guardian + consent checkboxes with timestamp)
- [ ] Parent login / logout
- [ ] Add up to 3 learners (nickname 1–16 chars, grade K–5)
- [ ] Learner picker (tap nickname; no practice PIN)

## Practice session

- [ ] Full-screen one problem + numeric keypad
- [ ] Optional one-line draft (“work”, ≤16 chars) for marked skills only
- [ ] ~4 minute timer from first problem; finish current item before end screen
- [ ] Correct: ~200ms check, no sound reward
- [ ] Incorrect: equation + answer + ≤12-word strategy; Continue after 1.5s
- [ ] Session rules: 1 new skill (2–4 items); pinned unmastered first; spacing ≥4; 3 misses/day/skill stop
- [ ] End summary + “another set” (no auto-extend) + “show parent”

## Generators & mastery

- [ ] Generators for all ladder ids in the PRD table
- [ ] Division only as `:div` after related multiply mastery
- [ ] Mastery: 5/6 correct across ≥2 US-Eastern calendar days
- [ ] No reaction-time UI, badges, percentiles, or “on grade level”

## Parent & account

- [ ] Home cards: last date, 7-day session count, mastered / learning / not started
- [ ] Skill list + last ≤10 attempts; pin ≤5 unmastered skills
- [ ] Nickname / grade settings only
- [ ] CSV export of attempts
- [ ] Delete learner (with confirm); delete account (30-day undo)

## Billing

- [ ] 14-day trial, no card
- [ ] Paywall only after trial when tapping Start
- [ ] Annual $59 (primary) / monthly $7.99 (secondary) via web checkout
- [ ] Cancel renewal; freeze after 30 unpaid days (keep mastery)

## Explicitly out of v1

- Fact grids, timed badges, placement quiz, pets/leaderboards, speech, store binaries, LLM, photo grading, India, UK MTC, class codes

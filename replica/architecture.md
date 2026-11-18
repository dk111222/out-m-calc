# Architecture: StepMath (rebuild of Math Tricks + Speed Drill)

Flutter Android + iOS only. No web, no React Native, no Next.js.

Sources: `replica/recon.md`, `replica/features.csv`, `docs/stepmath-requirements.md`. `brief.md` is not in the repo. Product boundary for this file is the recon map plus the constraints in the architect request: two modules, US mental-math tricks, offline first, multiple child profiles, weak-item review, PDF worksheet and certificate, COPPA/GDPR, no forced login, telemetry off by default.

Original screens this build maps: MT-S03, MT-S04, MT-S05, MT-S06, MT-S07, MT-S08, SS-S01, SS-S03, SS-S05. SS-S02, SS-S04, YouTube, and the coin lock are not built.

## Stack

| layer | choice | why |
| --- | --- | --- |
| app | Flutter + Dart, Android and iOS | One codebase for both stores. No web target is registered |
| architecture | Clean Architecture, feature-first | Domain has no Flutter or Hive imports. UI cannot write a box directly |
| state | Riverpod | One provider graph for the active learner, the open round, and adult vs child mode |
| routing | go_router | Routes match the page list in the requirements. Child routes cannot open wipe or purchase |
| local store | Hive | Offline first. No account, so there is no server database |
| layout | flutter_screenutil | Phone and tablet from MT-S02 and MT-S07 share one layout scale |
| sound | audioplayers | Local asset cues and optional read-aloud. No streamed audio |
| pdf | pdf + printing | Worksheet and certificate files are generated on device |
| locale | intl | Local dates for streaks, grade labels, and currency symbols on grade 5 items |
| auth | none | COPPA: a K–5 app does not require an account. A 4-digit parent code is a local hash, not a login |
| payments | none in the first slice | Print and extra learners can later be a store entitlement flag in `device_settings`. No Stripe |
| email | none | No addresses are collected |
| jobs | none on a server | Day rollover and due reviews run when the app resumes |
| hosting | app stores only | The binary is the product. Reference screenshots in `replica/screens/` are not assets of the app |

One store. Hive boxes are the database. Trick text ships inside the app as an asset, not as rows the user can edit.

## Layout

```
lib/
  app/                  go_router, ProviderScope bootstrap
  core/                 Clock, Id, Result, ParentGate
  features/
    learners/           domain, data, presentation
    math_tricks/        lessons, guided steps, final answers, step locator
    speed_drill/        setup, timer or count, pause, personal best
    review/             weak items and spaced due items
    export/             worksheet PDF, certificate PDF
    privacy/            pin, telemetry flag, wipe
```

Each feature has `domain/` (entities, repository interfaces, use cases), `data/` (Hive adapters, repository implementations), and `presentation/` (pages, Riverpod notifiers). A presentation class does not import `hive`.

## Schema

Runtime: 9 Hive boxes plus one read-only trick catalog in assets. Access rules: every use case takes `learnerId` from the adult-selected or child-locked session. Repositories refuse a query whose `learnerId` is not that session. There is no Postgres row level security. The parent code gates wipe, learner delete, and purchase. Child mode cannot open those routes.

Logical contract, including delete behavior, is `replica/schema.sql`. That file is not applied to a server.

| box | typeId | key | delete rule |
| --- | --- | --- | --- |
| learners | 1 | learner id | deleting a learner deletes that child's attempts, wrong items, speed rounds, mastery, assignments, snapshots, certificates |
| device_settings | 2 | `device` | singleton. Wipe deletes it last and writes a fresh row with `telemetry_enabled = false` |
| attempts | 3 | attempt id | cascade from learner. A trick asset id is not a foreign key to a box |
| wrong_items | 4 | wrong item id | cascade from learner and from the source attempt |
| speed_rounds | 5 | round id | cascade from learner |
| mastery | 6 | `learnerId:trickId` | cascade from learner |
| assignments | 7 | `learnerId:localDate` | one open assignment per learner per local day. Replacing today's assignment marks the previous `replaced` |
| session_snapshots | 8 | learner id | one in-progress learn or speed round. Cleared when the round completes |
| certificates | 9 | certificate id | cascade from learner. PDF bytes are not stored; the file is regenerated |

`created_at` and `updated_at` are UTC `DateTime`s. Local calendar dates are stored as `YYYY-MM-DD` strings computed in the device zone. Money, when a grade 5 item shows a bill, is integer cents plus a currency code. The parent code is stored as a hash, never as four digits.

Trick catalog (`assets/tricks/catalog.json`) fields: `id`, `grade`, `operation`, `title`, `applies_when`, `not_when`, `steps[]`, `example`, `short_range`, `standard_range`, `acceptance_items[5]`. It is not a Hive box. Missing catalog copy blocks the build of that trick.

Hard constraints the recon requires:

- Two writes for the same final answer cannot both increment mastery. The attempt id is created before grading, and the repository ignores a second submit with that id.
- A local day has one streak increment. Completing both a lesson and a speed round on the same local date still adds one day.
- Kindergarten speed default is count 10, not a 3-minute timer. Grades 3–5 default to 180 seconds. The learning module never starts a countdown.
- A resumed snapshot keeps the generated prompt list. Opening the app does not draw a new set.
- Wrong items with `reviewed_ok = true` stay stored and leave the default queue.
- Telemetry stays false until an adult turns it on. The first build does not ship an analytics SDK, so the flag has nothing to call.

## API

There is no HTTP API and no call to Math Tricks or 速算训练. These are go_router routes and the use case each one runs.

| route | does | who | input | output | flow |
| --- | --- | --- | --- | --- | --- |
| `/start` | Choose adult role and create the first learner | first launch | name, grade | learner id | F01 |
| `/adult` | List learners and today's assignment | adult | — | learners, assignments | F01 |
| `/assign/:learnerId` | Save today's learn trick or speed config | adult | kind, trickId or speed config | assignment | F01 |
| `/child` | Show the two module cards | child session | learner id | assignment, snapshot if any | F02 F03 |
| `/tricks` | List tricks for the learner grade | child or adult | grade | catalog slice | F02 |
| `/tricks/:id` | Show steps, applies, counterexample | child or adult | trick id | trick | F02 |
| `/practice/:id/guided` | Record each intermediate | child | step index, value | correct or failed step | F02 |
| `/practice/:id/final` | Record the final answer | child | answer | correct, or handoff to locate | F02 |
| `/practice/:id/locate` | Replay steps until the first miss | child | step values | failed step, wrong item | F02 |
| `/practice/:id/done` | Close the learn round and update mastery | child | — | correct count, next trick | F02 |
| `/speed/setup` | Edit limit mode, digits, operation | adult, or child if unassigned | config | speed config | F03 |
| `/speed/run` | Run the round, pause, grade | child | answers | correct count | F03 |
| `/speed/done` | Compare with that learner's best | child | — | correct count, best | F03 |
| `/review` | List weak items by date and trick | adult or child | filter | wrong items | F04 |
| `/export/worksheet` | Build a PDF of steps, 20 items, answers | adult | trick id | PDF path | F05 |
| `/export/certificate` | Build a PDF certificate for a mastered trick or speed best | adult | learner id, trick or round | PDF path | F05 |
| `/settings` | Pin, telemetry, wipe, restore | adult after pin | — | device settings | F06 |

Webhooks in: none. Webhooks out: none.

Jobs, all on app resume, no schedule while the process is dead:

- `rollLocalDay`: if the local date changed, expire an unfinished snapshot from yesterday and apply one weekly streak skip if one remains.
- `markDueReviews`: mastery dates plus 3 and 14 local days become due review items.
- No reminder notification in this stack. `flutter_local_notifications` is not an approved package.

## The parts that bite

- Time zones: streaks, assignments, and "today" use the device zone via `intl`. Instants are UTC. A traveler crossing midnight can complete yesterday's snapshot only until the next local midnight; then it expires.
- Idempotency: finish-round and streak increment key off `learnerId + localDate`. A second finish is a no-op.
- Races: the keypad submit is serialized in the practice notifier. The same attempt id cannot be graded twice.
- Offline: catalog, audio, boxes, and PDF generation work with airplane mode on. There is no sync queue.
- COPPA / GDPR: no account, no email, no advertising id, no analytics SDK. Display name is optional and local. Certificates print the display name or "Learner". Wipe removes every box. Telemetry default is false and the first build has no sink for it.
- Multi-child: a repository method without a learner id does not exist. Switching child drops the in-memory practice state of the previous child; the snapshot box keeps each child's round.
- Parent gate: the pin hash is checked before `/settings` destructive actions and before leaving child mode back to `/adult`. Four wrong tries lock the gate for 60 seconds on device.
- Files: a worksheet is one trick, 20 problems, one answer page. Generation refuses a second trick in the same file. Audio files are bundled assets under `assets/audio/`, not downloaded.
- Search: the trick list is the grade catalog filtered in memory. No full-text index.
- Realtime and email: not used.
- Hive migrations: `typeId` values above are fixed. A new field needs a new optional adapter field, not a reused type id.

## Build order

1. Vertical slice. Screens `/start`, `/child`, `/tricks/:id`, `/practice/:id/guided`, `/practice/:id/final`, `/practice/:id/done`. Boxes: `learners`, `device_settings`, `attempts`, `session_snapshots`. Asset: Make 10 for grade 1. Proves Flutter, Riverpod, go_router, and Hive on both platforms. No web folder.
2. Must-haves. Speed drill `/speed/setup`, `/speed/run`, `/speed/done` with grade defaults. Review box and `/review`. Step locator. Resume snapshot. Parent pin and wipe. Portrait and landscape keypad. No ads on those routes.
3. Should-haves. Mastery at 90% of the last 20 final answers. Due reviews on day 3 and 14. Worksheet PDF and certificate PDF. Weekly stats computed locally. Second learner. Streak skip. Read-aloud through audioplayers.
4. Fixes from replica-entrepreneur. Not run yet. Do not add YouTube, coins, the public leaderboard, or abacus flash when those notes arrive unless the recon skip rows are explicitly reopened.

## Next

`/replica-design` can name the visual tokens. The build after that follows the folder layout and the routes in this file, still Flutter only.

# Bugs: StepMath

Build under test: `e3c0031`, plus uncommitted edits. Device: Flutter widget tests at 390×844, and one unit test under `TZ=America/Los_Angeles`. Date: 2026-11-19.

No open S1. No open S2.

### BUG-001: streak and review dates slip across daylight saving

- Severity: S3
- Flow / case: F01-E10
- Screen: practice home, review dates
- Build: `e3c0031`  Browser / device: unit test, `TZ=America/Los_Angeles`

Steps
1. Set the process zone to America/Los_Angeles.
2. Ask for the day gap from 2026-03-07 to 2026-03-09.
3. Add one day to 2026-11-01.

Expected: the March gap is 2 days. 2026-11-01 plus one day is 2026-11-02.
Actual: before the fix, the March gap was 1, and the fall-back add landed on 2026-11-01 again. Local `DateTime` arithmetic crossed the spring-forward and fall-back hours.
Evidence: `test/stepmath_test.dart`, "a calendar gap stays on dates when the clock springs or falls". First run expected 2 and got 1. The same test passes after the civil-date change, including under Pacific time.
Suspected cause: `dayGap` and `addDays` used local `DateTime` differences.
Status: fixed in the working tree (`lib/domain/core.dart`, civil UTC dates). Not committed. The failing test is kept and passing.

### BUG-002: guest form told the parent the blank name would be Learner

- Severity: S4
- Flow / case: F01-E3
- Screen: new learner, guest
- Build: `e3c0031`  Browser / device: widget test, 390×844

Steps
1. From the start screen, tap Try as a guest.
2. Read the helper under Name.

Expected: "Leave this blank to use Guest."
Actual: the guest form used the parent helper, "Leave this blank to use Learner and a number." A blank save still stored Guest.
Evidence: `e2e/flows_test.dart`, "F01-E3 grade is required and a guest blank name is Guest". The assertion on the Guest helper failed before the copy change and passes after it.
Suspected cause: one helper string for both forms.
Status: fixed in the working tree (`lib/pages/home_pages.dart`). Not committed. The test is kept and passing.

### BUG-003: semibold is a copy of the regular font

- Severity: S4
- Flow / case: visual, every screen that asks for semibold
- Screen: app theme
- Build: `e3c0031`  Browser / device: files on disk

Steps
1. Compare `assets/fonts/SourceSans3-Regular.ttf` and `assets/fonts/SourceSans3-Semibold.ttf`.

Expected: the semibold file is a heavier cut.
Actual: the two files are byte-identical, 431196 bytes each. `cmp` exits 0.
Evidence: `cmp assets/fonts/SourceSans3-Regular.ttf assets/fonts/SourceSans3-Semibold.ttf`.
Suspected cause: the semibold download failed during the build and the regular file was copied into its place.
Status: open. Text still renders. Titles do not look heavier than body text.

## To check

Not filed as bugs. None of these were reproduced.

- Hardware keyboard only, TalkBack, and VoiceOver.
- Airplane mode. The app has no HTTP client; the radio was not switched off.
- System print sheet, and the certificate page with a real issued certificate.
- Delete a learner and confirm that child's rows are gone.
- Percent lesson screen: submit 0.80 and look at the breakdown. Grading is tested; the screen was not opened.
- Empty submit and double submit on a speed item.
- Landscape on a phone, and a human pass over `replica/clone-screens/`.
- Sound and read-aloud on a device. Automated runs mute both, because the audio plugin throws `MissingPluginException` in a widget test.
- Whether the screenshot PNGs rewritten by `test/screenshots_test.dart` differ only by capture noise.

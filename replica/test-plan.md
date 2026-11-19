# Test plan: StepMath

Build: `e3c0031` plus uncommitted fixes in `lib/domain/core.dart` and `lib/pages/home_pages.dart`  
Date: 2026-11-19  
Env: local Flutter widget tests, one temp Hive store, phone surface 390×844. No seed server.

The clone is Android and iOS only. There is no web target and no HTTP API, so Playwright, axe, and HTTP 5xx checks do not apply. Specs live in `e2e/flows_test.dart` and use visible text, tooltips, and widget types. A Flutter exception fails the test. Sound and read-aloud are muted in these runs so the audio plugin is never created.

Recon flows are F01–F06. Clone-only cases use a C prefix.

| case | flow | type | steps | expected | auto | result |
| --- | --- | --- | --- | --- | --- | --- |
| F01-H1 | F01 learn a trick | happy | Parent or teacher, name Ava, Grade 1, Save, Assign, Make 10, Save today, open Ava, Math Tricks, Start practice, enter the first step, Submit | Step 2 is on screen. The method page showed Use this when and Not for | e2e | pass |
| F01-E1 | F01 | edge: empty and very long name | Save with a blank name twice. Save a name of 80 copies of 北 | First child is Learner, second is Learner 2, long name is cut at 60 characters | e2e | pass |
| F01-E2 | F01 | edge: emoji and accents | Name Léa 数学🎒, Kindergarten, Save | That name is on the learner list | e2e | pass |
| F01-E3 | F01 | edge: empty grade, guest blank name | Open the parent form. Go Back. Try as a guest. Clear the name. Save | Save stays disabled until a grade is chosen. Guest helper says "Leave this blank to use Guest." Home shows Guest | e2e | pass |
| F01-E4 | F01 | edge: double click on submit | On a correct step, tap Submit twice before the advance | The step index moves once, to Step 2 | e2e, inside F01-H1 | pass |
| F01-E5 | F01 | edge: empty keypad | On Step 2, tap Submit with no digits | Stays on Step 2 | e2e, inside F01-H1 | pass |
| F01-E6 | F01 | edge: back mid-flow | From the new-learner form, tap Back | Start screen, with Try as a guest | e2e, inside F01-E3 | pass |
| F01-E7 | F01 | edge: refresh mid-flow | Start Make 10, boot a new controller, resume | Same prompt as before the restart | e2e C06-H1 | pass |
| F01-E8 | F01 | edge: second user's data | Record a miss and a speed best for Ava. Open review as Ava. Read Ben's best | Ava's review shows 8 + 7 and not Ben's 9 + 6. Ben's best stays 0. A child session cannot read the other child's wrongs | e2e F05-H1, F03-E2 | pass |
| F01-E9 | F01 | edge: mobile width | Run the practice flow at 390×844 | Submit, Your answer, and Delete are on screen | e2e | pass |
| F01-E10 | F01 | edge: time zones and daylight saving | dayGap 2026-03-07 to 2026-03-09, addDays across the spring-forward and fall-back dates | Gap is 2. 2026-03-08 plus 1 day is 2026-03-09. 2026-11-01 plus 1 day is 2026-11-02 | unit, `TZ=America/Los_Angeles` | pass |
| F01-E11 | F01 | edge: keyboard only | Drive the keypad with hardware keys only | | manual | not run |
| F01-E12 | F01 | edge: screen reader | Your answer and Delete are on screen. TalkBack and VoiceOver were not started | | manual | not run |
| F01-E13 | F01 | edge: two tabs at once | One Flutter isolate. There is no second tab | | n/a | n/a |
| F01-E14 | F01 | edge: slow network | The app does not call a server | | n/a | n/a |
| F01-E15 | F01 | edge: offline | No network client. Airplane mode was not toggled on a device | | manual | not run |
| F01-N1 | F01 | negative: permission denied | As the child, open /settings and call wipe | Stays on Today's practice. Wipe returns false. Delete-all is absent | e2e | pass |
| F01-N2 | F01 | negative: wrong parent code | Set 1234. Enter 0000 four times. Enter 1234 while locked. Advance 61 seconds. Enter 1234 | The fourth miss locks the gate for 60 seconds. The right code works after the lock | e2e | pass |
| F01-N3 | F01 | negative: wrong step | On Step 2, enter 9 and Submit | Not quite. The step index stays 1 | e2e, inside F01-H1 | pass |
| F01-N4 | F01 | negative: card declined | No payments and no Stripe | | n/a | n/a |
| F01-N5 | F01 | negative: deleted record | Delete a learner, then open that learner's practice | | manual | not run |
| F02-H1 | F02 percent breakdown | happy | Build 1% of 80. Compare 0.80 with the final. Round-trip the problem JSON | Last step is 0.8. 0.80 matches. The percent lesson screen was not opened | unit | pass |
| F02-E1 | F02 | edge: trailing zero | Compare 6.3 and 6.30 | Same answer | unit | pass |
| F02-E2 | F02 | edge: list from the skill | Empty, long, emoji, tabs, double submit, back, refresh, network, offline, session, second user, DST, mobile, keyboard, screen reader | Grading and the Make 10 locate screen cover empty submit, double submit, and a wrong step. The percent diagram itself was not clicked. Shared edges match F01 | unit plus F01-H1 | pass for grading; diagram not run |
| F02-N1 | F02 | negative: wrong final | A wrong final opens the step check and a second submit is ignored | Locate stays open | unit | pass |
| F02-N2 | F02 | negative: card declined | No payments | | n/a | n/a |
| F03-H1 | F03 3-minute speed | happy | Grade 3 child. Start the grade default. Open the run. Pause | Time left and the prompt show. Pause replaces the prompt with the stopped-clock line | e2e | pass |
| F03-E1 | F03 | edge: kindergarten cap | Generate speed addition for grade K | Every sum is 10 or less | unit | pass |
| F03-E2 | F03 | edge: second user's data | Finish a round of 12 for Ava | Ben's personal best stays 0 | e2e | pass |
| F03-E3 | F03 | edge: empty and double submit on a speed item | Submit an empty draft, then submit twice | | manual | not run |
| F03-E4 | F03 | edge: DST, mobile, keyboard, screen reader | Clock is civil dates. Surface is 390 wide. TalkBack not run | DST and width covered. Keyboard and screen reader match F01-E11 and F01-E12 | unit and e2e | pass for dates and width; keyboard and reader not run |
| F03-N1 | F03 | negative: other child's board | Same as F03-E2 | Ben does not inherit Ava's best | e2e | pass |
| F04-H1 | F04 read the method, then practice | happy | On Make 10, read the method, then Start practice | Use this when and Not for are on the page, then the keypad | e2e, inside F01-H1 | pass |
| F04-E1 | F04 | edge: print from the method page | Open the worksheet action on the method page and the system print sheet | | manual | not run |
| F04-N1 | F04 | negative: child opens parent export | Child route guard | Child cannot open settings. Export was not tapped from the method page in this run | e2e F01-N1 | pass for settings |
| F05-H1 | F05 review wrongs | happy | Ava misses 8 + 7. Ben misses 9 + 6. Open review as Ava. Repair every step of Ava's item | Ava sees 8 + 7 and not 9 + 6. After repair the item is out of the open queue and the row remains | e2e | pass |
| F05-H2 | F05 print a worksheet | happy | Build a worksheet of 20 Make 10 problems. Build one with 19 | PDF bytes are longer than 500. 19 problems throws | e2e | pass |
| F05-E1 | F05 | edge: second user's data | Child session reads the other learner's wrongs | StateError. The row is not on screen | e2e, inside F05-H1 | pass |
| F05-E2 | F05 | edge: system print dialog | Hand the PDF to the OS print sheet | Bytes are built. The sheet was not opened | manual | not run |
| F05-N1 | F05 | negative: deleted wrong | Delete the learner who owns a wrong, then open review | | manual | not run |
| F06-H1 | F06 two players | happy | Open the child home and search the tree | No Two players control. No 500-coin lock | e2e | pass |
| F06-E1 | F06 | edge: a live two-player match | The clone does not include two players | | n/a | n/a |
| C06-H1 | resume today's practice | happy | Start Make 10. Boot a new controller for the same child. Resume | The prompt matches the snapshot | e2e | pass |
| C06-E1 | resume | edge: snapshot from yesterday | Save a snapshot dated yesterday. Boot | The snapshot is cleared | e2e | pass |

## Same edge list on F02–F06

| edge | F02 | F03 | F04 | F05 | F06 |
| --- | --- | --- | --- | --- | --- |
| empty input | pass on the learn keypad | not run on a speed item | same keypad as F01 | repair uses the same keypad | n/a |
| very long input | n/a on a numeric answer | n/a | n/a | n/a | n/a |
| emoji and accents | n/a on a numeric answer | n/a | n/a | n/a | n/a |
| two tabs | n/a | n/a | n/a | n/a | n/a |
| double click on submit | pass on learn | not run on speed | pass on learn | pass on the repair loop | n/a |
| back mid-flow | not run on the percent page | pause covers leaving the problem | pass via Back on the form | not run | n/a |
| refresh mid-flow | not run | not run | covered by C06-H1 for learn | not run | n/a |
| slow network | n/a | n/a | n/a | n/a | n/a |
| offline | manual, same as F01-E15 | manual | manual | manual | n/a |
| expired session | pin lock is F01-N2; no account session | same | same | same | n/a |
| second user's data | not run on a percent item | pass | not run | pass | n/a |
| daylight saving | pass for streak and review dates | pass | pass | pass | n/a |
| mobile width | pass at 390 | pass at 390 | pass at 390 | pass at 390 | pass at 390 |
| keyboard only | not run | not run | not run | not run | n/a |
| screen reader | not run on a device | not run | not run | not run | n/a |
| wrong password | F01-N2 | same gate | same gate | same gate | n/a |
| card declined | n/a | n/a | n/a | n/a | n/a |
| permission denied | F01-N1 | F01-N1 | F01-N1 | child cannot read the other book | n/a |
| deleted record | not run | not run | not run | not run | n/a |

## Manual checklist

These were not driven on a device or emulator. They are not failures.

1. Hardware keyboard only through a practice item and a speed item.
2. TalkBack and VoiceOver on the keypad, including Your answer and Delete.
3. Airplane mode while learning, drilling, and exporting.
4. The system print sheet for a worksheet and for a certificate.
5. Delete one learner and confirm that child's practice, wrongs, and best are gone.
6. Open the percent trick, submit 0.80, and look at the breakdown.
7. Empty submit and a double submit on a speed item.
8. Landscape on a phone, and a visual pass of the widget screenshots in `replica/clone-screens/`.
9. Sound and read-aloud on a device. The automated runs mute both.

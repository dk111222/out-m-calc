# Design: StepMath

Flutter only. Tokens live in `replica/design/tokens.json`. This file is the spec the build uses. There is no Tailwind theme and no web stylesheet: the app target is Android and iOS.

Screens this system covers: MT-S03, MT-S04, MT-S05, MT-S06, MT-S07, MT-S08, SS-S01, SS-S03, SS-S05. Routes are the ones in `replica/architecture.md`.

## What was measured

Sampled from `replica/screens/` on 2026-11-19. These values are the originals. They are not the product palette.

| role on the original | measured | where |
| --- | --- | --- |
| lesson header | `#6A1E9A` | ios-01, about 6% down |
| drill header | `#1465C0` | ios-03 |
| page | `#F2F2F2` | ios-01 bottom |
| key well | `#EDEDED` | ios-03, about 78% down |
| digit link | `#0633FF` | ios-01 diagram |
| speed marketing blue | `#477BE7` | suan-suan/01 |
| dark header | `#002928` | play-10 |
| dark list | `#000000` | play-10 |

Greys in actual use: page `#F2F2F2`, key well `#EDEDED`, card `#FFFFFF`, a hairline near `#D1D1D1`. That is four neutrals plus pure black in the dark list. Spacing reads as an 8-point grid: card padding about 16, key gap about 8, header about 56. Radius on keys and cards is small, about 8. Type is a plain sans; the equation is the only large line, around 28–40. Motion on the stills is unknown; the product rule below replaces it.

The purple header, the bright blue, and the green wordmark stay out. A signature colour plus their card layout would copy trade dress. `accent` is a placeholder until `/replica-brand`.

## Colour

Low saturation. Paper, ink, and one grey-green. Step colours are for digit links only, and they stay dull.

Light: `bg #F4F1EA`, `surface #FFFFFF`, `surface-sunken #EBE6DC`, `border #DDD6C8`, `border-input #6B6458`, `text #1C2330`, `text-muted #5C564C`, `accent #2F5C55`, `on-accent #FFFFFF`, `danger #8C3330`, `success #1F5C40`, `warning #7A4E10`.

Dark: `bg #161A18`, `surface #222824`, `surface-sunken #1B201E`, `border #3C433E`, `border-input #C2B8A6`, `text #F3EFE6`, `text-muted #C9C1B3`, `accent #9DCDC2`, `on-accent #10211C`. Status and step colours swap to the `dark-*` values in the token file. Dark screens use a 1 px border instead of a shadow.

Step link colours, light on `surface`: `step-a #8C4038`, `step-b #2F5C73`, `step-c #2E5A3E`. Same roles in the dark theme use `dark-step-a/b/c`. One colour per step, reused in the sentence and in the diagram. No fourth colour, no glow.

Theme: `device_settings.theme_mode` is `system`, `light`, or `dark`. Default `system`. The child can change it from Settings. Changing theme does not reset a round.

## Type

Font: Source Sans 3 (OFL). Numerals use tabular figures everywhere, including the keypad, the timer, and the chart. Do not ship the original app's font file.

Scale, in logical pixels at Medium: 12/16/600, 14/20/400, 16/24/400, 20/28/600, 28/34/600, 40/48/600. The equation uses 40. Step titles use 20. Body and button labels use 16. Captions use 14. The chart label uses 12.

Font size is an app setting, not only the OS slider. `device_settings.text_scale` is `small` 0.9, `medium` 1.0, or `large` 1.15. Multiply the scale above. Then honour the OS text scaler and clamp the product to 1.3 so the keypad still fits. Key height stays at least 48 even when the label grows. The build adds `theme_mode` and `text_scale` to the device settings box.

## Space, radius, shadow, motion

Space: 0, 4, 8, 12, 16, 24, 32, 48. Screen padding 16. Gap inside a card 12. Gap between cards 16. Key gap 8.

Radius: controls 8, cards 12, dialog 16. The timer chip is a pill. Nothing else is a pill.

Shadow: light cards `0 1px 2px rgba(28,35,48,.06)`. Dialog `0 8px 24px rgba(28,35,48,.12)`. Dark theme drops both.

Motion: 120 ms for a colour or opacity change, 180 ms for a dialog. Ease-out only. No bounce, no confetti, no shake, no flip clock, no pulsing timer. A correct answer shows the word "Correct" and moves on. A wrong answer changes the border to `danger` and stays on the item.

## Layout

Phone width uses the full width minus 16 on each side. Header height 56. Tablet width from 600: the column maxes at 720 and centers. The keypad maxes at 480. Landscape practice (MT-S07): equation on the left, keypad on the right, same tokens. `flutter_screenutil` design size is 390 × 844. Do not scale the keypad below 48.

## Copy

American English. These strings are new. Do not reuse lesson sentences, coin labels, or the Chinese UI from the reference shots.

| spot | string |
| --- | --- |
| module one | Math Tricks |
| module two | Speed Drill |
| child home | Today's practice |
| lesson | Steps |
| when it works | Use this when |
| counterexample | Not for |
| answer prompt | Your answer |
| right | Correct |
| wrong | Not quite |
| locate | Check the step |
| keypad delete | Delete |
| speed time | Time left |
| speed count | Problems left |
| pause | Pause |
| best | Personal best |
| review | Wrong problems |
| empty review | No wrong problems yet |
| chart | Last 20 answers |
| print | Worksheet |
| award | Certificate |
| leave | Leave this round? |
| pin | Parent code |
| wipe | Delete all data on this device |
| theme | Appearance |
| type size | Text size |

Grade names: Kindergarten, Grade 1, Grade 2, Grade 3, Grade 4, Grade 5. Operations: Addition, Subtraction, Multiplication, Division.

## Components

### TrickCard

variants: lesson, assigned, mastered
sizes: full width of the column, min height 72
states: default, pressed (surface-sunken), focus (2 px `border-input` ring), disabled (muted title, no chevron), empty (the list shows "No tricks for this grade yet")
tokens: surface, border, radius md, title lg, caption sm in text-muted, padding 16
a11y: one button per card, name is the trick title plus the grade. Mastered adds "Mastered". Disabled cards are not focusable.
used on: `/tricks`, `/child`, `/tricks/:id` header
notes: no lock icon, no coin price, no video glyph. A mastered card shows the word Mastered, not a star burst.

### Keypad

variants: portrait (3 columns), landscape (same keys, right column)
sizes: key min 48 × 48, label xl. 0 spans two columns. Delete is the last key.
states: default, pressed (surface-sunken for 120 ms), focus (2 px ring), disabled while a submit is in flight. The label stays "Delete".
tokens: keys on surface, well is surface-sunken, gap 8, radius sm, digit text, Delete is text-muted
a11y: each key is a button named "1" through "9", "0", and "Delete". Entry is also accepted from a hardware keyboard. The live answer is one text field above the keys, announced when it changes. No key plays a tune. Optional tick is off unless read-aloud is on, and read-aloud speaks the problem, not each digit.
used on: `/practice/:id/guided`, `/practice/:id/final`, `/practice/:id/locate`, `/speed/run`
notes: learning mode shows no timer. Eight characters max. One decimal point. No minus key.

### TimerPanel

variants: time, count
sizes: height 48, full width of the practice column, or a 160-wide chip in landscape
states: running, paused, warning (under 30 seconds or under 3 problems: border becomes `warning`, the digits stay `text`), done, hidden (learning routes never mount it)
tokens: surface, border, radius pill, digits xl tabular, caption sm "Time left" or "Problems left"
a11y: the remaining value is announced at each minute and at 30, 10, and 0 seconds. Count mode announces every fifth problem. Pause is a separate button, "Pause".
used on: `/speed/run`, `/speed/setup` preview
notes: the digits swap in place. No sweep animation.

### ProgressChart

variants: last-20 bar, mastery caption
sizes: height 12 for the bar, full column width. Label row 24.
states: empty ("0 of 20"), in progress, mastered (the caption reads "Mastered", the bar stays the same shape), loading (a quiet bar in border colour, no spinner ring)
tokens: track is surface-sunken, fill is accent, radius sm, label xs
a11y: the bar is decorative. The text "18 of 20 correct" is the accessible name. Colour is not the only status.
used on: `/tricks`, `/practice/:id/done`, `/child`
notes: this is the last 20 final answers, not a 0/100 ladder. Width changes in 180 ms. No pie, no confetti.

### Dialog

variants: confirm, parent-code, destructive
sizes: width min(400, screen − 32), padding 24
states: open, submitting (primary button shows "Working" and stays named for the reader), error (the message under the field, `danger`), dismissed
tokens: surface, radius lg, shadow pop in light mode, title lg, body base, buttons height 48
a11y: focus moves to the title, then the first field. Escape or the system back closes a confirm dialog. A destructive dialog closes only from "Cancel" or after the code succeeds. Scrim is `text` at 40% opacity.
used on: leave round, pause, parent code, delete all data
notes: no illustration, no rating request, no sale. Strings from the copy table.

Buttons used inside the dialog and the primary actions: height 48, radius sm, primary is accent / on-accent, secondary is surface plus a border, destructive text is danger on surface. Focus ring 2 px `border-input`. Disabled drops to text-muted and does not submit.

## Contrast

`python contrast.py replica/design/tokens.json` — 39 pairs, 0 failing AA. Body pairs are above 4.5:1. Input borders are above 3:1. Step colours pass as text on the card, so a linked digit is readable without a second cue. Re-run the script after any palette change.

## Build notes

Map tokens to a Flutter `ThemeData` light and dark. Widgets read `ColorScheme` and `TextTheme`, not hex literals. Icons from a single open set (Phosphor or Material), drawn at 24, colour `text` or `on-accent`. No traced artwork from the screenshots.

Primitives are specified here and built with the first Flutter slice in `/replica-build`. This repo has no app target yet, so there is no design gallery route in this step.

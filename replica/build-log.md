# Build log

Date is 2026-11-19. Screens ship in one Flutter pass because the shell, Hive store, and practice machines are shared. A commit per screen would not compile on its own.

| ID | Route | Status | Missing | Harder than it looked |
|---|---|---|---|---|
| Loading | /loading | done | Screenshot is the post-boot start screen. The skeleton shows only while Hive is opening. | Boot redirect leaves this route before a tester can settle on it. |
| P01 | /start | done | | Guest and parent are both on this screen. |
| P02 | /learner/new | done | | Guest query fills the name Guest and enters child mode. |
| P03 | /adult | done | Empty adult list is unreachable: no learners stay on P01. | |
| P04 | /assign/:learnerId | done | | Later grades sit in a collapsed tile. |
| P05 | /child | done | | Two cards stay up when nothing is assigned. |
| P06 | /tricks | done | | Saved filter and a lock on later grades for a child. |
| P07 | /tricks/:id | done | | Diagram is colored digits plus a south icon, not a copied illustration. |
| P08 | /practice/:id/guided | done | | Same page as final and locate. Phase is in the route. |
| P09 | /practice/:id/final | done | | |
| P10 | /practice/:id/locate | done | | A wrong final stays wrong even if the later steps are typed correctly. |
| P11 | /practice/:id/done | done | | |
| P12 | /speed/setup | done | | Mixed is a real operation, not a second screen. |
| P13 | /speed/run | done | | A wrong speed answer moves on after 90ms so the clock stays meaningful. Learning still stops to locate the step. |
| P14 | /speed/done | done | | |
| P15 | /review | done | | |
| P16 | /settings | done | | Child sound, theme, and text size live on /prefs because settings can wipe the device. |
| Privacy | /settings/privacy | done | | |
| Report | /report/:learnerId | done | | Week is Monday through Sunday on the device calendar. |
| Worksheet | /export/worksheet | done | | Preview opens from the page. The file is one trick and 20 problems. |
| Certificate | /export/certificate | done | | |

Wider than the first cut:

- The decimal key replaced a zero key that spanned two columns, so the keypad stays a three-column grid.
- Source Sans 3 Semibold is a copy of Regular. The Semibold download failed. Headings use weight 600 but the file is the regular cut.
- Hive boxes store maps. The type ids in architecture.md are reserved and unused.
- Print and extra learners default to on. There is no purchase screen.
- Read-aloud uses bundled clips from macOS speech plus three generated tones. A missing clip is ignored.
- Parent code change asks for the current code, then a new code. A mismatched repeat does not erase the saved code.
- Haptics, two-player, placement, custom numbers, weekly mixed checkup, YouTube, coins, the public board, abacus, ads, accounts, and web are not in this build.

Screenshots in `replica/clone-screens` are widget renders at 390×844, plus the adult home at 1440. The certificate page has no still because that capture did not earn one.

<!-- Owner: C - Person C (Expenses, Dashboard, Documentation) -->
<!-- Description: Final video demo script, run-sheet, and camera/screen flow -->

# Demo Script

This follows section 9 of the team guide. The video is 10 to 15 minutes, one continuous recording, planned at 14:30. There is no slide deck, no team introductions, no cuts and no speed-ups. Every person speaks, and one person drives the phone at a time.

## Recording setup

- The **release APK** is installed on a **physical Android phone**. Build it with `flutter build apk --release`.
- Mirror the phone to the laptop with `scrcpy`. Put the Firebase Console next to it. Both must be legible at **1080p**.
- Record the laptop screen with OBS or a Meet/Zoom recording.
- Turn on Android **Show touches**. Turn on Do Not Disturb except for Changa. Keep the screen awake and the phone charged. Grant the notification permission beforehand.
- Use the headset microphone in a quiet room.
- Firebase Console tabs open: Authentication, and Firestore on `households`, `members`, `expenses`, `debts`, `chores`, `notifications`.

## Data to prepare before recording

| Item | Who |
|---|---|
| Three accounts, email-verified: Amara (admin), Bob, Chloe | A |
| One clean household with all 3 members, PIN known | B |
| Bob has some chore credits, so the credits preview is visible | E |
| One existing expense ("Rent", RWF 30,000, paid by Amara, equal split) with unpaid debts, **kept for D's nudge and settle segment**. C's expense is created live and deleted live, so D never depends on it | C |
| One recurring chore template ready to type, assigned across the household | E |
| Preferences set to the defaults (light theme, cash) so the change is visible | E |
| Sign-up test data: an empty field and a weak password, and a brand-new email for the real registration | A |

## The 7 required actions

| # | Required action | Shown by | Time |
|---|---|---|---|
| 1 | Cold-start launch | A | 0:00 |
| 2 | Register, log out, log in (and Google sign-in) | A | 0:30 to 2:45 |
| 3 | Visit every screen and rotate once | All | 12:45 to 14:30 |
| 4 | Create, read, update, delete in Firestore with the Console visible | C (expense) and E (chore) | C 5:15 to 7:45, E 10:15 to 12:45 |
| 5 | A state update that touches two widgets | C (dashboard balance and activity) and E (checkbox, credit badge, Harmony ring) | C 6:45, E 11:15 |
| 6 | Change a SharedPreferences setting, restart the app, show it persisted | E | 12:15 |
| 7 | Force a validation error and show the polite message | A (sign-up) and C (add expense) | A 0:45, C 5:15 |

## Timeline

| Time | Who | What |
|---|---|---|
| 0:00 to 2:45 | A | Force-stop the app and cold start it (#1). Onboarding. Sign up with an empty field and a weak password: polite errors (#7). Register properly, verify email screen, verify, log out, log in (#2). Log out, sign in with Google. Console: Authentication users. Show the `redirect` code in `app_router.dart`. |
| 2:45 to 5:15 | B | Create a household and show the PIN. Console: `households`, `householdPins`, `members`. Log in as the second account and join with the PIN. Manage Household: regenerate the PIN and show the change in the console. Show `docs/erd.png` next to the console, then one rule in `firestore.rules`. |
| 5:15 to 7:45 | C | See the click path below. |
| 7:45 to 10:15 | D | Debt & Nudge: the itemised breakdown. Send a nudge: the notification document appears in the console and the banner shows on the other device. Try again to show the cooldown message. Settle up with Mobile Money: the debts become `settled` in the console and the balance goes to 0. In a terminal: `flutter analyze` (0 issues) and the coverage summary. |
| 10:15 to 12:45 | E | Create a recurring chore: 4 documents appear in the console (Create). Complete one: the checkbox, the credit badge and the Harmony ring change together, and the member's credits change in the console (#5). Request a swap, accept it: the assignee changes (Update). Delete a chore (Delete). Preferences: change the theme and default payment method, **fully close the app**, reopen, still saved (#6). |
| 12:45 to 14:30 | All | A quick tour of every screen with one rotation to landscape (#3), about 20 seconds each: A auth and profile, B household and activity, C dashboard and sheets, D debts and alerts, E chores and preferences. Then GitHub (B): branches, merged PRs with reviews, the commit graph, the contributors page. A: the folder tree (presentation, domain, data) and why Cubit. D: `flutter test` passing. |

## C segment click path (5:15 to 7:45)

| Time | Do | Say |
|---|---|---|
| 5:15 | Tap the centre [+]. Tap Save with the title and amount empty | "Add Expense is a bottom sheet driven by a Cubit. Saving with nothing filled in gives a polite message, not a crash (#7)." |
| 5:40 | Enter "Groceries", RWF 12,000, category Groceries. Keep Equal split with all three | "An equal split of 12,000 over three people is 4,000 each, and the preview updates as I type." |
| 6:00 | Show the credits preview on Bob's row | "Bob has credits. One credit is RWF 10, and they are applied to his share automatically. The preview shows what he will actually owe." |
| 6:15 | Switch to Percent. Enter 50 and 40 for two people. Show the error. Fix it to add up to 100 | "A percent split must total 100. The form shows the problem and keeps Save disabled until it is fixed." |
| 6:40 | Switch back to Equal and save. Switch to the Console | "The expense, the debts and the reduced credits are written together in one transaction. Here is the expense document, its two debt documents, and Bob's credits now lower." |
| 6:55 | Go to the Dashboard | "The dashboard balance card and the activity list both updated without a refresh (#5). One Firestore stream feeds both through the DashboardCubit." |
| 7:10 | Open the expense. Show Who pays what | "Expense Details shows each person's share and payment status: paid the bill, pending, or covered by credits." |
| 7:20 | Edit the note and save. Show the `note` field change in the Console | "That is Update. Only the title and note can change, the amounts are fixed once debts exist." |
| 7:30 | Delete the expense and confirm. Show the expense and its debts gone in the Console, Bob's credits restored, and the dashboard updated | "That is Delete. The debts are removed and the credits are refunded in one transaction. If anyone had already paid, Delete would be disabled with an explanation, and the database enforces the same rule." |

Hand over to D at 7:45. If the delete is blocked, say why out loud and carry on.

## When something goes wrong

- Do not cut. Say what happened in one sentence, recover on camera, and keep going. Graders accept a visible, handled problem. They do not accept an edited video.
- If a tap does not register, pause for 2 seconds and tap again.
- If someone runs long, the next person starts when the previous one finishes. The 14:30 plan leaves a minute of safety under the 15-minute limit.

## What the graders look for

Say each of these out loud and show the code or the console:

- Widgets: why you chose them, and the variety (lists, cards, sheets, dialogs, tabs, chips, animations)
- Design match: the app next to Figma, small and large phones, landscape
- Navigation: how screens connect, the redirect rules, no back-stack surprises
- State management: the Cubit, the states, why no `setState`
- Clean Architecture: the three layers, where the logic lives
- ERD and database: the ERD next to the console, the rules, the indexes
- CRUD: every action visible in the console, and the UI updating instantly
- Authentication: both methods, errors, password reset, email verification, session persistence
- Testing: widget and unit tests running, the coverage number
- Preferences: saved and restored after a restart
- GitHub: branches, PRs with real reviews, balanced commits
- Validation: the rules and the polite messages

Everyone must be able to explain any file in the repo, including AI-written parts. Practise this before recording.

## Dry run and recording

- Full dry run with the release APK and `scrcpy`: **Thu 12 Nov**. Time each segment against the table above.
- Recording day: after the dry run is clean.
- Evidence screenshots go in `docs/evidence/`: dashboard, add expense, expense details, debts, chores, activity, plus a green CI run and the `flutter test` summary.
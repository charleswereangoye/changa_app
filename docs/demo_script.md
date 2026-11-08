# Demo Script

Target length: 5 minutes. Record the phone screen, then record the voice-over in one clean take. Speak slowly. Show the screen for 2 seconds before talking about it.

## Before recording

| Check | Done |
|---|---|
| Latest `main` pulled, `flutter analyze` and `flutter test` green | |
| Release APK or `flutter run` on one real Android phone, battery above 50%, Do Not Disturb on | |
| Three accounts ready: Amara (admin), Bob, Chloe. Bob already joined with the PIN. Chloe NOT joined yet | |
| Firestore console open in a browser tab on the household's `expenses` and `debts` collections | |
| Phone language English, clock showing, no other notifications visible | |
| Bob has some credits (so the credit discount shows in the demo) | |

Keep Amara signed in on the phone. A second phone or emulator signed in as Bob is useful for the nudge and settle scenes.

## Run-sheet

| # | Time | Screen | What to do | What to say |
|---|---|---|---|---|
| 1 | 0:00 | Title card | Show the app name and team | "This is Changa, a mobile app that helps student housemates share bills and rotate chores. We are Group 32." |
| 2 | 0:15 | Login, Home | Sign in as Amara. Dashboard opens | "Amara signs in. The dashboard shows the household's Harmony Score, what she is owed, what she owes, and the latest activity." |
| 3 | 0:40 | Household | Open household details. Show the 6-digit PIN | "Amara created the household and shares this PIN. A housemate joins with it. Only one household per person." |
| 4 | 1:00 | Join | On the second phone, Chloe joins with the PIN. Return to Amara's phone | "Chloe joins with the PIN. She appears in the household straight away." |
| 5 | 1:20 | Add expense | Tap the centre [+]. Enter Groceries, RWF 12,000, category Groceries. Keep Equal split with all three | "Amara paid RWF 12,000 for groceries. The form shows each person's share live: RWF 4,000 each." |
| 6 | 1:50 | Add expense | Switch to Percent, then Exact amounts. Show the error when the total is wrong, then go back to Equal and save | "We support equal, percent and exact splits. The form blocks a wrong total, and saving only works when it adds up." |
| 7 | 2:20 | Dashboard | Back on the dashboard. Show balances and the new activity line | "The dashboard updated by itself. Bob's credits were applied to his share, and the activity feed logged the expense." |
| 8 | 2:45 | Expense details | Open the expense. Show Who pays what: Amara paid, Bob pending (after credits), Chloe pending | "The details sheet shows each person's share and status, and what was reduced by credits." |
| 9 | 3:10 | Debts (if merged) | Open Bob's debt. Send a nudge. On Bob's phone, show the notification | "Amara sends Bob a friendly nudge. He gets a notification." |
| 10 | 3:30 | Settle up (if merged) | On Bob's phone, settle with Mobile Money. Switch to Amara's phone | "Bob settles by Mobile Money. Amara's balance and the activity feed update." |
| 11 | 3:50 | Expense details | Open the expense again. Show Bob as paid and the Delete button disabled with its explanation | "Once someone has paid, the expense can't be deleted. The app explains why, and the database enforces the same rule." |
| 12 | 4:10 | Chores and Harmony (if merged) | Show the chore roster, mark one done. Return to the dashboard, tap the info icon on Harmony | "Chores rotate between housemates. Finishing them on time raises the household Harmony Score. The info sheet explains how it is calculated." |
| 13 | 4:30 | Firestore console | Show the expense and its debt documents in the browser | "Everything is stored in Cloud Firestore with security rules, so housemates only see their own household." |
| 14 | 4:45 | CI | Show the green GitHub Actions run and the test count | "Every pull request runs formatting, analysis and all tests before it can be merged." |
| 15 | 4:55 | Closing card | Team names and roles | "Thank you. That was Changa." |

## If a scene fails on camera

- Record the scene again. Never explain a bug on camera.
- If a screen is not merged yet (scenes 9, 10, 12), skip it and add its time to scene 7 or 8. Do not show a placeholder screen.
- If the phone is slow, pause 2 seconds after each tap so the cut is clean.

## Evidence to capture (for the grading appendix)

- Screenshot of each main screen: dashboard, add expense, expense details, debts, chores, activity.
- Firestore console: one expense, its debts, and the member's credits before and after.
- GitHub: green CI run, merged pull requests with review comments.
- Terminal: `flutter test` summary and `flutter analyze` with no issues.

Save them in `docs/evidence/` with clear names (for example `dashboard.png`, `expense-details.png`).

## Roles on the day

| Person | Does |
|---|---|
| C (Nelson) | Records scenes 1 to 8 and 11, writes the final cut order |
| D | Records scenes 9 and 10 |
| E | Records scene 12 |
| B | Records scene 13 |
| A | Records scene 14 and puts the video together |
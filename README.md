# Changa

Changa is a mobile app that helps student housemates **share bills and rotate chores** without awkward conversations. One person pays the rent or the groceries, the app splits the cost, and everyone sees what they owe. Chores rotate fairly, and doing them earns credits that reduce your next bill.

Built with Flutter and Firebase for the ALU Mobile Application Development final project (Group 32).

## Features

- **Accounts:** sign up with email (with email verification and password reset) or with Google, and stay signed in after a restart.
- **Households:** create a household and share its 6-digit PIN, or join one with a PIN. Admins can regenerate the PIN and remove members. A person can belong to one household at a time.
- **Dashboard:** the home screen shows the household Harmony Score, what you are owed and what you owe, quick actions, and the latest activity.
- **Expenses:** add a shared cost and split it equally, by percent or by exact amounts. The form shows a live preview of each share. The Expense Details sheet shows who pays what and each person's payment status. The payer can edit the note, or delete the expense until someone has paid their share.
- **Credits:** chores earn credits (1 credit = RWF 10) that are applied to your share automatically.
- **Debts and nudges:** itemised balances per housemate, a polite one-tap nudge, and settling up by cash, Mobile Money or bank transfer.
- **Chores:** one-off and recurring chores that rotate between housemates, and swap requests.
- **Harmony Score:** a 0 to 100 score for the whole household, built from chores finished on time and bills settled promptly. An info sheet in the app explains how it is calculated.
- **Activity feed:** every action in the household is logged and shown to everyone.
- **Preferences:** theme, notification choices, default split type and default payment method are saved on the phone.

All amounts are whole Rwandan francs (RWF), with no decimals.

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter (Dart), Android only |
| State management | Cubit (`flutter_bloc`). `setState` is not allowed and CI checks for it |
| Architecture | Clean Architecture: `presentation`, `domain`, `data` in every feature |
| Navigation | `go_router` |
| Dependency injection | `get_it` |
| Backend | Firebase Authentication, Cloud Firestore, security rules and indexes |
| Local storage | `shared_preferences` |
| Other packages | `equatable`, `rxdart`, `intl`, `google_sign_in`, `flutter_local_notifications`, `share_plus` |
| Tests | `flutter_test`, `fake_cloud_firestore` |
| Font | Poppins |

## Project structure

```
lib/
  core/            shared code: theme, router, widgets, utils, constants, error types
  features/
    auth/          sign up, login, verification, password reset
    household/     create, join, manage, members
    expenses/      add expense, expense details, split and credit logic
    dashboard/     home screen, Harmony Score
    debts/         balances, nudges, settling up
    chores/        chores, rotation, swap requests
    activity/      activity feed
    notifications/ in-app and local notifications
    profile/       profile and preferences
test/              unit and widget tests, mirroring lib/
docs/              ERD, demo script, test and rules evidence
```

Every feature folder has the same three layers:

- `presentation/`: screens, widgets and Cubits. No business logic here.
- `domain/`: plain Dart entities, repository interfaces, use cases and pure logic (for example the split calculator and the Harmony Score). No Flutter or Firebase imports.
- `data/`: Firestore models, data sources and repository implementations.

## Getting started

### Requirements

- Flutter (stable channel) with Dart SDK `^3.13.2`. Check yours with `flutter --version`.
- Android Studio or the Android SDK, and an Android phone or emulator.
- Windows only: turn on **Developer Mode** (Settings, Privacy & security, For developers), because Flutter plugins need symlink support.

### Run the app

```bash
git clone https://github.com/charleswereangoye/changa_app.git
cd changa_app
flutter pub get
flutter run
```

### Firebase

The Firebase project is already configured. `android/app/google-services.json`, `lib/firebase_options.dart`, `firestore.rules` and `firestore.indexes.json` are in the repository, so you can build and run without creating a project.

- **Google sign-in** only works for debug builds whose SHA-1 and SHA-256 fingerprints are registered in the Firebase project. If Google sign-in fails on your machine, send your fingerprints (`cd android && ./gradlew signingReport`) to the person who owns the Firebase project.
- To deploy the rules and indexes to your own project: `firebase deploy --only firestore`.

### Build a release APK

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests and code quality

```bash
flutter test                  # run all unit and widget tests
flutter test --coverage       # also writes coverage/lcov.info
flutter analyze               # must report no issues
dart format .                 # formatting (CI fails if files are not formatted)
```

GitHub Actions runs the same checks on every pull request and every push to `main`: formatting, `flutter analyze`, a check that the code contains no `setState(`, and `flutter test`.

## Data model

The database design is in `docs/erd.png` (editable source: `docs/erd.drawio`). Collections:

- `users`, `householdPins`, `households`
- inside each household: `members`, `expenses`, `debts`, `chores`, `swapRequests`, `activities`, `notifications`

Field names are defined once in `lib/core/constants/firestore_paths.dart`, so the code and the ERD stay in step.

## Demo

The script and run-sheet for the video demo are in `docs/demo_script.md`.

## How we work

- One branch per task (`feature/...`), merged to `main` by pull request.
- Every pull request needs at least one real review comment from a teammate before it is merged. We use **Create a merge commit**, not squash, so the history stays visible.
- CI must be green before merging.

## Team

| Person | Name | Area |
|---|---|---|
| A | Charles Angoye | Foundation, authentication, profile, CI |
| B | Bendou Janna Vitalina Sœur | Database design, security rules, household, activity feed |
| C | Nelson Ishimwe | Expenses, dashboard, documentation |
| D | Dianah Shimwa | Debts, settling, nudges, notifications, release build |
| E | Leila Omol | Chores, Harmony Score, preferences |

## Screenshots

Screenshots of each main screen (dashboard, add expense, expense details, debts, chores, activity) are in `docs/evidence/`.

## Known limitations and future work

- No real push notifications when the app is closed (that would need Cloud Functions). The app shows an in-app banner and local notifications instead.
- Any member can change another member's credit balance field. The security rules limit this to that single field, and it can never go below 0.
- No account deletion and no offline mode.
- A user can belong to only one household at a time.
- Mobile Money is recorded as a payment method label. The app does not integrate with a payment provider.
- Android only.
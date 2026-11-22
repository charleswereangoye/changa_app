# D12 Release Device Tests

- Date: 2026-11-22
- Tester: Dianah
- Branch: feature/d-release-device-tests
- Tested commit: 2066b3f
- Build command: flutter build apk --release --no-tree-shake-icons
- APK: build/app/outputs/flutter-apk/app-release.apk
- APK SHA-256:
  bfa98801f2d5e222e690ca51ab36db5b950f48d9ed7386a0c0a8d7e18db7e020

## Devices

| Device | Model | Android version |
|---|---|---|
| Phone 1 | HONOR Magic V5, MBH-N49 | 17 |
| Phone 2 | HONOR Magic V5; same model reported by tester | Not recorded |

The tester reports using the same APK on both physical phones.
The results below are tester-reported.

## Release validation

| Check | Result |
|---|---|
| Installation on Phone 1 | Pass |
| Cold start on Phone 1 | Pass |
| Email sign-up and verification | Pass |
| Email login | Pass |
| Google Sign-In | Pass |
| Login and preferences retained after restart | Pass |
| Firestore expense creation and reads | Pass |
| Notification permission/status and delivery checks | Pass |
| Notification tap navigation | Pass |
| Landscape layout checks | Pass |
| Installation and startup on Phone 2 | Pass |
| Different accounts in the same household | Pass |
| Expense and debt updates visible across phones | Pass |
| Nudge received on the other phone | Pass |
| Settlement reflected in both balances and activity | Pass |

## Startup issue and fix

The original release remained on the native splash screen.

Temporary on-screen diagnostics identified a PlatformException during
dependency setup: SharedPreferencesApiRegistrar.getAll could not be
found through JNI.

The working build pins shared_preferences_android to 2.5.0 and applies
the upstream Kotlin JNI preservation rules through
android/app/proguard-rules.pro.

The temporary diagnostic startup screen was removed before building
the final tested APK.

## Evidence limits

- Functional outcomes were reported by the tester.
- The second phone's Android version was not recorded.
- Screenshots or recordings of the final physical-device checks
  are not attached to this report.
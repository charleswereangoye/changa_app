# D11 Device and Quality Matrix

## Test build

- Date: 2026-11-19
- Tester: Dianah
- Branch: feature/d-device-quality
- App commit: e303f1a
- Current device: D11 Small — iPhone SE (3rd generation), 4.7-inch
- OS: iOS 26.3

Record the new app commit whenever the tested code changes.

## Status rules

- Pending: not tested yet.
- Pass: all relevant checks completed successfully.
- Fail: reproducible problem; link evidence and an issue.
- Blocked: required feature, account, or device is unavailable.
- N/A: check does not apply; explain why.

## Initial observations

- The app displays after configuring Firebase for iOS.
- Rotating left was reported to work.
- Screen-specific layout, keyboard, and accessibility checks remain pending.

## Required device coverage

| Configuration | Device | Status |
|---|---|---|
| Small device, 5.5 inches or smaller | D11 Small — iPhone SE (3rd generation), iOS 26.3 | In progress |
| Large device, 6.7 inches or larger | D11 Large — iPhone 16 Plus, iOS 26.3 | In progress |
| Additional simulator | iPhone 16e, iOS 26.3 | In progress |

Test both portrait and landscape on the required device sizes.

## Screen checks

Record results with the device name and app commit in the evidence notes.

| Screen or flow | Small portrait | Small landscape | Large portrait | Large landscape | Large text | Keyboard | Evidence / issue |
|---|---|---|---|---|---|---|---|
| Splash and onboarding | Pending | Pending | Pending | Pending | Pending | N/A | |
| Login | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pending | Pass (both sizes) | Small: e303f1a; large: 38389f6 |
| Sign up | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pending | Pass (both sizes) | Small: e303f1a; large: 38389f6 |
| Forgot password | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pending | Pass (both sizes) | Small: e303f1a; large: 38389f6 |
| Email verification | Pending | Pending | Pending | Pending | Pending | N/A | |
| Create household | Pending | Pending | Pending | Pending | Pending | Pending | |
| Household created / PIN | Pending | Pending | Pending | Pending | Pending | N/A | |
| Join household | Pending | Pending | Pending | Pending | Pending | Pending | |
| Dashboard, empty and active | Pass (tested state) | Pass (tested state) | Pass (tested state) | Pass (tested state) | Pending | N/A | Other dashboard data state remains pending |
| Add expense | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pending | Pass (both sizes) | User-tested on both sizes |
| Debt details and nudge | Pending | Pending | Pass (layout) | Pass (layout) | Pending | N/A | Debt Details layout passed; sending a nudge not verified |
| Settle up | Pending | Pending | Pass (layout) | Pass (layout) | Pending | N/A | Selection survives rotation; settlement submission not verified |
| Chore roster | Pending | Pending | Pass (layout) | Pass (layout) | Pending | N/A | User-tested on D11 Large |
| Add / edit chore | Pending | Pending | Pass (layout) | Pass (layout) | Pending | Pass (large device) | Entered values preserved after rotation |
| Chore swap | Pending | Pending | Pass (layout) | Pass (layout) | Pending | N/A | Swap dialog layout passed; request submission not verified |
| Activity history | Pending | Pending | Pending | Pending | Pending | Pending | |
| Profile | Pending | Pending | Pending | Pending | Pending | N/A | |
| Edit profile | Pending | Pending | Pending | Pending | Pending | Pending | |
| Preferences | Pending | Pending | Pending | Pending | Pending | N/A | |
| Manage household | Pending | Pending | Pending | Pending | Pending | Pending | |
| Harmony explanation | Pending | Pending | Pending | Pending | Pending | N/A | |
| Notification banner and nudge modal | Pending | Pending | Pending | Pending | Pending | N/A | |

## Checks for each screen

- No overflow stripes, clipped labels, or overlapping controls.
- Content and actions remain reachable by scrolling.
- Rotation preserves entered values and selected options.
- With the keyboard open, fields and submission controls remain reachable.
- Large system text remains readable and usable.
- Interactive targets measure at least 48 logical pixels.
- Normal text contrast is at least 4.5:1; record measured results.
- Back, close, cancel, and confirmation actions work correctly.

## Evidence

Save screenshots under docs/evidence/device-quality/.

Suggested filename:
DEVICE-SCREEN-ORIENTATION-TEXTSIZE.png

For each failure, record:
- App commit and device.
- Steps to reproduce.
- Expected and actual behavior.
- Screenshot path.
- GitHub issue link and responsible owner.
- Retest result and fixed commit.

## Platform limits

- Android notification permission and local delivery require Android testing.
- Physical-phone release checks belong to D12.
- Simulator checks do not establish that the release APK works.
- Features awaiting merge must be retested after integration.

## Test log — 2026-11-19

### Login — D11 Small

- Build: e303f1a
- Portrait layout: passed.
- Landscape layout: passed.
- Keyboard open: fields and Log In remain reachable by scrolling.
- No overflow, clipping, or overlapping controls reported.
- Large text, measured contrast, and measured tap sizes: pending.

### Sign Up and Forgot Password — D11 Small

- Portrait and landscape layouts: passed.
- Fields and submission controls remain reachable with the keyboard open.
- No overflow, clipping, or overlapping controls reported.
- Large text, measured contrast, and measured tap sizes: pending.

### Remaining available screens — D11 Small

- Tester reports portrait, landscape, keyboard, and rotation checks passed
  for the remaining available screens at normal text size.
- Profile and Edit Profile currently display placeholders:
  final-screen testing is blocked pending integration.
- Notification banner and nudge modal testing is blocked pending integration.
- Large-text, contrast, tap-size, and large-device checks remain pending.

## Test log — 2026-11-22

### Authentication layouts — D11 Large

- Build: 38389f6.
- Device: iPhone 16 Plus, iOS 26.3.
- Login, Sign Up, and Forgot Password passed portrait, landscape,
  and keyboard-open layout checks.
- Results reported by the tester.
- Large text, measured contrast, and tap-size checks remain pending.

### Dashboard, expenses, and debts — D11 Large

- App build: 38389f6.
- Tester reports portrait and landscape layout checks passed.
- Add Expense remains usable with the keyboard open and preserves entered values.
- Settle Up preserves the selected payment method after rotation.
- These results cover layout and state preservation, not successful writes.

### Chores — D11 Large

- App build: 38389f6.
- Chore Roster, Add Chore, Edit Chore, and Chore Swap passed
  portrait and landscape layout checks.
- Add/Edit Chore remain usable with the keyboard open and preserve
  entered values after rotation.
- Results reported by the tester; write operations remain unverified.
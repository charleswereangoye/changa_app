# D11 Device and Quality Matrix

## Test build

- Date: 2026-11-18
- Tester: Dianah — Person D
- Branch: feature/d-device-quality
- App commit: 9f7151b
- Current device: iPhone 16e Simulator
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
| Small device, 5.5 inches or smaller | To select | Pending |
| Large device, 6.7 inches or larger | To select | Pending |
| Additional simulator | iPhone 16e, iOS 26.3 | In progress |

Test both portrait and landscape on the required device sizes.

## Screen checks

Record results with the device name and app commit in the evidence notes.

| Screen or flow | Small portrait | Small landscape | Large portrait | Large landscape | Large text | Keyboard | Evidence / issue |
|---|---|---|---|---|---|---|---|
| Splash and onboarding | Pending | Pending | Pending | Pending | Pending | N/A | |
| Login | Pending | Pending | Pending | Pending | Pending | Pending | |
| Sign up | Pending | Pending | Pending | Pending | Pending | Pending | |
| Forgot password | Pending | Pending | Pending | Pending | Pending | Pending | |
| Email verification | Pending | Pending | Pending | Pending | Pending | N/A | |
| Create household | Pending | Pending | Pending | Pending | Pending | Pending | |
| Household created / PIN | Pending | Pending | Pending | Pending | Pending | N/A | |
| Join household | Pending | Pending | Pending | Pending | Pending | Pending | |
| Dashboard, empty and active | Pending | Pending | Pending | Pending | Pending | N/A | |
| Add expense | Pending | Pending | Pending | Pending | Pending | Pending | |
| Debt details and nudge | Pending | Pending | Pending | Pending | Pending | N/A | |
| Settle up | Pending | Pending | Pending | Pending | Pending | N/A | |
| Chore roster | Pending | Pending | Pending | Pending | Pending | N/A | |
| Add / edit chore | Pending | Pending | Pending | Pending | Pending | Pending | |
| Chore swap | Pending | Pending | Pending | Pending | Pending | Pending | |
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
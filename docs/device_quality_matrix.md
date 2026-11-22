# D11 Device and Quality Matrix

## Test build

- Last updated: 2026-11-22
- Tester: Dianah
- Branch: fix/d-large-text-layout
- Latest dark-surface spot-check commit: b959f9c
- Latest spot-check device: iPhone 16e, iOS 26.3
- Earlier layout devices: iPhone SE (3rd generation) and iPhone 16 Plus
- Earlier builds are identified in the historical logs below.

The Screen checks table records the latest tester-reported layout results.
Earlier passes do not establish that every screen was rerun on this commit.

## Current summary

- The tester reports the screen-layout checks in the table passed.
- Both required simulator sizes were checked in portrait and landscape,
  including largest accessibility text.
- Dashboard empty/active states and Activity History empty/populated
  states and search were subsequently reported as passed.
- Contrast and touch-target measurements cover only the audited controls.
- Physical-device release results are documented separately under D12.

## Required device coverage

| Configuration | Device | Status |
|---|---|---|
| Small device, 5.5 inches or smaller | D11 Small — iPhone SE (3rd generation), iOS 26.3 | In progress |
| Large device, 6.7 inches or larger | D11 Large — iPhone 16 Plus, iOS 26.3 | In progress |
| Additional simulator | iPhone 16e, iOS 26.3 | In progress |

Test both portrait and landscape on the required device sizes.

## Screen checks

Results are tester-reported for D11 Small (iPhone SE, 3rd generation)
and D11 Large (iPhone 16 Plus), running iOS 26.3.

Layout checks cover portrait and landscape at normal and largest
accessibility text. These results do not establish successful database
writes or physical-device release behavior.

| Screen or flow | Small portrait | Small landscape | Large portrait | Large landscape | Large text | Keyboard | Evidence / issue |
|---|---|---|---|---|---|---|---|
| Splash and onboarding | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Navigation and controls checked |
| Login | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Fields and controls remain reachable |
| Sign up | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Entered text survives rotation |
| Forgot password | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Fields and controls remain reachable |
| Email verification | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Instructions and controls checked |
| Create household | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Values survive rotation |
| Household created / PIN | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | PIN readability, copy, and navigation checked |
| Join household | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | PIN entry and household preview checked |
| Dashboard, empty and active | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Both states checked; original overflow and passing retest screenshots retained |
| Add expense | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Scrolling and value preservation checked |
| Debt details and nudge | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Amounts, expense rows, scrolling, and navigation checked |
| Settle up | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Payment selection survives rotation |
| Chore roster | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Dates, cards, and actions checked |
| Add / edit chore | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Validation layout, scrolling, and value preservation checked |
| Chore swap | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | List, buttons, and dismissal checked |
| Activity history | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (search, both sizes) | Empty and populated states; search typing and clearing checked |
| Profile | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Final screen tested |
| Edit profile | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (both sizes) | Entered text survives rotation |
| Preferences | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Selections survive rotation |
| Payment methods | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Selection survives rotation |
| Manage household | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | Pass (editing form, both sizes) | Editing controls remain reachable |
| Harmony explanation | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Text, scrolling, and dismissal checked |
| Notification banner and nudge modal | Pass (layout) | Pass (layout) | Pass (layout) | Pass (layout) | Pass (both sizes) | N/A | Banner/modal text, dismissal, and View Details checked |

### Remaining verification

- Text contrast passed for the audited dashboard and navigation labels.
- Navigation and dashboard quick-action target checks passed.
  Measurements for other interactive controls remain pending.

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

### D11 Small

- D11 Small: tester reports largest-text dashboard checks passed in portrait and landscape using the layout fixes from e3fada1.
- Small portrait evidence: docs/evidence/device-quality/iphonese-dashboard-largest-text-pass-portrait.png
- Small landscape evidence: docs/evidence/device-quality/iphonese-dashboard-largest-text-pass-landscape.png
- Other dashboard data states remain pending.

## Historical log interpretation

The dated entries below preserve earlier observations. Their pending
statuses describe those test stages, not the latest summary table.
Later testing superseded the dashboard-state and Activity History
state/search gaps. Contrast and target-size checks remain scoped.

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

### Profile and household settings — D11 Large

- App build: 38389f6.
- Profile, Edit Profile, Preferences, Payment Methods, and Manage Household
  passed portrait and landscape layout checks.
- Tested editing controls remain accessible with the keyboard open.
- Entered text and selected options survive rotation.
- Results reported by the tester.

### Dashboard largest-text failure — D11 Large

- Build: 38389f6.
- Device: iPhone 16 Plus, iOS 26.3.
- Largest accessibility text, portrait.
- Quick-action labels overflow horizontally.
- Bottom navigation labels overflow vertically.
- Balance totals are clipped.
- Dashboard large-text result: Fail.
- Owners: C (dashboard), A (navigation shell).
- Evidence: docs/evidence/device-quality/iphone16plus-dashboard-largest-text-fail.png
- Retest: passed after the layout fixes from e3fada1.
- Portrait evidence: docs/evidence/device-quality/iphone16plus-dashboard-largest-text-pass-portrait.png
- Landscape evidence: docs/evidence/device-quality/iphone16plus-dashboard-largest-text-pass-landscape.png

### Activity History and Harmony explanation — both simulator sizes

- Date: 2026-11-22.
- Tester reports layout checks passed in portrait and landscape
  on D11 Small and D11 Large.
- Largest accessibility text remained readable and usable.
- These results cover the displayed Activity History state;
  empty and populated states were not separately recorded.
- Activity search keyboard behavior remains pending unless separately verified.

## Text contrast audit — 2026-11-22

Calculated from the opaque foreground and background colors in source.

| Audited text combination | Contrast ratio | 4.5:1 target |
|---|---:|---|
| Dark green on cream | 13.51:1 | Pass |
| Dark green on white | 14.16:1 | Pass |
| Dark green on light green | 8.41:1 | Pass |
| Light green on dark green | 8.41:1 | Pass |

Changes:
- Shared small-text default changed to dark green.
- Navigation labels changed to dark green.
- Dashboard household label and Harmony explanation subtitle darkened.
- Balance amounts and the See all link changed to dark green.

The tester reports all tests passed after these changes.

Scope:
- These results cover the audited text combinations.
- Other screens, transparent text, and explicit overrides require review.
- Icon contrast and measured tap-target sizes remain separate checks.
- Earlier simulator layout passes predate these text-color changes.

## Tap-target verification

- Navigation and quick-action widget tests: 6 passed.
- Tests cover normal and large text layouts, target-size assertions,
  scrolling, and action callbacks.
- Dashboard quick actions have a minimum height of 52 logical pixels.
- The navigation Add Expense button occupies 56 × 56 logical pixels.
- These results cover the tested controls and viewport configurations.
- Dashboard avatar, notification bell, and Harmony information link:
  widget tests verify width and height of at least 48 logical pixels
  and confirm their callbacks respond.
- The avatar keeps its 40-pixel visual size inside a 48 × 48 touch area.
- These measurements cover the tested widget configuration.

## Review follow-up — dark surfaces

- Date: 2026-11-22.
- Tested commit: b959f9c.
- Device: iPhone 16e, iOS 26.3.
- Tester reports the Harmony card, household-created header/PIN card,
  and Manage Household PIN panel remained readable at normal and
  largest accessibility text.
- No dark-green-on-dark-green small text was reported.
- This was a visual regression check, not a complete contrast measurement.
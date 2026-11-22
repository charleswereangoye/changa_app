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

- Measured text contrast of at least 4.5:1 remains pending.
- Measured interactive target sizes of at least 48 logical pixels remain pending.
- Database writes are not established by these layout results.
- Android notification permission and delivery require Android testing.
- D12 release startup remains unresolved.
- Two-physical-phone release testing remains pending.

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
- Retest: pending.

### Activity History and Harmony explanation — both simulator sizes

- Date: 2026-11-22.
- Tester reports layout checks passed in portrait and landscape
  on D11 Small and D11 Large.
- Largest accessibility text remained readable and usable.
- These results cover the displayed Activity History state;
  empty and populated states were not separately recorded.
- Activity search keyboard behavior remains pending unless separately verified.
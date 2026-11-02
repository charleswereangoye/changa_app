<!-- Owner: A - Person A (Foundation, Authentication, Profile) -->
<!-- Description: PR template with checklist, verification, and guidelines -->

## What
<!-- A plain-language summary of what changes were made in this PR -->

## Why
<!-- Why these changes are needed and what problem or task they solve -->

## Screenshots / Evidence
<!-- Attach screenshots or terminal outputs showing tests/features working -->
<!-- e.g. flutter analyze (0 issues), flutter test passing, or UI screenshots -->

## How to Test
<!-- Step-by-step instructions on how the reviewer can test these changes -->

## Checklist
- [ ] `dart format .` is clean
- [ ] `flutter analyze` shows 0 issues
- [ ] No `setState(` anywhere under `lib/`
- [ ] No Firebase imports in `presentation` or `domain` layers
- [ ] Loading, error, and empty states handled where applicable
- [ ] Tests added or updated for new logic
- [ ] Ran on a real device or an Android emulator
- [ ] Reviewer (next team member) commented and approved

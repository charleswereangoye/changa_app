<!-- Owner: A - Person A (Foundation, Authentication, Profile) -->
<!-- Description: PR template with checklist, verification, and guidelines -->

## Description
<!-- What changes does this PR introduce and why? -->

## Related Task / Issue
<!-- Link to task ID e.g. [A9], [C6], or GitHub Issue # -->

## Type of Change
- [ ] `feat`: New feature
- [ ] `fix`: Bug fix
- [ ] `test`: Added or updated unit/widget tests
- [ ] `refactor`: Code refactoring without behavior change
- [ ] `docs`: Documentation updates
- [ ] `chore`: Tooling, CI, dependencies

## Visual Evidence / Screenshots
<!-- Attach screenshots of the screen in portrait and landscape modes -->
| Portrait | Landscape |
|---|---|
| *(image)* | *(image)* |

## How to Test
<!-- Provide step-by-step instructions to reproduce or test the changes on a device or emulator -->
1.
2.
3.

## Definition of Done (Checklist)
- [ ] `dart format --set-exit-if-changed .` is clean
- [ ] `flutter analyze` shows 0 issues
- [ ] No `setState(` anywhere in `lib/` (verified via CI grep)
- [ ] Clean Architecture respected: no Firebase imports in `domain` or `presentation`
- [ ] Loading, error (with retry), and empty states properly handled
- [ ] Unit or widget tests added / updated (`flutter test` passes)
- [ ] If a Firestore field changed: ERD, `firestore_paths.dart`, security rules, and indexes updated in the same PR
- [ ] Verified on an Android device or emulator (including landscape rotation)
- [ ] Reviewed and approved by the assigned buddy / reviewer

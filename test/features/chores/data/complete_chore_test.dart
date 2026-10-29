import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

import 'chore_datasource_fixture.dart';

Matcher _ruleError(ChoreRuleKind kind) =>
    throwsA(isA<ChoreRuleException>().having((e) => e.kind, 'kind', kind));

void main() {
  late ChoreFixture f;

  setUp(() => f = ChoreFixture());

  group('credits awarded', () {
    // Literal numbers on purpose. They come from the team guide, so this
    // fails if the shared constants ever drift away from it again.
    const expected = {
      ChoreDifficulty.easy: 10,
      ChoreDifficulty.medium: 20,
      ChoreDifficulty.hard: 30,
    };

    for (final entry in expected.entries) {
      test('a ${entry.key.name} chore awards ${entry.value}', () async {
        await f.seedChore(difficulty: entry.key);

        await f.source.complete(householdId, choreId);

        final chore = await f.chore();
        expect(chore?[ChoreFields.creditsAwarded], entry.value);
        expect(chore?[ChoreFields.status], ChoreStatus.done.name);
        expect(await f.credits('u1'), entry.value);
      });
    }

    test('adds to credits the member already has', () async {
      await f.seedChore(difficulty: ChoreDifficulty.medium, memberCredits: 50);

      await f.source.complete(householdId, choreId);

      final awarded = (await f.chore())?[ChoreFields.creditsAwarded] as int;
      expect(await f.credits('u1'), 50 + awarded);
    });

    test('records when it was completed', () async {
      await f.seedChore();

      await f.source.complete(householdId, choreId);

      expect((await f.chore())?[ChoreFields.completedAt], isNotNull);
    });
  });

  group('who can complete', () {
    test('someone else cannot tick it, and nothing changes', () async {
      await f.seedChore(difficulty: ChoreDifficulty.hard);
      f.signInAs('u2');

      await expectLater(
        f.source.complete(householdId, choreId),
        _ruleError(ChoreRuleKind.permission),
      );

      expect((await f.chore())?[ChoreFields.status], ChoreStatus.pending.name);
      expect(await f.credits('u1'), 0);
    });

    test('completing twice is refused and credits are not doubled', () async {
      await f.seedChore(difficulty: ChoreDifficulty.easy);
      await f.source.complete(householdId, choreId);

      await expectLater(
        f.source.complete(householdId, choreId),
        _ruleError(ChoreRuleKind.validation),
      );

      final awarded = (await f.chore())?[ChoreFields.creditsAwarded] as int;
      expect(await f.credits('u1'), awarded);
    });

    test('a chore that no longer exists is reported as not found', () async {
      await f.seedChore();
      await f.db.doc(FirestorePaths.chore(householdId, choreId)).delete();

      await expectLater(
        f.source.complete(householdId, choreId),
        _ruleError(ChoreRuleKind.notFound),
      );
    });
  });
}

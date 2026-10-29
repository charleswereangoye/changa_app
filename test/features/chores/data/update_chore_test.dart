import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/models/chore_model.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

import 'chore_datasource_fixture.dart';

Matcher _ruleError(ChoreRuleKind kind) =>
    throwsA(isA<ChoreRuleException>().having((e) => e.kind, 'kind', kind));

ChoreModel _edited() => ChoreModel(
      id: choreId,
      title: 'Mopping',
      difficulty: ChoreDifficulty.hard,
      assignedToUid: 'u2',
      dueDate: DateTime(2026, 10, 27, 15, 30),
      status: ChoreStatus.pending,
      createdByUid: 'u1',
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  late ChoreFixture f;

  setUp(() => f = ChoreFixture());

  test('editing a pending chore changes only the editable fields', () async {
    await f.seedChore();

    await f.source.update(householdId, _edited());

    final chore = await f.chore();
    expect(chore?[ChoreFields.title], 'Mopping');
    expect(chore?[ChoreFields.difficulty], ChoreDifficulty.hard.name);
    expect(chore?[ChoreFields.assignedToUid], 'u2');
    expect(
      chore?[ChoreFields.dueDate],
      Timestamp.fromDate(DateTime(2026, 10, 27)),
    );
    expect(chore?[ChoreFields.status], ChoreStatus.pending.name);
    expect(chore?[ChoreFields.creditsAwarded], isNull);
  });

  // Regression: an edit that lands after the chore was completed must not
  // rewrite a finished chore, or its history stops matching the credits.
  test('a chore completed first cannot be edited afterwards', () async {
    await f.seedChore(difficulty: ChoreDifficulty.medium);
    await f.source.complete(householdId, choreId);
    final before = await f.chore();

    await expectLater(
      f.source.update(householdId, _edited()),
      _ruleError(ChoreRuleKind.validation),
    );

    final after = await f.chore();
    expect(after?[ChoreFields.difficulty], ChoreDifficulty.medium.name);
    expect(after?[ChoreFields.assignedToUid], 'u1');
    expect(after?[ChoreFields.dueDate], before?[ChoreFields.dueDate]);
    expect(after?[ChoreFields.title], 'Dishes');
    expect(after?[ChoreFields.creditsAwarded], before?[ChoreFields.creditsAwarded]);
  });

  test('editing a chore that no longer exists is reported as not found',
      () async {
    await f.seedChore();
    await f.db.doc(FirestorePaths.chore(householdId, choreId)).delete();

    await expectLater(
      f.source.update(householdId, _edited()),
      _ruleError(ChoreRuleKind.notFound),
    );
  });
}
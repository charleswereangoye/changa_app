import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/chores/data/datasources/chore_remote_datasource.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockActivityWriter extends Mock implements ActivityWriter {}

const householdId = 'h1';
const choreId = 'c1';

/// A fake Firestore with one household member (u1) and one chore (c1).
class ChoreFixture {
  ChoreFixture() {
    when(() => auth.currentUser).thenReturn(user);
    signInAs('u1');
  }

  final db = FakeFirebaseFirestore();
  final auth = MockFirebaseAuth();
  final user = MockUser();
  final activity = MockActivityWriter();

  late final source = ChoreRemoteDataSource(db, auth, activity);

  void signInAs(String uid) => when(() => user.uid).thenReturn(uid);

  Future<void> seedChore({
    ChoreDifficulty difficulty = ChoreDifficulty.easy,
    String assignee = 'u1',
    int memberCredits = 0,
  }) async {
    await db.doc(FirestorePaths.member(householdId, 'u1')).set({
      MemberFields.role: 'member',
      MemberFields.credits: memberCredits,
      MemberFields.joinedAt: Timestamp.fromDate(DateTime(2026, 10, 1)),
    });
    await db.doc(FirestorePaths.chore(householdId, choreId)).set({
      ChoreFields.seriesId: null,
      ChoreFields.title: 'Dishes',
      ChoreFields.description: null,
      ChoreFields.difficulty: difficulty.name,
      ChoreFields.assignedToUid: assignee,
      ChoreFields.dueDate: Timestamp.fromDate(DateTime(2026, 10, 20)),
      ChoreFields.status: ChoreStatus.pending.name,
      ChoreFields.completedAt: null,
      ChoreFields.creditsAwarded: null,
      ChoreFields.createdByUid: 'u1',
      ChoreFields.createdAt: Timestamp.fromDate(DateTime(2026, 10, 1)),
    });
  }

  Future<Map<String, dynamic>?> chore() async =>
      (await db.doc(FirestorePaths.chore(householdId, choreId)).get()).data();

  Future<int?> credits(String uid) async {
    final snap = await db.doc(FirestorePaths.member(householdId, uid)).get();
    return (snap.data()?[MemberFields.credits] as num?)?.toInt();
  }
}

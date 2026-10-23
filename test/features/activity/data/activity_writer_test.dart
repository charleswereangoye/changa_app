import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/activity/data/models/activity_model.dart';
import 'package:changa_app/features/activity/domain/entities/activity.dart';

void main() {
  group('ActivityModel Tests', () {
    test('throws FormatException when ActivityType is unknown', () {
      final json = {
        ActivityFields.type: 'non_existent_type',
        ActivityFields.actorUid: 'user_123',
        ActivityFields.createdAt: Timestamp.now(),
      };

      expect(
        () => ActivityModel.fromJson(json, 'activity_1'),
        throwsFormatException,
      );
    });
  });

  group('ActivityWriter Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ActivityWriter writer;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      writer = ActivityWriter(firestore: fakeFirestore);
    });

    test('addToBatch formats data and stages write properly', () async {
      final batch = fakeFirestore.batch();

      writer.addToBatch(
        batch,
        householdId: 'house_1',
        type: ActivityType.choreCompleted,
        actorUid: 'user_123',
        amount: 50,
      );

      await batch.commit();

      // Dump the fake database state to verify the write executed
      final dbState = fakeFirestore.dump();
      expect(dbState.contains('choreCompleted'), isTrue);
      expect(dbState.contains('user_123'), isTrue);
      expect(dbState.contains('50'), isTrue);
    });
  });
}

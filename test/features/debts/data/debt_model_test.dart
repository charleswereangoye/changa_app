import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/features/debts/data/models/debt_model.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 20);
  final settledAt = DateTime.utc(2026, 10, 21);

  Map<String, dynamic> validData() {
    return {
      DebtFields.expenseId: 'expense-1',
      DebtFields.debtorUid: 'kevin',
      DebtFields.creditorUid: 'me',
      DebtFields.amount: 6000,
      DebtFields.creditsApplied: 20,
      DebtFields.status: 'pending',
      DebtFields.settlementMethod: null,
      DebtFields.settledAt: null,
      DebtFields.createdAt: Timestamp.fromDate(createdAt),
    };
  }

  Future<DebtModel> read([Map<String, dynamic> overrides = const {}]) async {
    final document = await _document({...validData(), ...overrides});

    return DebtModel.fromFirestore(document);
  }

  group('DebtModel', () {
    test('reads the document ID and all shared fields', () async {
      final model = await read();

      expect(model.id, 'debt-1');
      expect(model.expenseId, 'expense-1');
      expect(model.debtorUid, 'kevin');
      expect(model.creditorUid, 'me');
      expect(model.amount, 6000);
      expect(model.amount, isA<int>());
      expect(model.creditsApplied, 20);
      expect(model.status, DebtStatus.pending);
      expect(model.settlementMethod, isNull);
      expect(model.settledAt, isNull);
      expect(model.createdAt.toUtc(), createdAt);
    });

    test('accepts whole-valued doubles and converts them to ints', () async {
      final model = await read({
        DebtFields.amount: 6000.0,
        DebtFields.creditsApplied: 20.0,
      });

      expect(model.amount, 6000);
      expect(model.amount, isA<int>());
      expect(model.creditsApplied, 20);
      expect(model.creditsApplied, isA<int>());
    });

    test('reads bank settlement and converts its timestamp', () async {
      final model = await read({
        DebtFields.status: 'settled',
        DebtFields.settlementMethod: 'bank',
        DebtFields.settledAt: Timestamp.fromDate(settledAt),
      });

      expect(model.status, DebtStatus.settled);
      expect(model.settlementMethod, SettlementMethod.bank);
      expect(model.settledAt?.toUtc(), settledAt);
    });

    test('writes exactly the shared fields without path keys', () async {
      final model = await read();
      final data = model.toMap();

      expect(data, validData());
      expect(data.containsKey('id'), isFalse);
      expect(data.containsKey('householdId'), isFalse);
    });

    test('writes the canonical bank value', () async {
      final model = await read({
        DebtFields.status: 'settled',
        DebtFields.settlementMethod: 'bank',
        DebtFields.settledAt: Timestamp.fromDate(settledAt),
      });

      final data = model.toMap();

      expect(data[DebtFields.status], 'settled');
      expect(data[DebtFields.settlementMethod], 'bank');
      expect(data[DebtFields.settledAt], Timestamp.fromDate(settledAt));
    });

    test('preserves every field when converting an entity round trip', () {
      final entity = Debt(
        id: 'debt-2',
        expenseId: 'expense-2',
        debtorUid: 'grace',
        creditorUid: 'me',
        amount: 0,
        creditsApplied: 200,
        status: DebtStatus.settled,
        settlementMethod: SettlementMethod.credits,
        createdAt: createdAt,
        settledAt: settledAt,
      );

      final model = DebtModel.fromEntity(entity);

      expect(model.toEntity(), equals(entity));
      expect(model.toMap()[DebtFields.creditsApplied], 200);
      expect(model.toMap()[DebtFields.settlementMethod], 'credits');
    });

    test('can request a server timestamp when creating a document', () async {
      final model = await read();
      final data = model.toMap(useServerTimestamp: true);

      expect(data[DebtFields.createdAt], isA<FieldValue>());
    });

    test(
      'uses a fallback date for a pending null creation timestamp',
      () async {
        final before = DateTime.now();
        final model = await read({DebtFields.createdAt: null});
        final after = DateTime.now();

        expect(model.createdAt.isBefore(before), isFalse);
        expect(model.createdAt.isAfter(after), isFalse);
      },
    );

    test('rejects invalid amounts instead of rounding them', () async {
      for (final value in <Object?>[
        1500.5,
        -1,
        double.nan,
        double.infinity,
        double.negativeInfinity,
        null,
        '1500',
        true,
      ]) {
        await expectLater(
          read({DebtFields.amount: value}),
          throwsFormatException,
          reason: 'Invalid amount: $value',
        );
      }
    });

    test('rejects invalid credit quantities', () async {
      for (final value in <Object?>[
        1.5,
        -1,
        double.nan,
        double.infinity,
        null,
        '20',
      ]) {
        await expectLater(
          read({DebtFields.creditsApplied: value}),
          throwsFormatException,
          reason: 'Invalid creditsApplied: $value',
        );
      }
    });

    test('rejects an unknown debt status', () async {
      await expectLater(
        read({DebtFields.status: 'unknown'}),
        throwsFormatException,
      );
    });

    test('rejects a non-contract settlement method value', () async {
      await expectLater(
        read({DebtFields.settlementMethod: 'bankTransfer'}),
        throwsFormatException,
      );
    });

    test('rejects a document with no data', () async {
      final document = await _document(null);

      expect(() => DebtModel.fromFirestore(document), throwsStateError);
    });
  });
}

Future<DocumentSnapshot<Map<String, dynamic>>> _document(
  Map<String, dynamic>? data,
) async {
  final firestore = FakeFirebaseFirestore();
  final reference = firestore.doc(FirestorePaths.debt('household-1', 'debt-1'));

  if (data != null) {
    await reference.set(data);
  }

  return reference.get();
}

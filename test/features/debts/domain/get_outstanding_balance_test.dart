import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/domain/repositories/debt_repository.dart';
import 'package:changa_app/features/debts/domain/usecases/get_outstanding_balance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository repository;
  late GetOutstandingBalance getOutstandingBalance;

  const householdId = 'household-1';

  setUp(() {
    repository = MockDebtRepository();
    getOutstandingBalance = GetOutstandingBalance(repository);
  });

  void returnDebts(List<Debt> debts) {
    when(() => repository.watchPendingDebts(householdId))
        .thenAnswer((_) => Stream<List<Debt>>.value(debts));
  }

  test('sums outgoing debts without subtracting incoming debts', () async {
    returnDebts([
      _debt(id: 'a', debtor: 'kevin', creditor: 'me', amount: 6000),
      _debt(id: 'b', debtor: 'kevin', creditor: 'grace', amount: 1000),
      _debt(id: 'c', debtor: 'me', creditor: 'kevin', amount: 2000),
    ]);

    final result = await getOutstandingBalance(
      householdId: householdId,
      uid: 'kevin',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, 7000);
    verify(() => repository.watchPendingDebts(householdId)).called(1);
  });

  test('excludes settled, self, and other members debts', () async {
    returnDebts([
      _debt(
        id: 'settled',
        debtor: 'kevin',
        creditor: 'me',
        amount: 9000,
        status: DebtStatus.settled,
      ),
      _debt(id: 'self', debtor: 'kevin', creditor: 'kevin', amount: 1000),
      _debt(id: 'other', debtor: 'grace', creditor: 'me', amount: 3000),
      _debt(id: 'pending', debtor: 'kevin', creditor: 'me', amount: 2000),
    ]);

    final result = await getOutstandingBalance(
      householdId: householdId,
      uid: 'kevin',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, 2000);
  });

  test('empty debts return a successful zero balance', () async {
    returnDebts([]);

    final result = await getOutstandingBalance(
      householdId: householdId,
      uid: 'kevin',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, 0);
  });

  test('empty household or member IDs are rejected before querying', () async {
    final missingHousehold = await getOutstandingBalance(
      householdId: '',
      uid: 'kevin',
    );

    final missingMember = await getOutstandingBalance(
      householdId: householdId,
      uid: '',
    );

    expect(missingHousehold.failureOrNull, isA<ValidationFailure>());
    expect(missingMember.failureOrNull, isA<ValidationFailure>());

    verifyNever(() => repository.watchPendingDebts(any()));
  });

  test('preserves a friendly repository failure', () async {
    const failure = NetworkFailure();

    when(() => repository.watchPendingDebts(householdId))
        .thenAnswer((_) => Stream<List<Debt>>.error(failure));

    final result = await getOutstandingBalance(
      householdId: householdId,
      uid: 'kevin',
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, same(failure));
  });

  test('unexpected errors become UnknownFailure', () async {
    when(() => repository.watchPendingDebts(householdId)).thenAnswer(
      (_) => Stream<List<Debt>>.error(StateError('Unexpected problem')),
    );

    final result = await getOutstandingBalance(
      householdId: householdId,
      uid: 'kevin',
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<UnknownFailure>());
  });
}

Debt _debt({
  required String id,
  required String debtor,
  required String creditor,
  required int amount,
  DebtStatus status = DebtStatus.pending,
}) {
  return Debt(
    id: id,
    expenseId: 'expense-$id',
    debtorUid: debtor,
    creditorUid: creditor,
    amount: amount,
    creditsApplied: 0,
    status: status,
    createdAt: DateTime.utc(2026, 10, 20),
  );
}

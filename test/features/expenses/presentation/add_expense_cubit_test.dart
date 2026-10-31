import 'package:flutter_test/flutter_test.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/new_expense_input.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:changa_app/features/expenses/domain/repositories/expense_repository.dart';
import 'package:changa_app/features/expenses/domain/usecases/add_expense.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_cubit.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';

class FakeExpenseRepository implements ExpenseRepository {
  NewExpenseInput? lastInput;

  Result<Expense> nextResult = Result.success(
    Expense(
      id: 'e1',
      title: 'Groceries',
      category: ExpenseCategory.groceries,
      totalAmount: 12000,
      paidByUid: 'amara',
      splitType: SplitType.equal,
      createdAt: DateTime(2026, 10, 30),
    ),
  );

  @override
  Future<Result<Expense>> addExpense(NewExpenseInput input) async {
    lastInput = input;
    return nextResult;
  }

  @override
  Stream<List<Expense>> watchExpenses(String householdId) =>
      const Stream.empty();

  @override
  Future<Result<void>> updateExpenseNote({
    required String householdId,
    required String expenseId,
    required String title,
    String? note,
  }) async => Result.success(null);

  @override
  Future<Result<void>> deleteExpense({
    required String householdId,
    required String expenseId,
  }) async => Result.success(null);
}

void main() {
  const amara = ExpenseParticipant(uid: 'amara', name: 'Amara K');
  const bob = ExpenseParticipant(uid: 'bob', name: 'Bob N', credits: 340);
  const chloe = ExpenseParticipant(uid: 'chloe', name: 'Chloe M');

  late FakeExpenseRepository repo;

  AddExpenseCubit buildCubit({SplitType type = SplitType.equal}) {
    return AddExpenseCubit(
      addExpense: AddExpense(repo),
      householdId: 'house1',
      participants: const [amara, bob, chloe],
      currentUid: 'amara',
      initialSplitType: type,
    );
  }

  void fillBasics(AddExpenseCubit cubit, {String amount = '12000'}) {
    cubit.amountChanged(amount);
    cubit.titleChanged('Groceries');
  }

  setUp(() => repo = FakeExpenseRepository());

  test('starts with everyone selected, me as payer, and Save disabled', () {
    final cubit = buildCubit();

    expect(cubit.state.paidByUid, 'amara');
    expect(cubit.state.selectedUids, ['amara', 'bob', 'chloe']);
    expect(cubit.state.isValid, isFalse);
    expect(cubit.state.amountError, isNull); // not touched yet
  });

  test('a valid equal split shows the preview', () {
    final cubit = buildCubit();
    fillBasics(cubit);

    expect(cubit.state.isValid, isTrue);
    expect(cubit.state.preview!.shares, {
      'amara': 4000,
      'bob': 4000,
      'chloe': 4000,
    });
  });

  test('shows a polite error for a short title once typed in', () {
    final cubit = buildCubit();
    cubit.titleChanged('ab');

    expect(cubit.state.titleError, isNotNull);
    expect(cubit.state.isValid, isFalse);
  });

  test('rejects an amount of 0 and one above 100,000,000', () {
    final cubit = buildCubit();
    cubit.titleChanged('Groceries');

    cubit.amountChanged('0');
    expect(cubit.state.amountError, isNotNull);

    cubit.amountChanged('100000001');
    expect(cubit.state.amountError, isNotNull);

    cubit.amountChanged('100000000');
    expect(cubit.state.amountError, isNull);
  });

  test('needs at least one housemate besides the payer', () {
    final cubit = buildCubit();
    fillBasics(cubit);

    cubit.toggleParticipant('bob');
    cubit.toggleParticipant('chloe');

    expect(cubit.state.selectedUids, ['amara']);
    expect(cubit.state.participantsProblem, isNotNull);
    expect(cubit.state.isValid, isFalse);
  });

  test('toggling keeps the order people were selected in', () {
    final cubit = buildCubit();

    cubit.toggleParticipant('bob'); // off
    cubit.toggleParticipant('bob'); // back on, now last

    expect(cubit.state.selectedUids, ['amara', 'chloe', 'bob']);
  });

  test('percent split must total 100', () {
    final cubit = buildCubit(type: SplitType.percent);
    fillBasics(cubit, amount: '10000');

    cubit.weightChanged('amara', '50');
    cubit.weightChanged('bob', '30');
    expect(cubit.state.weightsTotal, 80);
    expect(cubit.state.visibleSplitProblem, isNotNull);
    expect(cubit.state.isValid, isFalse);

    cubit.weightChanged('chloe', '20');
    expect(cubit.state.isValid, isTrue);
    expect(cubit.state.preview!.shares, {
      'amara': 5000,
      'bob': 3000,
      'chloe': 2000,
    });
  });

  test('exact split shows what is remaining', () {
    final cubit = buildCubit(type: SplitType.exact);
    fillBasics(cubit, amount: '10000');

    cubit.weightChanged('amara', '4000');
    cubit.weightChanged('bob', '3000');
    expect(cubit.state.remaining, 3000);
    expect(cubit.state.isValid, isFalse);

    cubit.weightChanged('chloe', '3000');
    expect(cubit.state.remaining, 0);
    expect(cubit.state.isValid, isTrue);
  });

  test('changing the split type clears what was typed', () {
    final cubit = buildCubit(type: SplitType.percent);
    cubit.weightChanged('amara', '50');

    cubit.splitTypeChanged(SplitType.exact);

    expect(cubit.state.weightTexts, isEmpty);
  });

  test('preview adds up the credits that would be applied', () {
    final cubit = buildCubit();
    fillBasics(cubit);

    // Bob has 340 credits and owes 4,000, so all 340 are used (RWF 3,400).
    expect(cubit.state.preview!.creditsUsed, 340);
    expect(cubit.state.preview!.creditsInRwf, 3400);
  });

  test('submit saves the expense and reports success', () async {
    final cubit = buildCubit();
    fillBasics(cubit);

    await cubit.submit();

    expect(cubit.state.status, AddExpenseStatus.success);
    final input = repo.lastInput!;
    expect(input.householdId, 'house1');
    expect(input.totalAmount, 12000);
    expect(input.paidByUid, 'amara');
    expect(input.participantUids, ['amara', 'bob', 'chloe']);
    expect(input.weights, isEmpty);
  });

  test('submit reports the failure message', () async {
    repo.nextResult = Result.failure(const ValidationFailure('Nope.'));
    final cubit = buildCubit();
    fillBasics(cubit);

    await cubit.submit();

    expect(cubit.state.status, AddExpenseStatus.failure);
    expect(cubit.state.failureMessage, 'Nope.');
  });

  test('submit does nothing while the form is invalid', () async {
    final cubit = buildCubit();

    await cubit.submit();

    expect(repo.lastInput, isNull);
    expect(cubit.state.status, AddExpenseStatus.editing);
  });
}

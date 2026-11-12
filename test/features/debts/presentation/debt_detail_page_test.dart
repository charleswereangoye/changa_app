import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/debts/domain/entities/debt.dart';
import 'package:changa_app/features/debts/domain/entities/debt_status.dart';
import 'package:changa_app/features/debts/presentation/cubit/debt_detail_cubit.dart';
import 'package:changa_app/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:changa_app/features/expenses/domain/entities/expense.dart';
import 'package:changa_app/features/expenses/domain/entities/expense_category.dart';
import 'package:changa_app/features/expenses/domain/entities/split_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtDetailCubit extends MockCubit<DebtDetailState>
    implements DebtDetailCubit {}

void main() {
  late _MockDebtDetailCubit cubit;
  late StreamController<DebtDetailState> states;

  final expense = Expense(
    id: 'expense-1',
    title: 'Groceries',
    category: ExpenseCategory.groceries,
    totalAmount: 24000,
    paidByUid: 'me',
    splitType: SplitType.equal,
    createdAt: DateTime.utc(2026, 11, 1),
  );

  Debt debt({bool outgoing = false}) {
    return Debt(
      id: 'debt-1',
      expenseId: expense.id,
      debtorUid: outgoing ? 'me' : 'kevin',
      creditorUid: outgoing ? 'kevin' : 'me',
      amount: 6000,
      creditsApplied: 20,
      status: DebtStatus.pending,
      createdAt: expense.createdAt,
    );
  }

  DebtDetailState loaded({bool outgoing = false}) {
    return DebtDetailState(
      status: DebtDetailStatus.loaded,
      debts: [debt(outgoing: outgoing)],
      expensesById: {expense.id: expense},
      netBalance: outgoing ? -6000 : 6000,
    );
  }

  setUp(() {
    cubit = _MockDebtDetailCubit();
    states = StreamController<DebtDetailState>.broadcast(sync: true);

    when(() => cubit.meUid).thenReturn('me');
    when(() => cubit.otherUid).thenReturn('kevin');
    when(() => cubit.householdId).thenReturn('home');
    when(() => cubit.sendNudge()).thenAnswer((_) async {});
    when(() => cubit.retry()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await states.close();
  });

  Future<void> pump(
    WidgetTester tester,
    DebtDetailState initialState, {
    VoidCallback? onSettle,
    ValueChanged<Expense>? onExpenseTap,
    double textScale = 1,
  }) async {
    whenListen(cubit, states.stream, initialState: initialState);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: BlocProvider<DebtDetailCubit>.value(
          value: cubit,
          child: DebtDetailPage(
            housemateName: 'Kevin',
            onSettle: onSettle,
            onExpenseTap: onExpenseTap,
          ),
        ),
      ),
    );
  }

  testWidgets('shows a loading indicator', (tester) async {
    await pump(tester, DebtDetailState(status: DebtDetailStatus.loading));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Send Nudge'), findsNothing);
  });

  testWidgets('shows an incoming balance and its expense breakdown', (
    tester,
  ) async {
    await pump(tester, loaded());

    expect(find.text('Kevin owes you'), findsOneWidget);
    expect(find.text('RWF 6,000'), findsWidgets);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Itemized breakdown'), findsOneWidget);
    expect(find.text('Chore credits applied · 20 pts'), findsOneWidget);
    expect(find.text('Send Nudge'), findsOneWidget);
  });

  testWidgets('hides both nudge buttons when I owe Kevin', (tester) async {
    await pump(tester, loaded(outgoing: true));

    expect(find.text('You owe Kevin'), findsOneWidget);
    expect(find.text('Send nudge'), findsNothing);
    expect(find.text('Send Nudge'), findsNothing);
    expect(find.text('Mark as settled'), findsOneWidget);
  });

  testWidgets('shows the empty settled state without actions', (tester) async {
    await pump(tester, DebtDetailState(status: DebtDetailStatus.loaded));

    expect(find.text('All settled up'), findsOneWidget);
    expect(find.text('No pending shared expenses'), findsOneWidget);
    expect(find.text('Send Nudge'), findsNothing);
    expect(find.text('Mark as settled'), findsNothing);
  });

  testWidgets('settlement calls the supplied navigation action', (
    tester,
  ) async {
    var calls = 0;

    await pump(tester, loaded(), onSettle: () => calls++);

    await tester.tap(find.text('Mark as settled'));

    expect(calls, 1);
  });

  testWidgets('tapping an expense passes it to the details action', (
    tester,
  ) async {
    Expense? selected;

    await pump(tester, loaded(), onExpenseTap: (value) => selected = value);

    await tester.tap(find.text('Groceries'));

    expect(selected, same(expense));
  });

  testWidgets('nudge button calls the Cubit', (tester) async {
    await pump(tester, loaded());

    await tester.tap(find.text('Send Nudge'));

    verify(() => cubit.sendNudge()).called(1);
  });

  testWidgets('shows a success message after sending', (tester) async {
    final initial = loaded();
    await pump(tester, initial);

    states.add(initial.copyWith(nudgeStatus: NudgeStatus.sending));
    await tester.pump();

    states.add(initial.copyWith(nudgeStatus: NudgeStatus.sent));
    await tester.pumpAndSettle();

    expect(find.text('Nudge sent to Kevin'), findsOneWidget);
  });

  testWidgets('shows the friendly cooldown message', (tester) async {
    final initial = loaded();
    await pump(tester, initial);

    states.add(
      initial.copyWith(
        nudgeStatus: NudgeStatus.failure,
        nudgeFailure: const NudgeCooldownFailure(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("You nudged Kevin today. Let's give them a little time."),
      findsOneWidget,
    );
  });

  testWidgets('shows a load failure and allows retry', (tester) async {
    await pump(
      tester,
      DebtDetailState(
        status: DebtDetailStatus.failure,
        failure: const NetworkFailure('Please check your connection.'),
      ),
    );

    expect(find.text('Please check your connection.'), findsOneWidget);
    expect(find.text('Send Nudge'), findsNothing);

    await tester.tap(find.text('Try again'));

    verify(() => cubit.retry()).called(1);
  });

  testWidgets('fits a narrow screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester, loaded(), onSettle: () {}, textScale: 1.5);

    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Groceries'),
      150,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

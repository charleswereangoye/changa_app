import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/debts/domain/entities/balance_summary.dart';
import 'package:changa_app/features/debts/presentation/cubit/settle_cubit.dart';
import 'package:changa_app/features/debts/presentation/pages/settle_up_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettleCubit extends MockCubit<SettleState> implements SettleCubit {}

void main() {
  late _MockSettleCubit cubit;
  late StreamController<SettleState> states;

  final summary = BalanceSummary(
    youAreOwed: 14000,
    youOwe: 4000,
    net: 10000,
    byMember: {'kevin': 14000, 'grace': -4000, 'jean': 0},
  );

  SettleState loaded() {
    return SettleState(
      status: SettleStatus.loaded,
      summary: summary,
      selectedOtherUid: 'kevin',
    );
  }

  setUpAll(() {
    registerFallbackValue(SettlementMethod.momo);
  });

  setUp(() {
    cubit = _MockSettleCubit();
    states = StreamController<SettleState>.broadcast(sync: true);

    when(() => cubit.confirm()).thenAnswer((_) async {});
    when(() => cubit.retry()).thenAnswer((_) async {});

    when(() => cubit.selectMethod(any())).thenAnswer((invocation) {
      final method = invocation.positionalArguments[0] as SettlementMethod;
      states.add(cubit.state.copyWith(method: method));
    });

    when(() => cubit.selectMember(any())).thenAnswer((invocation) {
      final uid = invocation.positionalArguments[0] as String;
      states.add(cubit.state.copyWith(selectedOtherUid: uid));
    });
  });

  tearDown(() async {
    await states.close();
  });

  Future<void> pump(
    WidgetTester tester,
    SettleState initialState, {
    VoidCallback? onDone,
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
        home: BlocProvider<SettleCubit>.value(
          value: cubit,
          child: SettleUpPage(
            memberNames: const {
              'kevin': 'Kevin',
              'grace': 'Grace',
              'jean': 'Jean',
            },
            onDone: onDone ?? () {},
          ),
        ),
      ),
    );
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows loading while balances arrive', (tester) async {
    await pump(tester, const SettleState(status: SettleStatus.loading));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('confirm-settlement')), findsNothing);
  });

  testWidgets('shows balances and excludes zero-balance members', (
    tester,
  ) async {
    await pump(tester, loaded());

    expect(find.text('Kevin'), findsOneWidget);
    expect(find.text('Owes you RWF 14,000'), findsOneWidget);
    expect(find.byKey(const Key('settle-member-jean')), findsNothing);

    await scrollTo(tester, find.byKey(const Key('settle-member-grace')));

    expect(find.text('Grace'), findsOneWidget);
    expect(find.text('You owe RWF 4,000'), findsOneWidget);
  });

  testWidgets('selecting a housemate updates the selected card', (
    tester,
  ) async {
    await pump(tester, loaded());

    await scrollTo(tester, find.byKey(const Key('select-settlement-grace')));
    await tester.tap(find.byKey(const Key('select-settlement-grace')));
    await tester.pump();

    verify(() => cubit.selectMember('grace')).called(1);
    expect(cubit.state.selectedOtherUid, 'grace');
  });

  testWidgets('confirms after choosing Bank Transfer', (tester) async {
    SettlementMethod? confirmedMethod;

    when(() => cubit.confirm()).thenAnswer((_) async {
      confirmedMethod = cubit.state.method;
    });

    await pump(tester, loaded());

    await scrollTo(tester, find.byKey(const ValueKey(SettlementMethod.bank)));
    await tester.tap(find.byKey(const ValueKey(SettlementMethod.bank)));
    await tester.pump();

    expect(cubit.state.method, SettlementMethod.bank);

    await scrollTo(tester, find.byKey(const Key('confirm-settlement')));
    await tester.tap(find.byKey(const Key('confirm-settlement')));

    verify(() => cubit.selectMethod(SettlementMethod.bank)).called(1);
    verify(() => cubit.confirm()).called(1);
    expect(confirmedMethod, SettlementMethod.bank);
  });

  testWidgets('submission disables confirmation payment changes and close', (
    tester,
  ) async {
    await pump(tester, loaded().copyWith(action: SettlementAction.submitting));

    // Avoid pumpAndSettle while the progress indicator is animating.
    await tester.scrollUntilVisible(
      find.byKey(const Key('confirm-settlement')),
      150,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-settlement')),
    );
    expect(confirm.onPressed, isNull);

    final bank = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey(SettlementMethod.bank)),
    );
    expect(bank.onSelected, isNull);

    final close = tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Close',
      ),
    );
    expect(close.onPressed, isNull);
  });

  testWidgets('failed settlement keeps the method and allows retry', (
    tester,
  ) async {
    await pump(
      tester,
      loaded().copyWith(
        method: SettlementMethod.cash,
        action: SettlementAction.failure,
        actionFailure: const NetworkFailure('Please check your connection.'),
      ),
    );

    await scrollTo(tester, find.byKey(const Key('settlement-error')));

    expect(find.text('Please check your connection.'), findsOneWidget);

    final cash = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey(SettlementMethod.cash)),
    );
    expect(cash.selected, isTrue);

    await scrollTo(tester, find.byKey(const Key('confirm-settlement')));

    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-settlement')),
    );
    expect(confirm.onPressed, isNotNull);
  });

  testWidgets('shows success after settlement completes', (tester) async {
    await pump(
      tester,
      loaded().copyWith(
        action: SettlementAction.success,
        method: SettlementMethod.momo,
      ),
    );

    expect(find.text('All settled with Kevin'), findsOneWidget);
    expect(find.text('Recorded via Mobile Money.'), findsOneWidget);
    expect(find.byKey(const Key('confirm-settlement')), findsNothing);
  });

  testWidgets('shows all settled when no net balances remain', (tester) async {
    await pump(
      tester,
      SettleState(
        status: SettleStatus.loaded,
        summary: BalanceSummary(youAreOwed: 0, youOwe: 0, net: 0, byMember: {}),
      ),
    );

    expect(find.byKey(const Key('all-settled')), findsOneWidget);
    expect(find.byKey(const Key('confirm-settlement')), findsNothing);
  });

  testWidgets('zero overall net still shows opposing member balances', (
    tester,
  ) async {
    await pump(
      tester,
      SettleState(
        status: SettleStatus.loaded,
        summary: BalanceSummary(
          youAreOwed: 4000,
          youOwe: 4000,
          net: 0,
          byMember: {'kevin': 4000, 'grace': -4000},
        ),
      ),
    );

    expect(find.byKey(const Key('all-settled')), findsNothing);
    expect(find.text('Owes you RWF 4,000'), findsOneWidget);
    expect(find.text('You owe RWF 4,000'), findsOneWidget);
  });

  testWidgets('Done calls the supplied navigation action', (tester) async {
    var calls = 0;

    await pump(tester, loaded(), onDone: () => calls++);

    await tester.tap(find.text('Done'));

    expect(calls, 1);
  });

  testWidgets('balance loading failure offers retry', (tester) async {
    await pump(
      tester,
      const SettleState(
        status: SettleStatus.failure,
        failure: NetworkFailure('Please check your connection.'),
      ),
    );

    expect(find.text('Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Try again'));

    verify(() => cubit.retry()).called(1);
  });

  testWidgets('fits a narrow screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(tester, loaded(), textScale: 1.5);

    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.byKey(const Key('confirm-settlement')));

    expect(tester.takeException(), isNull);
    expect(find.text('Confirm settlement'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/request_swap.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/chores/presentation/cubit/swap_cubit.dart';
import 'package:changa_app/features/chores/presentation/widgets/swap_sheet.dart';

class MockRequestSwap extends Mock implements RequestSwap {}

class MockWatchAllChores extends Mock implements WatchAllChores {}

final _chore = Chore(
  id: 'c1',
  title: 'Wash dishes',
  difficulty: ChoreDifficulty.easy,
  assignedToUid: 'me',
  dueDate: DateTime(2026, 11, 12),
  status: ChoreStatus.pending,
  createdByUid: 'me',
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late MockRequestSwap requestSwap;
  late MockWatchAllChores watchAll;

  setUp(() {
    requestSwap = MockRequestSwap();
    watchAll = MockWatchAllChores();
    when(() => watchAll(any())).thenAnswer((_) => const Stream.empty());
  });

  Widget sheet(List<SwapCandidate> people) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: BlocProvider<SwapCubit>(
        create: (_) => SwapCubit(
          requestSwap: requestSwap,
          watchAllChores: watchAll,
          householdId: 'home',
          chore: _chore,
          candidates: people,
        ),
        child: const SwapSheet(),
      ),
    ),
  );

  testWidgets('lists the housemates for the chore', (tester) async {
    await tester.pumpWidget(
      sheet(const [
        SwapCandidate(uid: 'kevin', name: 'Kevin Mugo'),
        SwapCandidate(uid: 'jean', name: 'Jean Baptiste'),
      ]),
    );

    expect(find.text('Swap this chore'), findsOneWidget);
    expect(find.text('Wash dishes'), findsOneWidget);
    expect(find.text('Kevin Mugo'), findsOneWidget);
    expect(find.text('Jean Baptiste'), findsOneWidget);
    expect(find.text('0 chores this week'), findsNWidgets(2));
    expect(find.text('Request Swap'), findsNWidgets(2));
  });

  testWidgets('tapping Request Swap sends it to that person', (tester) async {
    when(
      () => requestSwap(
        householdId: any(named: 'householdId'),
        choreId: any(named: 'choreId'),
        toUid: any(named: 'toUid'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => Result<void>.success(null));
    await tester.pumpWidget(
      sheet(const [SwapCandidate(uid: 'kevin', name: 'Kevin Mugo')]),
    );

    await tester.enterText(find.byKey(const Key('swap-note-field')), 'Please');
    await tester.tap(find.text('Request Swap'));
    await tester.pump();

    verify(
      () => requestSwap(
        householdId: 'home',
        choreId: 'c1',
        toUid: 'kevin',
        note: 'Please',
      ),
    ).called(1);
  });

  testWidgets('says so when there is nobody to swap with', (tester) async {
    await tester.pumpWidget(sheet(const []));

    expect(
      find.text('There is nobody else in the household to swap with yet.'),
      findsOneWidget,
    );
    expect(find.text('Request Swap'), findsNothing);
  });
}

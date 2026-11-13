import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/router/route_names.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/chores/domain/usecases/reassign_chores.dart';
import 'package:changa_app/features/debts/domain/usecases/get_outstanding_balance.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/leave_household.dart';
import 'package:changa_app/features/household/domain/usecases/regenerate_pin.dart';
import 'package:changa_app/features/household/domain/usecases/remove_member.dart';
import 'package:changa_app/features/household/domain/usecases/transfer_admin.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/household/presentation/cubit/manage_household_cubit.dart';
import 'package:changa_app/features/household/presentation/pages/manage_household_page.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';

class MockWatchHousehold extends Mock implements WatchHousehold {}

class MockWatchMembers extends Mock implements WatchMembers {}

class MockGetUsersByIds extends Mock implements GetUsersByIds {}

class MockRegeneratePin extends Mock implements RegeneratePin {}

class MockRemoveMember extends Mock implements RemoveMember {}

class MockTransferAdmin extends Mock implements TransferAdmin {}

class MockLeaveHousehold extends Mock implements LeaveHousehold {}

class MockGetOutstandingBalance extends Mock implements GetOutstandingBalance {}

class MockReassignChores extends Mock implements ReassignChores {}

void main() {
  final fixedDate = DateTime(2026, 10, 31, 10, 0);

  final testHousehold = Household(
    id: 'house-1',
    name: 'Kigali Nest',
    type: HouseholdType.apartment,
    expectedMembers: 4,
    pin: '482916',
    adminUid: 'amara',
    createdAt: fixedDate,
  );

  final amaraMember = Member(
    uid: 'amara',
    role: MemberRole.admin,
    credits: 40,
    joinedAt: fixedDate,
  );

  final jeanMember = Member(
    uid: 'jean',
    role: MemberRole.member,
    credits: 30,
    joinedAt: fixedDate.add(const Duration(minutes: 5)),
  );

  final kevinMember = Member(
    uid: 'kevin',
    role: MemberRole.member,
    credits: 10,
    joinedAt: fixedDate.add(const Duration(minutes: 10)),
  );

  final graceMember = Member(
    uid: 'grace',
    role: MemberRole.member,
    credits: 20,
    joinedAt: fixedDate.add(const Duration(minutes: 15)),
  );

  final testMembers = [amaraMember, jeanMember, kevinMember, graceMember];

  const testNames = {
    'amara': 'Amara Okoye',
    'jean': 'Jean Baptiste',
    'kevin': 'Kevin Mugisha',
    'grace': 'Grace Uwimana',
  };

  const testHarmonyScores = {'amara': 82, 'jean': 90, 'kevin': 68, 'grace': 88};

  late MockWatchHousehold watchHousehold;
  late MockWatchMembers watchMembers;
  late MockGetUsersByIds getUsersByIds;
  late MockRegeneratePin regeneratePin;
  late MockRemoveMember removeMember;
  late MockTransferAdmin transferAdmin;
  late MockLeaveHousehold leaveHousehold;
  late MockGetOutstandingBalance getOutstandingBalance;
  late MockReassignChores reassignChores;

  setUp(() {
    watchHousehold = MockWatchHousehold();
    watchMembers = MockWatchMembers();
    getUsersByIds = MockGetUsersByIds();
    regeneratePin = MockRegeneratePin();
    removeMember = MockRemoveMember();
    transferAdmin = MockTransferAdmin();
    leaveHousehold = MockLeaveHousehold();
    getOutstandingBalance = MockGetOutstandingBalance();
    reassignChores = MockReassignChores();
  });

  ManageHouseholdCubit buildCubit({String currentUid = 'amara'}) {
    return ManageHouseholdCubit(
      watchHousehold: watchHousehold,
      watchMembers: watchMembers,
      getUsersByIds: getUsersByIds,
      regeneratePin: regeneratePin,
      removeMember: removeMember,
      transferAdmin: transferAdmin,
      leaveHousehold: leaveHousehold,
      getOutstandingBalance: getOutstandingBalance,
      reassignChores: reassignChores,
      currentUid: currentUid,
      initialHarmonyScores: testHarmonyScores,
    );
  }

  // 1. UNIT TESTS: ManageHouseholdCubit
  group('ManageHouseholdCubit', () {
    test(
      'loads household, sorts admin first, and resolves member names',
      () async {
        final householdController = StreamController<Household?>.broadcast(
          sync: true,
        );
        final membersController = StreamController<List<Member>>.broadcast(
          sync: true,
        );
        addTearDown(() async {
          await householdController.close();
          await membersController.close();
        });

        when(() => watchHousehold('house-1'))
            .thenAnswer((_) => householdController.stream);
        when(() => watchMembers('house-1'))
            .thenAnswer((_) => membersController.stream);
        when(() => getUsersByIds(any())).thenAnswer(
          (_) async => Result.success([
            AppUser(
              uid: 'amara',
              fullName: 'Amara Okoye',
              email: 'amara@alu.edu',
              phone: '0780000001',
              createdAt: fixedDate,
            ),
            AppUser(
              uid: 'kevin',
              fullName: 'Kevin Mugisha',
              email: 'kevin@alu.edu',
              phone: '0780000002',
              createdAt: fixedDate,
            ),
          ]),
        );

        final cubit = buildCubit();
        addTearDown(cubit.close);

        await cubit.load(householdId: 'house-1', currentUid: 'amara');
        expect(cubit.state, isA<ManageHouseholdStateLoading>());

        householdController.add(testHousehold);
        // Emit non-admin first to verify sorting places admin at index 0
        membersController.add([kevinMember, amaraMember]);
        await Future<void>.delayed(Duration.zero);

        final loaded = cubit.state as ManageHouseholdStateLoaded;
        expect(loaded.household.name, 'Kigali Nest');
        expect(loaded.isAdmin, isTrue);
        expect(loaded.members.first.uid, 'amara');
        expect(loaded.displayNameFor('amara'), 'Amara Okoye');
        expect(loaded.displayNameFor('kevin'), 'Kevin Mugisha');
      },
    );

    test(
      'regeneratePin updates household PIN and emits pinRegenerated action',
      () async {
        when(() => regeneratePin('house-1'))
            .thenAnswer((_) async => Result.success('915304'));

        final cubit = buildCubit();
        addTearDown(cubit.close);
        cubit.seedState(
          household: testHousehold,
          members: testMembers,
          memberNames: testNames,
        );

        final result = await cubit.regeneratePin();

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, '915304');
        final loaded = cubit.state as ManageHouseholdStateLoaded;
        expect(loaded.household.pin, '915304');
        expect(loaded.lastAction, ManageHouseholdAction.pinRegenerated);
        verify(() => regeneratePin('house-1')).called(1);
      },
    );

    test('transferAdmin updates adminUid and flips member roles', () async {
      when(() => transferAdmin(householdId: 'house-1', newAdminUid: 'jean'))
          .thenAnswer((_) async => Result.success(null));

      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.seedState(
        household: testHousehold,
        members: testMembers,
        memberNames: testNames,
      );

      final result = await cubit.transferAdmin('jean');

      expect(result.isSuccess, isTrue);
      final loaded = cubit.state as ManageHouseholdStateLoaded;
      expect(loaded.household.adminUid, 'jean');
      expect(loaded.isAdmin, isFalse);
      expect(
        loaded.members.firstWhere((m) => m.uid == 'jean').role,
        MemberRole.admin,
      );
      expect(
        loaded.members.firstWhere((m) => m.uid == 'amara').role,
        MemberRole.member,
      );
      expect(loaded.lastAction, ManageHouseholdAction.adminTransferred);
    });

    test('fetchOutstandingBalance returns pending balance from GetOutstandingBalance', () async {
      when(() => getOutstandingBalance(householdId: 'house-1', uid: 'kevin'))
          .thenAnswer((_) async => Result.success(18500));

      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.seedState(
        household: testHousehold,
        members: testMembers,
        memberNames: testNames,
      );

      final balance = await cubit.fetchOutstandingBalance('kevin');
      expect(balance, 18500);
      verify(() => getOutstandingBalance(householdId: 'house-1', uid: 'kevin'))
          .called(1);
    });

    test('removeMember calls ReassignChores(fromUid: removed, toUid: admin) then RemoveMember', () async {
      when(
        () => reassignChores(
          householdId: 'house-1',
          fromUid: 'kevin',
          toUid: 'amara',
        ),
      ).thenAnswer((_) async => Result.success(null));
      when(() => removeMember(householdId: 'house-1', uid: 'kevin'))
          .thenAnswer((_) async => Result.success(null));

      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.seedState(
        household: testHousehold,
        members: testMembers,
        memberNames: testNames,
      );

      final result = await cubit.removeMember('kevin');

      expect(result.isSuccess, isTrue);
      final loaded = cubit.state as ManageHouseholdStateLoaded;
      expect(loaded.members.any((m) => m.uid == 'kevin'), isFalse);
      expect(loaded.lastAction, ManageHouseholdAction.memberRemoved);

      verifyInOrder([
        () => reassignChores(
          householdId: 'house-1',
          fromUid: 'kevin',
          toUid: 'amara',
        ),
        () => removeMember(householdId: 'house-1', uid: 'kevin'),
      ]);
    });

    test('removeMember aborts if ReassignChores fails', () async {
      when(
        () => reassignChores(
          householdId: 'house-1',
          fromUid: 'kevin',
          toUid: 'amara',
        ),
      ).thenAnswer(
        (_) async => Result.failure(const NetworkFailure('Offline')),
      );

      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.seedState(
        household: testHousehold,
        members: testMembers,
        memberNames: testNames,
      );

      final result = await cubit.removeMember('kevin');

      expect(result.isFailure, isTrue);
      verifyNever(
        () => removeMember(
          householdId: any(named: 'householdId'),
          uid: any(named: 'uid'),
        ),
      );
    });
  });

  // 2. WIDGET TESTS: ManageHouseholdPage
  group('ManageHouseholdPage', () {
    Widget buildTestApp(ManageHouseholdCubit cubit) {
      final router = GoRouter(
        initialLocation: '/household/manage',
        routes: [
          GoRoute(
            path: '/household/manage',
            name: RouteNames.manageHousehold,
            builder: (context, state) => ManageHouseholdPage(cubit: cubit),
          ),
          GoRoute(
            path: '/household/created',
            name: RouteNames.householdCreated,
            builder: (context, state) {
              final passed = state.extra as Household?;
              return Scaffold(
                body: Center(
                  child: Text('HouseholdCreated:${passed?.pin ?? ''}'),
                ),
              );
            },
          ),
        ],
      );

      return MaterialApp.router(routerConfig: router);
    }

    testWidgets(
      'renders summary card, formatted PIN, members list, role badges, and Harmony scores',
      (tester) async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        cubit.seedState(
          household: testHousehold,
          members: testMembers,
          memberNames: testNames,
          harmonyScores: testHarmonyScores,
        );

        await tester.pumpWidget(buildTestApp(cubit));
        await tester.pumpAndSettle();

        expect(find.text('Manage Household'), findsOneWidget);
        expect(find.text('Kigali Nest'), findsNWidgets(2));
        expect(find.text('Apartment · 4 members'), findsOneWidget);
        expect(find.text('MEMBERS (4)'), findsOneWidget);

        expect(find.text('Amara Okoye'), findsOneWidget);
        expect(find.text('Jean Baptiste'), findsOneWidget);
        expect(find.text('Kevin Mugisha'), findsOneWidget);
        expect(find.text('Grace Uwimana'), findsOneWidget);

        expect(find.text('ADMIN'), findsOneWidget);
        expect(find.text('MEMBER'), findsNWidgets(3));
        expect(find.text('Harmony 82'), findsOneWidget);
        expect(find.text('Harmony 90'), findsOneWidget);
        expect(find.text('482 916'), findsOneWidget);
      },
    );

    testWidgets(
      'Regenerate PIN opens confirmation dialog with exact spec text and regenerates on confirm',
      (tester) async {
        when(() => regeneratePin('house-1'))
            .thenAnswer((_) async => Result.success('774209'));

        final cubit = buildCubit();
        addTearDown(cubit.close);
        cubit.seedState(
          household: testHousehold,
          members: testMembers,
          memberNames: testNames,
          harmonyScores: testHarmonyScores,
        );

        await tester.pumpWidget(buildTestApp(cubit));
        await tester.pumpAndSettle();

        final regenButton = find.byKey(const Key('regenerate-pin-button'));
        await tester.ensureVisible(regenButton);
        await tester.tap(regenButton);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Anyone with the old PIN will no longer be able to join. Current members keep their access.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Regenerate'));
        await tester.pumpAndSettle();

        expect(find.text('774 209'), findsOneWidget);
        verify(() => regeneratePin('house-1')).called(1);
      },
    );

    testWidgets(
      'Remove from household dialog shows Outstanding balance: X RWF and calls ReassignChores + RemoveMember on confirm',
      (tester) async {
        when(() => getOutstandingBalance(householdId: 'house-1', uid: 'kevin'))
            .thenAnswer((_) async => Result.success(12500));
        when(
          () => reassignChores(
            householdId: 'house-1',
            fromUid: 'kevin',
            toUid: 'amara',
          ),
        ).thenAnswer((_) async => Result.success(null));
        when(() => removeMember(householdId: 'house-1', uid: 'kevin'))
            .thenAnswer((_) async => Result.success(null));

        final cubit = buildCubit();
        addTearDown(cubit.close);
        cubit.seedState(
          household: testHousehold,
          members: testMembers,
          memberNames: testNames,
          harmonyScores: testHarmonyScores,
        );

        await tester.pumpWidget(buildTestApp(cubit));
        await tester.pumpAndSettle();

        // Tap the "..." menu on Kevin's row
        final kevinMenu = find.byKey(const ValueKey('member-menu-kevin'));
        await tester.ensureVisible(kevinMenu);
        await tester.tap(kevinMenu);
        await tester.pumpAndSettle();

        expect(find.text('Transfer admin'), findsOneWidget);
        expect(find.text('Remove from household'), findsOneWidget);

        await tester.tap(find.byKey(const Key('action-remove-member')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Outstanding balance: 12,500 RWF'),
          findsOneWidget,
        );
        expect(find.text('Remove anyway'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Remove anyway'));
        await tester.pumpAndSettle();

        verifyInOrder([
          () => getOutstandingBalance(householdId: 'house-1', uid: 'kevin'),
          () => reassignChores(
            householdId: 'house-1',
            fromUid: 'kevin',
            toUid: 'amara',
          ),
          () => removeMember(householdId: 'house-1', uid: 'kevin'),
        ]);
        expect(find.text('Kevin Mugisha'), findsNothing);
      },
    );

    testWidgets('Invite new member button opens Household Created page', (
      tester,
    ) async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      cubit.seedState(
        household: testHousehold,
        members: testMembers,
        memberNames: testNames,
        harmonyScores: testHarmonyScores,
      );

      await tester.pumpWidget(buildTestApp(cubit));
      await tester.pumpAndSettle();

      final inviteBtn = find.byKey(const Key('invite-new-member-btn'));
      await tester.ensureVisible(inviteBtn);
      await tester.tap(inviteBtn);
      await tester.pumpAndSettle();

      expect(find.text('HouseholdCreated:482916'), findsOneWidget);
    });

    testWidgets(
      'non-admin member does not see Regenerate PIN or member overflow menus',
      (tester) async {
        final cubit = buildCubit(currentUid: 'jean');
        addTearDown(cubit.close);
        cubit.seedState(
          household: testHousehold,
          members: testMembers,
          memberNames: testNames,
          harmonyScores: testHarmonyScores,
          currentUid: 'jean',
        );

        await tester.pumpWidget(buildTestApp(cubit));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('regenerate-pin-button')), findsNothing);
        expect(find.byKey(const ValueKey('member-menu-kevin')), findsNothing);
      },
    );
  });
}

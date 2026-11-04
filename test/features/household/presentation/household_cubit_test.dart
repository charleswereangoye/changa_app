import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/create_household.dart';
import 'package:changa_app/features/household/domain/usecases/join_household.dart';
import 'package:changa_app/features/household/domain/usecases/preview_household_by_pin.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/household/presentation/cubit/create_household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/join_household_cubit.dart';
import 'package:changa_app/features/household/presentation/pages/household_created_page.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';

class MockCreateHousehold extends Mock implements CreateHousehold {}

class MockPreviewHouseholdByPin extends Mock implements PreviewHouseholdByPin {}

class MockJoinHousehold extends Mock implements JoinHousehold {}

class MockWatchHousehold extends Mock implements WatchHousehold {}

class MockWatchMembers extends Mock implements WatchMembers {}

class MockGetUsersByIds extends Mock implements GetUsersByIds {}

class MockWatchUser extends Mock implements WatchUser {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  final testDate = DateTime(2026, 10, 24);
  const adminUid = 'uid_admin_1';
  const memberUid = 'uid_member_2';

  final testHousehold = Household(
    id: 'house_123',
    name: 'Kigali Nest',
    type: HouseholdType.apartment,
    expectedMembers: 4,
    pin: '482916',
    adminUid: adminUid,
    createdAt: testDate,
  );

  final secondHousehold = Household(
    id: 'house_456',
    name: 'Nyarutarama Villa',
    type: HouseholdType.house,
    expectedMembers: 3,
    pin: '654321',
    adminUid: memberUid,
    createdAt: testDate,
  );

  final testMembers = [
    Member(
      uid: adminUid,
      role: MemberRole.admin,
      credits: 120,
      joinedAt: testDate,
    ),
    Member(
      uid: memberUid,
      role: MemberRole.member,
      credits: 40,
      joinedAt: testDate,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(HouseholdType.apartment);
  });

  group('CreateHouseholdCubit', () {
    late MockCreateHousehold mockCreateHousehold;

    setUp(() {
      mockCreateHousehold = MockCreateHousehold();
    });

    test('starts with default values (Apartment, 4 roommates)', () {
      final cubit = CreateHouseholdCubit(createHousehold: mockCreateHousehold);
      expect(cubit.state.name, '');
      expect(cubit.state.type, HouseholdType.apartment);
      expect(cubit.state.expectedMembers, 4);
      cubit.close();
    });

    blocTest<CreateHouseholdCubit, CreateHouseholdState>(
      'rejects name shorter than 3 characters or longer than 40 characters',
      build: () => CreateHouseholdCubit(createHousehold: mockCreateHousehold),
      act: (cubit) async {
        await cubit.submit(name: 'Ab');
        await cubit.submit(name: 'A' * 41);
      },
      expect: () => [
        isA<CreateHouseholdStateFailure>(),
        isA<CreateHouseholdStateFailure>(),
      ],
      verify: (_) {
        verifyNever(
          () => mockCreateHousehold(
            name: any(named: 'name'),
            type: any(named: 'type'),
            expectedMembers: any(named: 'expectedMembers'),
          ),
        );
      },
    );

    test('in-flight guard ignores duplicate submit on double tap', () async {
      final completer = Completer<Result<Household>>();
      when(
        () => mockCreateHousehold(
          name: 'Kigali Nest',
          type: HouseholdType.apartment,
          expectedMembers: 4,
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = CreateHouseholdCubit(createHousehold: mockCreateHousehold);

      final firstCall = cubit.submit(name: 'Kigali Nest');
      final secondCall = cubit.submit(name: 'Kigali Nest');

      expect(cubit.state, isA<CreateHouseholdStateSubmitting>());
      completer.complete(Result.success(testHousehold));
      await Future.wait([firstCall, secondCall]);

      verify(
        () => mockCreateHousehold(
          name: 'Kigali Nest',
          type: HouseholdType.apartment,
          expectedMembers: 4,
        ),
      ).called(1);
      await cubit.close();
    });

    test('does not emit after cubit is closed during in-flight create', () async {
      final completer = Completer<Result<Household>>();
      when(
        () => mockCreateHousehold(
          name: 'Kigali Nest',
          type: HouseholdType.apartment,
          expectedMembers: 4,
        ),
      ).thenAnswer((_) => completer.future);

      final cubit = CreateHouseholdCubit(createHousehold: mockCreateHousehold);
      final future = cubit.submit(name: 'Kigali Nest');
      await cubit.close();

      completer.complete(Result.success(testHousehold));
      await future;
      expect(cubit.isClosed, true);
    });
  });

  group('JoinHouseholdCubit', () {
    late MockPreviewHouseholdByPin mockPreview;
    late MockJoinHousehold mockJoin;

    const preview1 = HouseholdPreview(name: 'Kigali Nest', memberCount: 4);
    const preview2 = HouseholdPreview(name: 'Remera Hub', memberCount: 3);

    setUp(() {
      mockPreview = MockPreviewHouseholdByPin();
      mockJoin = MockJoinHousehold();
    });

    test('ignores out-of-order preview lookup results', () async {
      final completer1 = Completer<Result<HouseholdPreview>>();
      final completer2 = Completer<Result<HouseholdPreview>>();

      when(() => mockPreview('111111')).thenAnswer((_) => completer1.future);
      when(() => mockPreview('222222')).thenAnswer((_) => completer2.future);

      final cubit = JoinHouseholdCubit(
        previewHouseholdByPin: mockPreview,
        joinHousehold: mockJoin,
      );

      final call1 = cubit.onPinCompleted('111111');
      final call2 = cubit.onPinCompleted('222222');

      completer2.complete(Result.success(preview2));
      await call2;
      expect(
        cubit.state,
        const JoinHouseholdStatePreviewLoaded(pin: '222222', preview: preview2),
      );

      completer1.complete(Result.success(preview1));
      await call1;
      expect(
        cubit.state,
        const JoinHouseholdStatePreviewLoaded(pin: '222222', preview: preview2),
      );

      await cubit.close();
    });

    test('invalidates preview when deleting a PIN digit or changing PIN', () async {
      when(() => mockPreview('482916'))
          .thenAnswer((_) async => Result.success(preview1));

      final cubit = JoinHouseholdCubit(
        previewHouseholdByPin: mockPreview,
        joinHousehold: mockJoin,
      );

      await cubit.onPinCompleted('482916');
      expect(cubit.state.preview, preview1);
      expect(cubit.state.canJoin, true);

      cubit.onPinChanged('48291');
      expect(cubit.state, const JoinHouseholdStateInitial(pin: '48291'));
      expect(cubit.state.preview, isNull);
      expect(cubit.state.canJoin, false);

      await cubit.close();
    });

    test('prevents PIN changes and duplicate submissions during joining', () async {
      when(() => mockPreview('482916'))
          .thenAnswer((_) async => Result.success(preview1));
      final joinCompleter = Completer<Result<Household>>();
      when(() => mockJoin('482916')).thenAnswer((_) => joinCompleter.future);

      final cubit = JoinHouseholdCubit(
        previewHouseholdByPin: mockPreview,
        joinHousehold: mockJoin,
      );

      await cubit.onPinCompleted('482916');

      final join1 = cubit.joinHousehold();
      final join2 = cubit.joinHousehold();
      cubit.onPinChanged('48291');
      await cubit.onPinCompleted('111111');

      expect(cubit.state, isA<JoinHouseholdStateJoining>());
      expect(cubit.state.pin, '482916');

      joinCompleter.complete(Result.success(testHousehold));
      await Future.wait([join1, join2]);

      verify(() => mockJoin('482916')).called(1);
      verifyNever(() => mockPreview('111111'));
      await cubit.close();
    });

    test('guards preview and join completions when cubit closes mid-request', () async {
      final previewCompleter = Completer<Result<HouseholdPreview>>();
      when(() => mockPreview('482916'))
          .thenAnswer((_) => previewCompleter.future);

      final cubit = JoinHouseholdCubit(
        previewHouseholdByPin: mockPreview,
        joinHousehold: mockJoin,
      );

      final future = cubit.onPinCompleted('482916');
      await cubit.close();
      previewCompleter.complete(Result.success(preview1));
      await future;
      expect(cubit.isClosed, true);
    });
  });

  group('HouseholdCubit session, streams, and race conditions', () {
    late MockWatchHousehold mockWatchHousehold;
    late MockWatchMembers mockWatchMembers;
    late MockGetUsersByIds mockGetUsersByIds;
    late MockWatchUser mockWatchUser;
    late MockAuthCubit mockAuthCubit;
    late StreamController<AuthState> authStateController;
    late StreamController<AppUser?> userDocController;
    late StreamController<Household?> householdController;
    late StreamController<List<Member>> membersController;

    final adminAppUser = AppUser(
      uid: adminUid,
      fullName: 'Janna Bendou',
      email: 'janna@example.com',
      phone: '+250788000111',
      householdId: 'house_123',
      createdAt: testDate,
    );

    final memberAppUser = AppUser(
      uid: memberUid,
      fullName: 'Alice Mukamana',
      email: 'alice@example.com',
      phone: '+250788000222',
      householdId: 'house_456',
      createdAt: testDate,
    );

    setUp(() {
      mockWatchHousehold = MockWatchHousehold();
      mockWatchMembers = MockWatchMembers();
      mockGetUsersByIds = MockGetUsersByIds();
      mockWatchUser = MockWatchUser();
      mockAuthCubit = MockAuthCubit();
      authStateController = StreamController<AuthState>.broadcast();
      userDocController = StreamController<AppUser?>.broadcast();
      householdController = StreamController<Household?>.broadcast();
      membersController = StreamController<List<Member>>.broadcast();

      when(() => mockAuthCubit.state).thenReturn(const AuthStateInitial());
      whenListen(mockAuthCubit, authStateController.stream);

      when(() => mockWatchUser(any()))
          .thenAnswer((_) => userDocController.stream);
      when(() => mockWatchHousehold('house_123'))
          .thenAnswer((_) => householdController.stream);
      when(() => mockWatchMembers('house_123'))
          .thenAnswer((_) => membersController.stream);
    });

    tearDown(() async {
      await authStateController.close();
      await userDocController.close();
      await householdController.close();
      await membersController.close();
    });

    test(
      'loads household via WatchUser on login/restart and clears on sign-out',
      () async {
        when(() => mockGetUsersByIds(any())).thenAnswer(
          (_) async => Result.success([adminAppUser, memberAppUser]),
        );

        final cubit = HouseholdCubit(
          watchHousehold: mockWatchHousehold,
          watchMembers: mockWatchMembers,
          getUsersByIds: mockGetUsersByIds,
          watchUser: mockWatchUser,
          authCubit: mockAuthCubit,
        );

        authStateController.add(Authenticated(adminAppUser));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        verify(() => mockWatchUser(adminUid)).called(1);

        userDocController.add(adminAppUser);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        verify(() => mockWatchHousehold('house_123')).called(1);

        householdController.add(testHousehold);
        membersController.add(testMembers);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state, isA<HouseholdStateLoaded>());
        expect(cubit.state.household?.name, 'Kigali Nest');
        expect(cubit.state.displayNameFor(adminUid), 'Janna Bendou');
        expect(cubit.state.currentMember?.uid, adminUid);
        expect(cubit.state.myCredits, 120);

        authStateController.add(const Unauthenticated());
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(cubit.state, isA<HouseholdStateEmpty>());
        expect(cubit.state.household, isNull);
        expect(cubit.state.members, isEmpty);
        expect(cubit.state.memberNames, isEmpty);
        expect(cubit.state.currentMember, isNull);

        await cubit.close();
      },
    );

    test(
      'resets caches and caller overrides across account/household switches and ignores stale name lookups',
      () async {
        final slowNamesCompleter = Completer<Result<List<AppUser>>>();
        final secondHouseController = StreamController<Household?>.broadcast();
        final secondMembersController =
            StreamController<List<Member>>.broadcast();

        when(() => mockWatchHousehold('house_456'))
            .thenAnswer((_) => secondHouseController.stream);
        when(() => mockWatchMembers('house_456'))
            .thenAnswer((_) => secondMembersController.stream);

        when(() => mockGetUsersByIds([adminUid, memberUid]))
            .thenAnswer((_) => slowNamesCompleter.future);
        when(() => mockGetUsersByIds([memberUid])).thenAnswer(
          (_) async => Result.success([memberAppUser]),
        );

        final cubit = HouseholdCubit(
          watchHousehold: mockWatchHousehold,
          watchMembers: mockWatchMembers,
          getUsersByIds: mockGetUsersByIds,
        );

        cubit.loadHousehold('house_123', currentUid: adminUid);
        householdController.add(testHousehold);
        membersController.add(testMembers);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        cubit.loadHousehold('house_456', currentUid: memberUid);
        secondHouseController.add(secondHousehold);
        secondMembersController.add([
          Member(
            uid: memberUid,
            role: MemberRole.admin,
            credits: 50,
            joinedAt: testDate,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        slowNamesCompleter.complete(Result.success([adminAppUser]));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(cubit.state.household?.id, 'house_456');
        expect(cubit.state.currentMember?.uid, memberUid);
        expect(cubit.state.memberNames.containsKey(adminUid), false);
        expect(cubit.state.displayNameFor(memberUid), 'Alice Mukamana');

        await secondHouseController.close();
        await secondMembersController.close();
        await cubit.close();
      },
    );

    test('HouseholdCreatedPage formats share text per B8 spec', () {
      expect(
        HouseholdCreatedPage.buildShareMessage('482916'),
        'Join my household on Changa with PIN 482 916',
      );
    });
  });
}
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
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

class MockCreateHousehold extends Mock implements CreateHousehold {}

class MockPreviewHouseholdByPin extends Mock implements PreviewHouseholdByPin {}

class MockJoinHousehold extends Mock implements JoinHousehold {}

class MockWatchHousehold extends Mock implements WatchHousehold {}

class MockWatchMembers extends Mock implements WatchMembers {}

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

    blocTest<CreateHouseholdCubit, CreateHouseholdState>(
      'clamps roommates stepper between 2 and 10',
      build: () => CreateHouseholdCubit(createHousehold: mockCreateHousehold),
      act: (cubit) {
        cubit.expectedMembersChanged(1);
        cubit.expectedMembersChanged(15);
      },
      expect: () => [
        const CreateHouseholdStateInitial(expectedMembers: 2),
        const CreateHouseholdStateInitial(expectedMembers: 10),
      ],
    );

    blocTest<CreateHouseholdCubit, CreateHouseholdState>(
      'emits [Submitting, Success] when createHousehold succeeds',
      build: () {
        when(
          () => mockCreateHousehold(
            name: 'Kigali Nest',
            type: HouseholdType.dorm,
            expectedMembers: 5,
          ),
        ).thenAnswer((_) async => Result.success(testHousehold));
        return CreateHouseholdCubit(createHousehold: mockCreateHousehold);
      },
      act: (cubit) async {
        cubit.typeChanged(HouseholdType.dorm);
        cubit.expectedMembersChanged(5);
        await cubit.submit(name: '  Kigali Nest  ');
      },
      expect: () => [
        const CreateHouseholdStateInitial(
          type: HouseholdType.dorm,
          expectedMembers: 4,
        ),
        const CreateHouseholdStateInitial(
          type: HouseholdType.dorm,
          expectedMembers: 5,
        ),
        const CreateHouseholdStateSubmitting(
          name: 'Kigali Nest',
          type: HouseholdType.dorm,
          expectedMembers: 5,
        ),
        CreateHouseholdStateSuccess(
          household: testHousehold,
          name: 'Kigali Nest',
          type: HouseholdType.dorm,
          expectedMembers: 5,
        ),
      ],
    );
  });

  group('JoinHouseholdCubit', () {
    late MockPreviewHouseholdByPin mockPreview;
    late MockJoinHousehold mockJoin;

    const preview = HouseholdPreview(name: 'Kigali Nest', memberCount: 4);

    setUp(() {
      mockPreview = MockPreviewHouseholdByPin();
      mockJoin = MockJoinHousehold();
    });

    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'emits [PreviewLoading, PreviewLoaded] when 6-digit PIN is valid',
      build: () {
        when(() => mockPreview('482916'))
            .thenAnswer((_) async => Result.success(preview));
        return JoinHouseholdCubit(
          previewHouseholdByPin: mockPreview,
          joinHousehold: mockJoin,
        );
      },
      act: (cubit) => cubit.onPinCompleted('482916'),
      expect: () => [
        const JoinHouseholdStatePreviewLoading(pin: '482916'),
        const JoinHouseholdStatePreviewLoaded(pin: '482916', preview: preview),
      ],
    );

    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'emits polite error when PIN is not found',
      build: () {
        when(() => mockPreview('999999')).thenAnswer(
          (_) async => Result.failure(
            const NotFoundFailure(
              'No household found with that PIN. Please check the digits.',
            ),
          ),
        );
        return JoinHouseholdCubit(
          previewHouseholdByPin: mockPreview,
          joinHousehold: mockJoin,
        );
      },
      act: (cubit) => cubit.onPinCompleted('999999'),
      expect: () => [
        const JoinHouseholdStatePreviewLoading(pin: '999999'),
        const JoinHouseholdStateError(
          pin: '999999',
          message: 'No household found with that PIN. Please check the digits.',
        ),
      ],
    );

    blocTest<JoinHouseholdCubit, JoinHouseholdState>(
      'joins household after preview and emits JoinHouseholdStateSuccess',
      build: () {
        when(() => mockPreview('482916'))
            .thenAnswer((_) async => Result.success(preview));
        when(() => mockJoin('482916'))
            .thenAnswer((_) async => Result.success(testHousehold));
        return JoinHouseholdCubit(
          previewHouseholdByPin: mockPreview,
          joinHousehold: mockJoin,
        );
      },
      act: (cubit) async {
        await cubit.onPinCompleted('482916');
        await cubit.joinHousehold();
      },
      expect: () => [
        const JoinHouseholdStatePreviewLoading(pin: '482916'),
        const JoinHouseholdStatePreviewLoaded(pin: '482916', preview: preview),
        const JoinHouseholdStateJoining(pin: '482916', preview: preview),
        JoinHouseholdStateSuccess(
          household: testHousehold,
          pin: '482916',
          preview: preview,
        ),
      ],
    );
  });

  group('HouseholdCubit & Share Formatting', () {
    late MockWatchHousehold mockWatchHousehold;
    late MockWatchMembers mockWatchMembers;
    late StreamController<Household?> householdController;
    late StreamController<List<Member>> membersController;

    setUp(() {
      mockWatchHousehold = MockWatchHousehold();
      mockWatchMembers = MockWatchMembers();
      householdController = StreamController<Household?>.broadcast();
      membersController = StreamController<List<Member>>.broadcast();

      when(() => mockWatchHousehold('house_123'))
          .thenAnswer((_) => householdController.stream);
      when(() => mockWatchMembers('house_123'))
          .thenAnswer((_) => membersController.stream);
    });

    tearDown(() async {
      await householdController.close();
      await membersController.close();
    });

    test('streams household, members with display names, and own member doc with credits', () async {
      final cubit = HouseholdCubit(
        watchHousehold: mockWatchHousehold,
        watchMembers: mockWatchMembers,
        currentUidResolver: () => adminUid,
        memberNamesResolver: (_) async => {
          adminUid: 'Janna Bendou',
          memberUid: 'Alice Mukamana',
        },
      );

      cubit.loadHousehold('house_123');
      expect(cubit.state, isA<HouseholdStateLoading>());

      householdController.add(testHousehold);
      membersController.add(testMembers);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state, isA<HouseholdStateLoaded>());
      expect(cubit.state.household?.name, 'Kigali Nest');
      expect(cubit.state.members.length, 2);
      expect(cubit.state.displayNameFor(adminUid), 'Janna Bendou');
      expect(cubit.state.displayNameFor(memberUid), 'Alice Mukamana');
      expect(cubit.state.displayNameFor('missing_uid'), 'Former member');
      expect(cubit.state.currentMember?.uid, adminUid);
      expect(cubit.state.myCredits, 120);
      expect(cubit.state.isAdmin, true);

      await cubit.close();
    });

    test('HouseholdCreatedPage formats share text per B8 spec', () {
      expect(
        HouseholdCreatedPage.buildShareMessage('482916'),
        'Join my household on Changa with PIN 482 916',
      );
    });
  });
}

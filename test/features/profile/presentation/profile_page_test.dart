import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/core/theme/app_colors.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/leave_household.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/profile/presentation/pages/profile_page.dart';
import 'package:changa_app/injection_container.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHouseholdCubit extends Mock implements HouseholdCubit {}

class MockChoreRepository extends Mock implements ChoreRepository {}

class MockLeaveHousehold extends Mock implements LeaveHousehold {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockHouseholdCubit mockHouseholdCubit;
  late StreamController<AppUser?> authStreamController;

  final testUser = AppUser(
    uid: 'u_amara',
    fullName: 'Amara Okoye',
    email: 'amara@changa.rw',
    phone: '+250788111222',
    householdId: 'h_kigali',
    createdAt: DateTime(2024, 8, 1),
  );

  final testHousehold = Household(
    id: 'h_kigali',
    name: 'Kigali Nest',
    type: HouseholdType.apartment,
    expectedMembers: 3,
    pin: '123456',
    adminUid: 'u_amara',
    createdAt: DateTime(2024, 8, 1),
  );

  final testMember = Member(
    uid: 'u_amara',
    role: MemberRole.admin,
    credits: 145,
    joinedAt: DateTime(2024, 8, 1),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockHouseholdCubit = MockHouseholdCubit();
    authStreamController = StreamController<AppUser?>.broadcast();

    when(() => mockAuthRepository.currentUser).thenReturn(testUser);
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStreamController.stream);

    when(() => mockHouseholdCubit.state).thenReturn(
      HouseholdStateLoaded(
        household: testHousehold,
        members: [testMember],
        currentMember: testMember,
      ),
    );
    when(() => mockHouseholdCubit.stream).thenAnswer(
      (_) => Stream.value(
        HouseholdStateLoaded(
          household: testHousehold,
          members: [testMember],
          currentMember: testMember,
        ),
      ),
    );
  });

  tearDown(() {
    authStreamController.close();
    if (sl.isRegistered<ChoreRepository>()) {
      sl.unregister<ChoreRepository>();
    }
    if (sl.isRegistered<LeaveHousehold>()) {
      sl.unregister<LeaveHousehold>();
    }
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(authRepository: mockAuthRepository),
          ),
          BlocProvider<HouseholdCubit>.value(value: mockHouseholdCubit),
        ],
        child: const ProfilePage(),
      ),
    );
  }

  group('ProfilePage', () {
    testWidgets('renders user profile header, name, subtitle and stats row', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify User info
      expect(find.text('Amara Okoye'), findsOneWidget);
      expect(
        find.textContaining('Kigali Nest · Member since Aug 2024'),
        findsOneWidget,
      );

      // Verify Stats
      expect(find.text('Harmony'), findsOneWidget);
      expect(find.text('Credits (pts)'), findsOneWidget);
      expect(find.text('Chores Done'), findsOneWidget);
      expect(find.text('145'), findsOneWidget); // member credits
    });

    testWidgets('renders settings menu categories and tiles with Admin badge', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Section headers
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('HOUSEHOLD'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);

      // Account tiles
      expect(
        find.byKey(const Key('profile-tile-edit-profile')),
        findsOneWidget,
      );
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byKey(const Key('profile-tile-preferences')), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(
        find.byKey(const Key('profile-tile-payment-methods')),
        findsOneWidget,
      );
      expect(find.text('Payment Methods'), findsOneWidget);

      // Household tiles
      expect(
        find.byKey(const Key('profile-tile-manage-household')),
        findsOneWidget,
      );
      expect(find.text('Manage Household'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('ADMIN')).style?.color,
        AppColors.lightGreen,
      );
      expect(
        find.byKey(const Key('profile-tile-leave-household')),
        findsOneWidget,
      );
      expect(find.text('Leave Household'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Leave Household')).style?.color,
        AppColors.lightGreen,
      );

      // Support tiles
      expect(find.byKey(const Key('profile-tile-help')), findsOneWidget);
      expect(find.text('Help & FAQ'), findsOneWidget);
      expect(find.byKey(const Key('profile-tile-logout')), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Log Out')).style?.color,
        AppColors.lightGreen,
      );
    });

    testWidgets('tapping Log Out opens ConfirmDialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile-tile-logout')));
      await tester.tap(find.byKey(const Key('profile-tile-logout')));
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsWidgets);
      expect(
        find.text('Are you sure you want to log out of your Changa account?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);

      final confirmBtn = tester.widget<FilledButton>(
        find.byKey(const Key('confirm-dialog-confirm')),
      );
      expect(
        confirmBtn.style?.backgroundColor?.resolve({}),
        AppColors.lightGreen,
      );

      when(() => mockAuthRepository.signOut())
          .thenAnswer((_) async => Result.success(null));

      await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepository.signOut()).called(1);
    });

    testWidgets('tapping Help & FAQ opens FAQ bottom sheet', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('profile-tile-help')));
      await tester.tap(find.byKey(const Key('profile-tile-help')));
      await tester.pumpAndSettle();

      expect(find.text('Help & FAQ'), findsWidgets);
      expect(find.text('How does splitting work?'), findsOneWidget);
      expect(find.text('What are House Credits?'), findsOneWidget);
    });

    testWidgets(
      'regression: failed logout shows error snackbar and stays on ProfilePage',
      (tester) async {
        when(() => mockAuthRepository.signOut()).thenAnswer(
          (_) async =>
              Result.failure(const AuthFailure('Network connection failed')),
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('profile-tile-logout')),
        );
        await tester.tap(find.byKey(const Key('profile-tile-logout')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
        await tester.pumpAndSettle();

        expect(find.text('Network connection failed'), findsOneWidget);
        expect(find.text('Amara Okoye', skipOffstage: false), findsOneWidget);
        expect(find.byKey(const Key('profile-tile-logout')), findsOneWidget);
      },
    );

    testWidgets(
      'regression: calculated Harmony score displays dynamic score based on household chores',
      (tester) async {
        final mockChoreRepo = MockChoreRepository();
        final testChore = Chore(
          id: 'c1',
          title: 'Wash Dishes',
          difficulty: ChoreDifficulty.medium,
          assignedToUid: 'u_amara',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: ChoreStatus.done,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdByUid: 'u_amara',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        when(() => mockChoreRepo.watchAllChores('h_kigali'))
            .thenAnswer((_) => Stream.value([testChore]));

        sl.registerSingleton<ChoreRepository>(mockChoreRepo);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // 1 chore completed on time yields calculated Harmony score of 100
        expect(find.text('100'), findsOneWidget);
        expect(find.text('Harmony'), findsOneWidget);
      },
    );

    testWidgets(
      'regression: leaving household as admin shows warning dialog preventing departure',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('profile-tile-leave-household')),
        );
        await tester.tap(find.byKey(const Key('profile-tile-leave-household')));
        await tester.pumpAndSettle();

        expect(find.text('Cannot Leave Household'), findsOneWidget);
        expect(
          find.textContaining(
            'As the household administrator, you cannot leave directly.',
          ),
          findsOneWidget,
        );
        expect(find.text('OK'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('Cannot Leave Household'), findsNothing);
      },
    );

    testWidgets(
      'regression: leaving household as regular member invokes LeaveHousehold on confirmation',
      (tester) async {
        final regularMember = Member(
          uid: 'u_amara',
          role: MemberRole.member,
          credits: 50,
          joinedAt: DateTime(2024, 8, 1),
        );
        when(() => mockHouseholdCubit.state).thenReturn(
          HouseholdStateLoaded(
            household: testHousehold,
            members: [regularMember],
            currentMember: regularMember,
          ),
        );

        final mockLeave = MockLeaveHousehold();
        when(() => mockLeave('h_kigali'))
            .thenAnswer((_) async => Result.success(null));
        sl.registerSingleton<LeaveHousehold>(mockLeave);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const Key('profile-tile-leave-household')),
        );
        await tester.tap(find.byKey(const Key('profile-tile-leave-household')));
        await tester.pumpAndSettle();

        expect(find.text('Leave Household'), findsWidgets);
        expect(
          find.textContaining('Are you sure you want to leave Kigali Nest?'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
        await tester.pumpAndSettle();

        verify(() => mockLeave('h_kigali')).called(1);
        expect(find.text('You have left Kigali Nest.'), findsOneWidget);
      },
    );

    testWidgets(
      'regression: tapping notification preferences settings tile is responsive',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final tile = find.byKey(const Key('profile-tile-preferences'));
        expect(tile, findsOneWidget);
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'regression: Admin badge, Leave Household, and Log Out tiles use lightGreen and no pink',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Admin badge wording and color
        final adminText = tester.widget<Text>(find.text('ADMIN'));
        expect(adminText.style?.color, AppColors.lightGreen);

        // Leave Household wording and color
        final leaveHouseholdText = tester.widget<Text>(
          find.text('Leave Household'),
        );
        expect(leaveHouseholdText.style?.color, AppColors.lightGreen);

        // Log Out wording and color
        await tester.ensureVisible(
          find.byKey(const Key('profile-tile-logout')),
        );
        final logoutText = tester.widget<Text>(find.text('Log Out'));
        expect(logoutText.style?.color, AppColors.lightGreen);

        // Tap Log Out and verify confirmation popup button is lightGreen
        await tester.tap(find.byKey(const Key('profile-tile-logout')));
        await tester.pumpAndSettle();

        final popupConfirmBtn = tester.widget<FilledButton>(
          find.byKey(const Key('confirm-dialog-confirm')),
        );
        expect(
          popupConfirmBtn.style?.backgroundColor?.resolve({}),
          AppColors.lightGreen,
        );
      },
    );
  });
}

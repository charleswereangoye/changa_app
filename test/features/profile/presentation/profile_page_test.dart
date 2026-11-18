import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/profile/presentation/pages/profile_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockHouseholdCubit extends Mock implements HouseholdCubit {}

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
        find.byKey(const Key('profile-tile-leave-household')),
        findsOneWidget,
      );
      expect(find.text('Leave Household'), findsOneWidget);

      // Support tiles
      expect(find.byKey(const Key('profile-tile-help')), findsOneWidget);
      expect(find.text('Help & FAQ'), findsOneWidget);
      expect(find.byKey(const Key('profile-tile-logout')), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
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
  });
}

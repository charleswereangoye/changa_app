import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:changa_app/features/profile/presentation/pages/edit_profile_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileCubit extends Mock implements ProfileCubit {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late MockProfileCubit mockProfileCubit;
  late StreamController<AppUser?> authStreamController;

  final testUser = AppUser(
    uid: 'u_amara',
    fullName: 'Amara Okoye',
    email: 'amara@changa.rw',
    phone: '+250788111222',
    householdId: 'h_kigali',
    createdAt: DateTime(2024, 8, 1),
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockProfileCubit = MockProfileCubit();
    authStreamController = StreamController<AppUser?>.broadcast();

    when(() => mockAuthRepository.currentUser).thenReturn(testUser);
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStreamController.stream);

    when(() => mockProfileCubit.state).thenReturn(ProfileStateLoaded(testUser));
    when(() => mockProfileCubit.stream)
        .thenAnswer((_) => Stream.value(ProfileStateLoaded(testUser)));
  });

  tearDown(() {
    authStreamController.close();
  });

  Widget buildTestWidget({ProfileCubit? cubit, AppUser? initialUser}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(authRepository: mockAuthRepository),
          ),
        ],
        child: EditProfilePage(
          cubit: cubit ?? mockProfileCubit,
          initialUser: initialUser ?? testUser,
        ),
      ),
    );
  }

  group('EditProfilePage', () {
    testWidgets('renders input fields populated with existing user data', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Amara Okoye'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('+250788111222'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('amara@changa.rw'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('validates required name field on submission', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Clear the name field
      await tester.enterText(
        find.byKey(const Key('edit-profile-name-input')),
        '',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.byKey(const Key('edit-profile-save-button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name.'), findsOneWidget);
      verifyNever(
        () => mockProfileCubit.editProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      );
    });

    testWidgets('validates phone number format on submission', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter invalid phone
      await tester.enterText(
        find.byKey(const Key('edit-profile-phone-input')),
        '12345',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.byKey(const Key('edit-profile-save-button')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Please enter a valid phone number'),
        findsOneWidget,
      );
      verifyNever(
        () => mockProfileCubit.editProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      );
    });

    testWidgets('submits updated values when form is valid', (tester) async {
      when(
        () => mockProfileCubit.editProfile(
          fullName: any(named: 'fullName'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter new name and phone
      await tester.enterText(
        find.byKey(const Key('edit-profile-name-input')),
        'Amara Updated',
      );
      await tester.enterText(
        find.byKey(const Key('edit-profile-phone-input')),
        '+250 788 999 888',
      );
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.byKey(const Key('edit-profile-save-button')));
      await tester.pumpAndSettle();

      verify(
        () => mockProfileCubit.editProfile(
          fullName: 'Amara Updated',
          phone: '+250 788 999 888',
        ),
      ).called(1);
    });

    testWidgets(
      'regression: saving then reopening the profile editor populates the latest saved data',
      (tester) async {
        final updatedUser = AppUser(
          uid: 'u_amara',
          fullName: 'Amara Diallo',
          email: 'amara@changa.rw',
          phone: '+250 788 333 444',
          householdId: 'h_kigali',
          createdAt: DateTime(2024, 8, 1),
        );

        when(
          () => mockProfileCubit.editProfile(
            fullName: 'Amara Diallo',
            phone: '+250 788 333 444',
          ),
        ).thenAnswer((_) async {
          when(() => mockProfileCubit.state)
              .thenReturn(ProfileStateLoaded(updatedUser));
          when(() => mockAuthRepository.currentUser).thenReturn(updatedUser);
          return true;
        });

        final authCubit = AuthCubit(authRepository: mockAuthRepository);

        // Open editor the first time
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider<AuthCubit>.value(
              value: authCubit,
              child: EditProfilePage(
                cubit: mockProfileCubit,
                initialUser: testUser,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Amara Okoye'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('edit-profile-name-input')),
          'Amara Diallo',
        );
        await tester.enterText(
          find.byKey(const Key('edit-profile-phone-input')),
          '+250 788 333 444',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('edit-profile-save-button')));
        await tester.pumpAndSettle();

        // Reopen editor with the updated user
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider<AuthCubit>.value(
              value: authCubit,
              child: EditProfilePage(
                cubit: mockProfileCubit,
                initialUser: updatedUser,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Amara Diallo'), findsOneWidget);
        expect(find.text('+250 788 333 444'), findsOneWidget);

        authCubit.close();
      },
    );
  });
}

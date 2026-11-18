import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:changa_app/core/enums/settlement_method.dart';
import 'package:changa_app/core/theme/app_theme.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/profile/domain/services/preferences_store.dart';
import 'package:changa_app/features/profile/presentation/cubit/preferences_cubit.dart';
import 'package:changa_app/features/profile/presentation/pages/payment_methods_page.dart';

class MockPreferencesStore extends Mock implements PreferencesStore {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockPreferencesStore store;
  late PreferencesCubit preferencesCubit;
  late MockAuthRepository authRepository;
  late AuthCubit authCubit;

  final testUser = AppUser(
    uid: 'user-1',
    fullName: 'Amara Okoye',
    email: 'amara@example.com',
    phone: '+250 788 123 456',
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() async {
    store = MockPreferencesStore();
    when(() => store.getString(any(), fallback: any(named: 'fallback')))
        .thenAnswer((i) async => i.namedArguments[#fallback] as String);
    when(() => store.getBool(any(), fallback: any(named: 'fallback')))
        .thenAnswer((i) async => i.namedArguments[#fallback] as bool);
    when(() => store.setString(any(), any())).thenAnswer((_) async {});
    when(() => store.setBool(any(), any())).thenAnswer((_) async {});
    preferencesCubit = PreferencesCubit(store);
    await preferencesCubit.load();

    authRepository = MockAuthRepository();
    when(() => authRepository.currentUser).thenReturn(testUser);
    when(() => authRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(testUser));
    when(() => authRepository.updateCurrentUser(any())).thenReturn(null);
    authCubit = AuthCubit(authRepository: authRepository);
  });

  tearDown(() {
    preferencesCubit.close();
    authCubit.close();
  });

  Widget buildTestPage() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PreferencesCubit>.value(value: preferencesCubit),
        BlocProvider<AuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const PaymentMethodsPage(),
      ),
    );
  }

  testWidgets('renders all 3 payment methods and the info banner', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestPage());
    await tester.pumpAndSettle();

    expect(find.text('Payment Methods'), findsOneWidget);
    expect(find.text('SETTLEMENT METHODS'), findsOneWidget);
    expect(find.byKey(const Key('payment-method-momo')), findsOneWidget);
    expect(find.byKey(const Key('payment-method-cash')), findsOneWidget);
    expect(find.byKey(const Key('payment-method-bank')), findsOneWidget);
    expect(find.textContaining('+250 788 123 456'), findsOneWidget);
  });

  testWidgets('tapping Cash updates the default settlement method', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('payment-method-cash')));
    await tester.pumpAndSettle();

    expect(
      preferencesCubit.state.defaultSettlementMethod,
      SettlementMethod.cash,
    );
    expect(find.text('Default payment method set to Cash.'), findsOneWidget);
  });

  testWidgets('tapping Bank updates the default settlement method', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestPage());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('payment-method-bank')));
    await tester.pumpAndSettle();

    expect(
      preferencesCubit.state.defaultSettlementMethod,
      SettlementMethod.bank,
    );
    expect(
      find.text('Default payment method set to Bank Transfer.'),
      findsOneWidget,
    );
  });
}

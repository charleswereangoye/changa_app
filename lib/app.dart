import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/household/presentation/cubit/household_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/profile/presentation/cubit/preferences_cubit.dart';
import 'features/profile/presentation/cubit/preferences_state.dart';
import 'injection_container.dart';

/// The root widget of the Changa application.
class ChangaApp extends StatelessWidget {
  const ChangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => sl.isRegistered<AuthCubit>()
              ? sl<AuthCubit>()
              : AuthCubit(authRepository: sl()),
        ),
        BlocProvider<HouseholdCubit>(
          lazy: false,
          create: (context) {
            final cubit = sl.isRegistered<HouseholdCubit>()
                ? sl<HouseholdCubit>()
                : HouseholdCubit();
            cubit.bindAuthCubit(context.read<AuthCubit>());
            return cubit;
          },
        ),
        BlocProvider<PreferencesCubit>(
          lazy: false,
          create: (_) => sl<PreferencesCubit>()..load(),
        ),
        BlocProvider<NotificationsCubit>(
          create: (_) => sl.isRegistered<NotificationsCubit>()
              ? sl<NotificationsCubit>()
              : NotificationsCubit(sl(), sl(), sl()),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          final householdCubit = context.read<HouseholdCubit>();
          if (state is Authenticated) {
            householdCubit.onAuthUserChanged(state.user.uid);
          } else if (state is Unauthenticated) {
            householdCubit.clearHousehold();
            try {
              final location =
                  AppRouter.router.routerDelegate.currentConfiguration.uri.path;
              final isAuthScreen =
                  location == '/' ||
                  location == '/onboarding' ||
                  location == '/login' ||
                  location == '/sign-up' ||
                  location == '/forgot-password' ||
                  location == '/verify-email';
              if (!isAuthScreen) {
                AppRouter.router.goNamed(RouteNames.login);
              }
            } catch (_) {}
          }
        },
        child: BlocBuilder<PreferencesCubit, PreferencesState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
          builder: (context, preferences) => MaterialApp.router(
            title: 'Changa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: ThemeMode.light,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}

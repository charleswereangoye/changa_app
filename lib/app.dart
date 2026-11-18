import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/household/presentation/cubit/household_cubit.dart';
import 'features/notifications/presentation/cubit/notifications_cubit.dart';
import 'features/profile/presentation/cubit/preferences_cubit.dart';
import 'features/profile/presentation/cubit/preferences_state.dart';
import 'injection_container.dart';

import 'dart:async';

import 'core/router/route_names.dart';
import 'features/notifications/domain/entities/app_notification.dart';
import 'features/notifications/presentation/widgets/notification_listener_host.dart';

/// The root widget of the Changa application.
class ChangaApp extends StatelessWidget {
  const ChangaApp({super.key});

  void _openNotification(BuildContext context, AppNotification notification) {
    final auth = context.read<AuthCubit>().state;
    final household = context.read<HouseholdCubit>().state;

    if (auth is! Authenticated ||
        household is! HouseholdStateLoaded ||
        household.currentMember?.uid != auth.user.uid ||
        notification.recipientUid != auth.user.uid) {
      return;
    }

    switch (notification.type) {
      case 'swapRequest':
      case 'swapResponse':
        AppRouter.router.goNamed(RouteNames.chores);
        return;

      case 'nudge':
      case 'newExpense':
      case 'settled':
        final otherUid = notification.actorUid;

        if (otherUid.trim().isEmpty || otherUid == auth.user.uid) {
          return;
        }

        unawaited(
          AppRouter.router.pushNamed<void>(
            RouteNames.debtDetail,
            pathParameters: {'uid': otherUid},
          ),
        );
        return;

      default:
        return;
    }
  }

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
          }
        },
        child: BlocBuilder<PreferencesCubit, PreferencesState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
          builder: (context, preferences) => MaterialApp.router(
            title: 'Changa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            themeMode: preferences.themeMode,
            routerConfig: AppRouter.router,
            builder: (context, preferences) => MaterialApp.router(
              title: 'Changa',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              themeMode: preferences.themeMode,
              routerConfig: AppRouter.router,
              builder: (context, child) => NotificationListenerHost(
                navigatorKey: AppRouter.rootNavigatorKey,
                onOpen: (notification) =>
                    _openNotification(context, notification),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/chores/presentation/pages/add_edit_chore_page.dart';
import '../../features/chores/presentation/pages/chore_roster_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/debts/presentation/pages/debt_detail_page.dart';
import '../../features/debts/presentation/pages/settle_up_page.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/household/presentation/pages/create_household_page.dart';
import '../../features/household/presentation/pages/household_created_page.dart';
import '../../features/household/presentation/pages/join_household_page.dart';
import '../../features/household/presentation/pages/manage_household_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/preferences_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'home_shell.dart';
import 'route_names.dart';

/// Central application router connecting all screens across features.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash & Onboarding
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth screens
      GoRoute(
        path: '/sign-up',
        name: RouteNames.signUp,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),

      // Household setup
      GoRoute(
        path: '/household/create',
        name: RouteNames.createHousehold,
        builder: (context, state) => const CreateHouseholdPage(),
      ),
      GoRoute(
        path: '/household/created',
        name: RouteNames.householdCreated,
        builder: (context, state) => const HouseholdCreatedPage(),
      ),
      GoRoute(
        path: '/household/join',
        name: RouteNames.joinHousehold,
        builder: (context, state) => const JoinHouseholdPage(),
      ),
      GoRoute(
        path: '/household/manage',
        name: RouteNames.manageHousehold,
        builder: (context, state) => const ManageHouseholdPage(),
      ),

      // Main Tab Shell (Dashboard, Chores, Activity, Profile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/dashboard',
                name: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/chores',
                name: RouteNames.chores,
                builder: (context, state) => const ChoreRosterPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/activity',
                name: RouteNames.activity,
                builder: (context, state) => const ActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),

      // Expenses
      GoRoute(
        path: '/expenses/add',
        name: RouteNames.addExpense,
        builder: (context, state) => const AddExpensePage(),
      ),

      // Debts & Settling
      GoRoute(
        path: '/debts/:uid',
        name: RouteNames.debtDetail,
        builder: (context, state) => const DebtDetailPage(),
      ),
      GoRoute(
        path: '/debts/:uid/settle',
        name: RouteNames.settleUp,
        builder: (context, state) => const SettleUpPage(),
      ),

      // Chores management
      GoRoute(
        path: '/chores/add',
        name: RouteNames.addChore,
        builder: (context, state) => const AddEditChorePage(),
      ),
      GoRoute(
        path: '/chores/:id/edit',
        name: RouteNames.editChore,
        builder: (context, state) => const AddEditChorePage(),
      ),

      // Profile & Preferences
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/preferences',
        name: RouteNames.preferences,
        builder: (context, state) => const PreferencesPage(),
      ),
    ],
  );
}

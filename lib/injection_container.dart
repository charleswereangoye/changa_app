// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Main dependency injection container orchestrating feature initializers

import 'package:get_it/get_it.dart';
import 'package:changa_app/features/auth/auth_injection.dart';
import 'package:changa_app/features/profile/profile_injection.dart';
import 'package:changa_app/features/household/household_injection.dart';
import 'package:changa_app/features/activity/activity_injection.dart';
import 'package:changa_app/features/expenses/expenses_injection.dart';
import 'package:changa_app/features/dashboard/dashboard_injection.dart';
import 'package:changa_app/features/debts/debts_injection.dart';
import 'package:changa_app/features/notifications/notifications_injection.dart';
import 'package:changa_app/features/chores/chores_injection.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await initAuth();
  await initProfile();
  await initHousehold();
  await initActivity();
  await initExpenses();
  await initDashboard();
  await initDebts();
  await initNotifications();
  await initChores();
}

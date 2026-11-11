// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Dependency injection registration for Dashboard feature

import 'package:get_it/get_it.dart';

import 'package:changa_app/features/activity/domain/entities/activity.dart';
import 'package:changa_app/features/activity/domain/usecases/watch_recent_activity.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/usecases/watch_all_chores.dart';
import 'package:changa_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:changa_app/features/debts/domain/usecases/watch_debts_since.dart';
import 'package:changa_app/features/debts/domain/usecases/watch_pending_debts.dart';

final sl = GetIt.instance;

Future<void> initDashboard() async {
  if (sl.isRegistered<DashboardCubit>()) return;

  sl.registerFactory<DashboardCubit>(() {
    // Chores (E) and activity (B) may not have a data layer registered yet.
    // Until they do, those sections just show as empty instead of crashing.
    final WatchChoresFn watchChores = sl.isRegistered<WatchAllChores>()
        ? sl<WatchAllChores>().call
        : (String _) => Stream.value(const <Chore>[]);

    final WatchRecentActivityFn watchActivity =
        sl.isRegistered<WatchRecentActivity>()
        ? (String householdId) =>
              sl<WatchRecentActivity>()(householdId: householdId)
        : (String _) => Stream.value(const <Activity>[]);

    return DashboardCubit(
      watchPendingDebts: sl<WatchPendingDebts>().call,
      watchDebtsSince: sl<WatchDebtsSince>().call,
      watchChores: watchChores,
      watchRecentActivity: watchActivity,
    );
  });
}

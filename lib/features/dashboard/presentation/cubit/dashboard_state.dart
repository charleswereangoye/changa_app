// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: States for DashboardCubit

part of 'dashboard_cubit.dart';

/// Each dashboard section loads on its own, so one failing source (say,
/// chores) never blanks the whole screen.
enum DashboardSection { loading, ready, failed }

class DashboardState extends Equatable {
  const DashboardState({
    this.hasHousehold = true,
    this.balanceStatus = DashboardSection.loading,
    this.balance,
    this.harmonyStatus = DashboardSection.loading,
    this.harmony,
    this.activityStatus = DashboardSection.loading,
    this.recentActivity = const [],
  });

  /// False when the signed-in person has not joined a household yet.
  final bool hasHousehold;

  final DashboardSection balanceStatus;
  final BalanceSummary? balance;

  final DashboardSection harmonyStatus;

  /// Null while ready means there is nothing to judge yet (show a dash).
  final HarmonyScore? harmony;

  final DashboardSection activityStatus;
  final List<Activity> recentActivity;

  /// A new household with nothing in it yet.
  bool get isEmptyHousehold =>
      hasHousehold &&
      balanceStatus == DashboardSection.ready &&
      activityStatus == DashboardSection.ready &&
      (balance?.byMember.isEmpty ?? true) &&
      recentActivity.isEmpty;

  DashboardState copyWith({
    DashboardSection? balanceStatus,
    BalanceSummary? balance,
    DashboardSection? harmonyStatus,
    HarmonyScore? harmony,
    bool clearHarmony = false,
    DashboardSection? activityStatus,
    List<Activity>? recentActivity,
  }) {
    return DashboardState(
      hasHousehold: hasHousehold,
      balanceStatus: balanceStatus ?? this.balanceStatus,
      balance: balance ?? this.balance,
      harmonyStatus: harmonyStatus ?? this.harmonyStatus,
      harmony: clearHarmony ? null : (harmony ?? this.harmony),
      activityStatus: activityStatus ?? this.activityStatus,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }

  @override
  List<Object?> get props => [
    hasHousehold,
    balanceStatus,
    balance,
    harmonyStatus,
    harmony,
    activityStatus,
    recentActivity,
  ];
}

part of 'dashboard_cubit.dart';

enum DashboardSection { loading, ready, failed }

class DashboardState extends Equatable {
  const DashboardState({
    this.hasHousehold = true,
    this.balanceStatus = DashboardSection.loading,
    this.balance,
    this.harmonyStatus = DashboardSection.loading,
    this.harmony,
    this.choreCount = 0,
    this.activityStatus = DashboardSection.loading,
    this.recentActivity = const [],
  });

  final bool hasHousehold;

  final DashboardSection balanceStatus;
  final BalanceSummary? balance;

  final DashboardSection harmonyStatus;
  final HarmonyScore? harmony;
  final int choreCount;

  final DashboardSection activityStatus;
  final List<Activity> recentActivity;

  bool get isEmptyHousehold =>
      hasHousehold &&
      balanceStatus == DashboardSection.ready &&
      harmonyStatus == DashboardSection.ready &&
      activityStatus == DashboardSection.ready &&
      harmony == null &&
      choreCount == 0 &&
      (balance?.byMember.values.every((amount) => amount == 0) ?? true) &&
      recentActivity.isEmpty;

  DashboardState copyWith({
    DashboardSection? balanceStatus,
    BalanceSummary? balance,
    DashboardSection? harmonyStatus,
    HarmonyScore? harmony,
    bool clearHarmony = false,
    int? choreCount,
    DashboardSection? activityStatus,
    List<Activity>? recentActivity,
  }) {
    return DashboardState(
      hasHousehold: hasHousehold,
      balanceStatus: balanceStatus ?? this.balanceStatus,
      balance: balance ?? this.balance,
      harmonyStatus: harmonyStatus ?? this.harmonyStatus,
      harmony: clearHarmony ? null : (harmony ?? this.harmony),
      choreCount: choreCount ?? this.choreCount,
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
    choreCount,
    activityStatus,
    recentActivity,
  ];
}

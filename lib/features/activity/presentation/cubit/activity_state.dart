// States for ActivityCubit

part of 'activity_cubit.dart';

sealed class ActivityState extends Equatable {
  const ActivityState();

  List<Activity> get recentActivities => const [];

  @override
  List<Object?> get props => [];
}

class ActivityStateInitial extends ActivityState {
  const ActivityStateInitial();
}

class ActivityStateLoading extends ActivityState {
  @override
  final List<Activity> recentActivities;
  final List<DateTime> availableMonths;
  final DateTime? selectedMonth;
  final String searchQuery;

  const ActivityStateLoading({
    this.recentActivities = const [],
    this.availableMonths = const [],
    this.selectedMonth,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
    recentActivities,
    availableMonths,
    selectedMonth,
    searchQuery,
  ];
}

class ActivityStateLoaded extends ActivityState {
  final List<Activity> activities;
  @override
  final List<Activity> recentActivities;
  final List<DateTime> availableMonths;
  final DateTime selectedMonth;
  final String searchQuery;

  ActivityStateLoaded({
    required List<Activity> activities,
    List<Activity> recentActivities = const [],
    required List<DateTime> availableMonths,
    required this.selectedMonth,
    this.searchQuery = '',
  }) : activities = List<Activity>.unmodifiable(activities),
       recentActivities = List<Activity>.unmodifiable(recentActivities),
       availableMonths = List<DateTime>.unmodifiable(availableMonths);

  /// Filters the loaded month's activities against the formatted message,
  /// card title, subtitle, trailing amount/points, and raw type/refId.
  List<Activity> filterActivities({
    Map<String, String> memberNames = const {},
    String? currentUid,
    Map<String, String> refTitles = const {},
  }) {
    final trimmed = searchQuery.trim().toLowerCase();
    if (trimmed.isEmpty) return activities;

    return activities.where((activity) {
      final fullMessage = ActivityMessageBuilder.build(
        activity,
        memberNames,
        currentUid: currentUid,
        refTitles: refTitles,
      ).toLowerCase();
      final cardTitle = ActivityMessageBuilder.formatCardTitle(
        activity,
        memberNames,
        currentUid: currentUid,
        refTitles: refTitles,
      ).toLowerCase();
      final cardSubtitle = ActivityMessageBuilder.formatCardSubtitle(
        activity,
        memberNames,
        currentUid: currentUid,
      ).toLowerCase();
      final badge = (ActivityMessageBuilder.formatTrailingBadge(activity) ?? '')
          .toLowerCase();
      final actorName = (memberNames[activity.actorUid] ?? '').toLowerCase();
      final targetName =
          (activity.targetUid != null
                  ? memberNames[activity.targetUid!] ?? ''
                  : '')
              .toLowerCase();

      return fullMessage.contains(trimmed) ||
          cardTitle.contains(trimmed) ||
          cardSubtitle.contains(trimmed) ||
          badge.contains(trimmed) ||
          actorName.contains(trimmed) ||
          targetName.contains(trimmed) ||
          activity.type.name.toLowerCase().contains(trimmed) ||
          (activity.amount != null &&
              activity.amount.toString().contains(trimmed));
    }).toList();
  }

  ActivityStateLoaded copyWith({
    List<Activity>? activities,
    List<Activity>? recentActivities,
    List<DateTime>? availableMonths,
    DateTime? selectedMonth,
    String? searchQuery,
  }) {
    return ActivityStateLoaded(
      activities: activities ?? this.activities,
      recentActivities: recentActivities ?? this.recentActivities,
      availableMonths: availableMonths ?? this.availableMonths,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    activities,
    recentActivities,
    availableMonths,
    selectedMonth,
    searchQuery,
  ];
}

class ActivityStateFailure extends ActivityState {
  final Failure failure;
  @override
  final List<Activity> recentActivities;
  final List<DateTime> availableMonths;
  final DateTime selectedMonth;
  final String searchQuery;

  const ActivityStateFailure(
    this.failure, {
    this.recentActivities = const [],
    this.availableMonths = const [],
    required this.selectedMonth,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
    failure,
    recentActivities,
    availableMonths,
    selectedMonth,
    searchQuery,
  ];
}

part of 'chores_cubit.dart';

enum ChoresStatus { loading, loaded, failure }

/// A one-off message for the screen to show, such as "+10 pts".
/// The id changes every time so two identical messages still register.
class ChoreNotice extends Equatable {
  const ChoreNotice(this.id, this.text, {this.isError = false});

  final int id;
  final String text;
  final bool isError;

  @override
  List<Object?> get props => [id, text, isError];
}

class ChoresState extends Equatable {
  const ChoresState({
    required this.today,
    required this.selectedDay,
    this.status = ChoresStatus.loading,
    this.chores = const [],
    this.completingIds = const {},
    this.failure,
    this.notice,
  });

  final DateTime today;
  final DateTime selectedDay;
  final ChoresStatus status;
  final List<Chore> chores;

  /// Chores whose completion is being saved right now.
  final Set<String> completingIds;
  final Failure? failure;
  final ChoreNotice? notice;

  /// Monday to Sunday of the current week, for the day strip.
  List<DateTime> get weekDays => DateHelpers.weekDays(today);

  bool get isSelectedDayToday => DateHelpers.isSameDay(selectedDay, today);

  ChoresState copyWith({
    DateTime? selectedDay,
    ChoresStatus? status,
    List<Chore>? chores,
    Set<String>? completingIds,
    Failure? failure,
    ChoreNotice? notice,
    bool clearFailure = false,
    bool clearNotice = false,
  }) {
    return ChoresState(
      today: today,
      selectedDay: selectedDay ?? this.selectedDay,
      status: status ?? this.status,
      chores: chores ?? this.chores,
      completingIds: completingIds ?? this.completingIds,
      failure: clearFailure ? null : (failure ?? this.failure),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
    today,
    selectedDay,
    status,
    chores,
    completingIds,
    failure?.message,
    notice,
  ];
}

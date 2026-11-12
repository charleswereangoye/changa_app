part of 'settle_cubit.dart';

enum SettleStatus { initial, loading, loaded, failure }

enum SettlementAction { idle, submitting, success, failure }

class SettleState extends Equatable {
  const SettleState({
    this.status = SettleStatus.initial,
    this.summary,
    this.selectedOtherUid,
    this.method = SettlementMethod.momo,
    this.action = SettlementAction.idle,
    this.failure,
    this.actionFailure,
  });

  final SettleStatus status;
  final BalanceSummary? summary;
  final String? selectedOtherUid;
  final SettlementMethod method;
  final SettlementAction action;
  final Failure? failure;
  final Failure? actionFailure;

  int get selectedBalance => summary?.byMember[selectedOtherUid] ?? 0;

  bool get isSubmitting => action == SettlementAction.submitting;

  bool get allSettled =>
      status == SettleStatus.loaded &&
      summary != null &&
      summary!.youAreOwed == 0 &&
      summary!.youOwe == 0;

  bool get canConfirm =>
      status == SettleStatus.loaded &&
      selectedOtherUid != null &&
      selectedBalance != 0 &&
      !isSubmitting &&
      action != SettlementAction.success;

  SettleState copyWith({
    SettleStatus? status,
    BalanceSummary? summary,
    String? selectedOtherUid,
    bool clearSelection = false,
    SettlementMethod? method,
    SettlementAction? action,
    Failure? failure,
    bool clearFailure = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return SettleState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedOtherUid: clearSelection
          ? null
          : selectedOtherUid ?? this.selectedOtherUid,
      method: method ?? this.method,
      action: action ?? this.action,
      failure: clearFailure ? null : failure ?? this.failure,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    selectedOtherUid,
    method,
    action,
    failure,
    actionFailure,
  ];
}

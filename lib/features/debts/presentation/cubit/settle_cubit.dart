import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/settlement_method.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/balance_summary.dart';
import '../../domain/usecases/get_balance_summary.dart';
import '../../domain/usecases/settle_between.dart';

part 'settle_state.dart';

class SettleCubit extends Cubit<SettleState> {
  SettleCubit({
    required this._getBalanceSummary,
    required this._settleBetween,
    required this.householdId,
    required this.meUid,
    String? initialOtherUid,
    SettlementMethod defaultMethod = SettlementMethod.momo,
  }) : super(
         SettleState(
           selectedOtherUid: initialOtherUid,
           method: defaultMethod == SettlementMethod.credits
               ? SettlementMethod.momo
               : defaultMethod,
         ),
       );

  final GetBalanceSummary _getBalanceSummary;
  final SettleBetween _settleBetween;

  final String householdId;
  final String meUid;

  StreamSubscription<BalanceSummary>? _subscription;
  int _version = 0;
  bool _submitting = false;

  Future<void> load({bool force = false}) async {
    if (isClosed || _submitting) return;
    if (!force && _subscription != null) return;

    final version = ++_version;
    final previous = _subscription;
    _subscription = null;

    emit(
      SettleState(
        status: SettleStatus.loading,
        selectedOtherUid: state.selectedOtherUid,
        method: state.method,
      ),
    );

    await previous?.cancel();
    if (!_isCurrent(version)) return;

    if (householdId.isEmpty || meUid.isEmpty) {
      emit(
        state.copyWith(
          status: SettleStatus.failure,
          failure: const ValidationFailure(
            'Join a household to settle shared balances.',
          ),
        ),
      );
      return;
    }

    try {
      _subscription = _getBalanceSummary(householdId: householdId, meUid: meUid)
          .listen(
            (summary) {
              if (!_isCurrent(version)) return;

              emit(
                state.copyWith(
                  status: SettleStatus.loaded,
                  summary: summary,
                  clearFailure: true,
                ),
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!_isCurrent(version)) return;

              emit(
                state.copyWith(
                  status: SettleStatus.failure,
                  failure: _toFailure(error),
                ),
              );
            },
            onDone: () {
              if (_isCurrent(version)) {
                _subscription = null;
              }
            },
          );
    } catch (error) {
      if (_isCurrent(version)) {
        emit(
          state.copyWith(
            status: SettleStatus.failure,
            failure: _toFailure(error),
          ),
        );
      }
    }
  }

  Future<void> retry() => load(force: true);

  void selectMember(String uid) {
    if (isClosed || _submitting || state.status != SettleStatus.loaded) {
      return;
    }

    final balance = state.summary?.byMember[uid];
    if (uid == meUid || balance == null || balance == 0) return;

    emit(
      state.copyWith(
        selectedOtherUid: uid,
        action: SettlementAction.idle,
        clearActionFailure: true,
      ),
    );
  }

  void selectMethod(SettlementMethod method) {
    if (isClosed || _submitting || method == SettlementMethod.credits) {
      return;
    }

    emit(state.copyWith(method: method, clearActionFailure: true));
  }

  Future<void> confirm() async {
    if (isClosed || _submitting || !state.canConfirm) return;

    final otherUid = state.selectedOtherUid!;
    final method = state.method;
    final version = _version;

    _submitting = true;

    emit(
      state.copyWith(
        action: SettlementAction.submitting,
        clearActionFailure: true,
      ),
    );

    try {
      final result = await _settleBetween(
        householdId: householdId,
        meUid: meUid,
        otherUid: otherUid,
        method: method.name,
      );

      if (!_isCurrent(version)) return;

      final failure = result.failureOrNull;

      emit(
        state.copyWith(
          action: failure == null
              ? SettlementAction.success
              : SettlementAction.failure,
          actionFailure: failure,
          clearActionFailure: failure == null,
        ),
      );
    } catch (error) {
      if (_isCurrent(version)) {
        emit(
          state.copyWith(
            action: SettlementAction.failure,
            actionFailure: _toFailure(error),
          ),
        );
      }
    } finally {
      _submitting = false;
    }
  }

  bool _isCurrent(int version) => !isClosed && version == _version;

  Failure _toFailure(Object error) {
    if (error is Failure) return error;

    return const UnknownFailure(
      'Your settlement could not be completed. Please try again.',
    );
  }

  @override
  Future<void> close() async {
    ++_version;

    final subscription = _subscription;
    _subscription = null;

    await subscription?.cancel();
    await super.close();
  }
}

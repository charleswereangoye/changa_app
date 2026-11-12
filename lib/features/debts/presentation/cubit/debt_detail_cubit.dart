import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/error/failures.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/usecases/watch_expenses.dart';
import '../../domain/entities/debt.dart';
import '../../domain/logic/balance_calculator.dart';
import '../../domain/usecases/send_nudge.dart';
import '../../domain/usecases/watch_debts_between.dart';

part 'debt_detail_state.dart';

class DebtDetailCubit extends Cubit<DebtDetailState> {
  DebtDetailCubit({
    required this._watchDebtsBetween,
    required this._watchExpenses,
    required this._sendNudge,
    required this.householdId,
    required this.meUid,
    required this.otherUid,
  }) : super(DebtDetailState());

  final WatchDebtsBetween _watchDebtsBetween;
  final WatchExpenses _watchExpenses;
  final SendNudge _sendNudge;

  /// This Cubit belongs to one detail page and one pair of members.
  final String householdId;
  final String meUid;
  final String otherUid;

  StreamSubscription<DebtDetailState>? _subscription;
  int _version = 0;
  bool _nudgeInFlight = false;

  Future<void> load({bool force = false}) async {
    if (isClosed) return;
    if (!force && (_subscription != null || _nudgeInFlight)) return;

    final version = ++_version;
    final previous = _subscription;
    _subscription = null;

    emit(state.copyWith(status: DebtDetailStatus.loading, clearFailure: true));

    await previous?.cancel();
    if (!_isCurrent(version)) return;

    if (householdId.isEmpty ||
        meUid.isEmpty ||
        otherUid.isEmpty ||
        meUid == otherUid) {
      emit(
        DebtDetailState(
          status: DebtDetailStatus.failure,
          failure: const ValidationFailure(
            'Choose a housemate to view shared balances.',
          ),
        ),
      );
      return;
    }

    try {
      final combined =
          Rx.combineLatest2<List<Debt>, List<Expense>, DebtDetailState>(
            _watchDebtsBetween(householdId, meUid, otherUid),
            _watchExpenses(householdId),
            _buildLoadedState,
          );

      _subscription = combined.listen(
        (loaded) {
          if (!_isCurrent(version)) return;

          // Live updates must not reset an action still in progress.
          emit(
            loaded.copyWith(
              nudgeStatus: state.nudgeStatus,
              nudgeFailure: state.nudgeFailure,
            ),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!_isCurrent(version)) return;

          emit(
            state.copyWith(
              status: DebtDetailStatus.failure,
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
            status: DebtDetailStatus.failure,
            failure: _toFailure(error),
          ),
        );
      }
    }
  }

  DebtDetailState _buildLoadedState(List<Debt> debts, List<Expense> expenses) {
    final pending = debts.where((debt) {
      final betweenMembers =
          (debt.debtorUid == meUid && debt.creditorUid == otherUid) ||
          (debt.debtorUid == otherUid && debt.creditorUid == meUid);

      return debt.isPending && betweenMembers;
    }).toList();

    pending.sort((a, b) {
      final dateOrder = b.createdAt.compareTo(a.createdAt);
      return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
    });

    const calculator = BalanceCalculator();
    final summary = calculator.summarize(pendingDebts: pending, meUid: meUid);

    return DebtDetailState(
      status: DebtDetailStatus.loaded,
      debts: pending,
      expensesById: {for (final expense in expenses) expense.id: expense},
      netBalance: summary.byMember[otherUid] ?? 0,
    );
  }

  Future<void> retry() => load(force: true);

  Future<void> sendNudge() async {
    if (isClosed || _nudgeInFlight || !state.canNudge) return;

    _nudgeInFlight = true;

    emit(
      state.copyWith(nudgeStatus: NudgeStatus.sending, clearNudgeFailure: true),
    );

    try {
      final result = await _sendNudge(
        householdId: householdId,
        fromUid: meUid,
        toUid: otherUid,
      );

      // This Cubit belongs to one fixed household and member pair.
      // Restarting its data stream does not invalidate the nudge result.
      if (isClosed) return;

      final failure = result.failureOrNull;
      emit(
        state.copyWith(
          nudgeStatus: failure == null ? NudgeStatus.sent : NudgeStatus.failure,
          nudgeFailure: failure,
          clearNudgeFailure: failure == null,
        ),
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            nudgeStatus: NudgeStatus.failure,
            nudgeFailure: _toFailure(error),
          ),
        );
      }
    } finally {
      _nudgeInFlight = false;
    }
  }

  bool _isCurrent(int version) => !isClosed && version == _version;

  Failure _toFailure(Object error) {
    if (error is Failure) return error;

    return const UnknownFailure('Something went wrong. Please try again.');
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

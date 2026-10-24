// Gets the total pending debt owed by one household member.

import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/debt_status.dart';
import '../repositories/debt_repository.dart';

class GetOutstandingBalance {
  const GetOutstandingBalance(this._repository);

  final DebtRepository _repository;

  Future<Result<int>> call({
    required String householdId,
    required String uid,
  }) async {
    if (householdId.isEmpty || uid.isEmpty) {
      return Result<int>.failure(
        const ValidationFailure(
          'Choose a household member to view their balance.',
        ),
      );
    }

    try {
      // Read the first stream result and cancel the subscription.
      final debts = await _repository.watchPendingDebts(householdId).first;

      var total = 0;

      for (final debt in debts) {
        if (debt.status != DebtStatus.pending ||
            debt.fromUid != uid ||
            debt.fromUid == debt.toUid) {
          continue;
        }

        final amount = debt.amount;

        if (!amount.isFinite ||
            amount < 0 ||
            amount != amount.truncateToDouble()) {
          return Result<int>.failure(
            const ValidationFailure(
              'Some balance details need checking. Please try again later.',
            ),
          );
        }

        total += amount.toInt();
      }

      return Result<int>.success(total);
    } catch (error) {
      // Preserve the friendly errors supplied by the repository.
      if (error is Failure) {
        return Result<int>.failure(error);
      }

      return Result<int>.failure(const UnknownFailure());
    }
  }
}

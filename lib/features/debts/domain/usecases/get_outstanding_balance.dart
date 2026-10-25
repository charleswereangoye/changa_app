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
      final debts = await _repository.watchPendingDebts(householdId).first;

      var total = 0;

      for (final debt in debts) {
        if (debt.status != DebtStatus.pending ||
            debt.debtorUid != uid ||
            debt.debtorUid == debt.creditorUid) {
          continue;
        }

        total += debt.amount;
      }

      return Result<int>.success(total);
    } catch (error) {
      if (error is Failure) {
        return Result<int>.failure(error);
      }

      return Result<int>.failure(const UnknownFailure());
    }
  }
}

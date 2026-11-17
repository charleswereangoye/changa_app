import '../entities/balance_summary.dart';
import '../logic/balance_calculator.dart';
import '../repositories/debt_repository.dart';

class GetBalanceSummary {
  const GetBalanceSummary(this.repository);

  final DebtRepository repository;

  Stream<BalanceSummary> call({
    required String householdId,
    required String meUid,
  }) {
    const calculator = BalanceCalculator();

    return repository
        .watchPendingDebts(householdId)
        .map(
          (debts) => calculator.summarize(pendingDebts: debts, meUid: meUid),
        );
  }
}

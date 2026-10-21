// Owner: D - Person D (Debts, Settling, Nudges, Notifications, Release Build)
// Description: BalanceSummary entity (youAreOwed, youOwe, net, byMember)

// TODO(D): Implement BalanceSummary according to project specification

class BalanceSummary {
  final int youAreOwed;
  final int youOwe;
  final int net;
  final Map<String, int> byMember;

  BalanceSummary({
    required this.youAreOwed,
    required this.youOwe,
    required this.net,
    required Map<String, int> byMember,
  }) : byMember = Map<String, int>.unmodifiable(byMember);
}

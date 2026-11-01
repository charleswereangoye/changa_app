import 'package:equatable/equatable.dart';

class BalanceSummary extends Equatable {
  BalanceSummary({
    required this.youAreOwed,
    required this.youOwe,
    required this.net,
    required Map<String, int> byMember,
  }) : byMember = Map<String, int>.unmodifiable(byMember);

  final int youAreOwed;
  final int youOwe;
  final int net;

  /// Positive: this member owes me.
  /// Negative: I owe this member.
  final Map<String, int> byMember;

  @override
  List<Object?> get props => [youAreOwed, youOwe, net, byMember];
}

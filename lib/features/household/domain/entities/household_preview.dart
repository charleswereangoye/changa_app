import 'package:equatable/equatable.dart';

class HouseholdPreview extends Equatable {
  final String name;
  final int memberCount;

  const HouseholdPreview({
    required this.name,
    required this.memberCount,
  });

  @override
  List<Object?> get props => [name, memberCount];
}
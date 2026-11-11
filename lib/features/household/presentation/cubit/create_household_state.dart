// States for CreateHouseholdCubit

part of 'create_household_cubit.dart';

abstract class CreateHouseholdState extends Equatable {
  final String name;
  final HouseholdType type;
  final int expectedMembers;
  final String? errorMessage;

  const CreateHouseholdState({
    this.name = '',
    this.type = HouseholdType.apartment,
    this.expectedMembers = 4,
    this.errorMessage,
  });

  bool get isSubmitting => this is CreateHouseholdStateSubmitting;

  bool get isValid {
    final trimmed = name.trim();
    return trimmed.length >= 3 &&
        trimmed.length <= 40 &&
        expectedMembers >= 2 &&
        expectedMembers <= 10;
  }

  @override
  List<Object?> get props => [name, type, expectedMembers, errorMessage];
}

class CreateHouseholdStateInitial extends CreateHouseholdState {
  const CreateHouseholdStateInitial({
    super.name = '',
    super.type = HouseholdType.apartment,
    super.expectedMembers = 4,
    super.errorMessage,
  });
}

class CreateHouseholdStateSubmitting extends CreateHouseholdState {
  const CreateHouseholdStateSubmitting({
    required super.name,
    required super.type,
    required super.expectedMembers,
  });
}

class CreateHouseholdStateSuccess extends CreateHouseholdState {
  final Household household;

  const CreateHouseholdStateSuccess({
    required this.household,
    required super.name,
    required super.type,
    required super.expectedMembers,
  });

  @override
  List<Object?> get props => [household, name, type, expectedMembers];
}

class CreateHouseholdStateFailure extends CreateHouseholdState {
  final String message;

  const CreateHouseholdStateFailure({
    required this.message,
    super.name = '',
    super.type = HouseholdType.apartment,
    super.expectedMembers = 4,
  }) : super(errorMessage: message);

  @override
  List<Object?> get props => [message, name, type, expectedMembers];
}

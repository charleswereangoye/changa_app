// States for JoinHouseholdCubit

part of 'join_household_cubit.dart';

abstract class JoinHouseholdState extends Equatable {
  final String pin;
  final HouseholdPreview? preview;
  final String? errorMessage;

  const JoinHouseholdState({this.pin = '', this.preview, this.errorMessage});

  bool get isPreviewLoading => this is JoinHouseholdStatePreviewLoading;
  bool get isJoining => this is JoinHouseholdStateJoining;
  bool get hasError => this is JoinHouseholdStateError;
  bool get canJoin =>
      preview != null && !isPreviewLoading && !isJoining && pin.length == 6;

  @override
  List<Object?> get props => [pin, preview, errorMessage];
}

class JoinHouseholdStateInitial extends JoinHouseholdState {
  const JoinHouseholdStateInitial() : super();
}

class JoinHouseholdStatePreviewLoading extends JoinHouseholdState {
  const JoinHouseholdStatePreviewLoading({required super.pin});
}

class JoinHouseholdStatePreviewLoaded extends JoinHouseholdState {
  const JoinHouseholdStatePreviewLoaded({
    required super.pin,
    required HouseholdPreview super.preview,
  });
}

class JoinHouseholdStateJoining extends JoinHouseholdState {
  const JoinHouseholdStateJoining({required super.pin, super.preview});
}

class JoinHouseholdStateSuccess extends JoinHouseholdState {
  final Household household;

  const JoinHouseholdStateSuccess({
    required this.household,
    required super.pin,
    super.preview,
  });

  @override
  List<Object?> get props => [household, pin, preview];
}

class JoinHouseholdStateError extends JoinHouseholdState {
  final String message;

  const JoinHouseholdStateError({
    required this.message,
    super.pin = '',
    super.preview,
  }) : super(errorMessage: message);

  @override
  List<Object?> get props => [message, pin, preview];
}

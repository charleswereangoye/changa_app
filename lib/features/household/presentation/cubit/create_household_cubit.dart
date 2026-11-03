// Cubit managing Create Household form

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/usecases/create_household.dart';

part 'create_household_state.dart';

class CreateHouseholdCubit extends Cubit<CreateHouseholdState> {
  static const int minNameLength = 3;
  static const int maxNameLength = 40;
  static const int minRoommates = 2;
  static const int maxRoommates = 10;

  final CreateHousehold? _createHousehold;

  CreateHouseholdCubit({this._createHousehold})
    : super(const CreateHouseholdStateInitial());

  CreateHousehold? _resolveUseCase() {
    if (_createHousehold != null) return _createHousehold;
    final sl = GetIt.instance;
    if (sl.isRegistered<CreateHousehold>()) {
      return sl<CreateHousehold>();
    }
    return null;
  }

  static String? validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Please enter a household name.';
    }
    if (trimmed.length < minNameLength || trimmed.length > maxNameLength) {
      return 'Household name must be between $minNameLength and $maxNameLength characters.';
    }
    return null;
  }

  static String? validateExpectedMembers(int count) {
    if (count < minRoommates || count > maxRoommates) {
      return 'Number of roommates must be between $minRoommates and $maxRoommates.';
    }
    return null;
  }

  void nameChanged(String value) {
    emit(
      CreateHouseholdStateInitial(
        name: value,
        type: state.type,
        expectedMembers: state.expectedMembers,
      ),
    );
  }

  void typeChanged(HouseholdType type) {
    emit(
      CreateHouseholdStateInitial(
        name: state.name,
        type: type,
        expectedMembers: state.expectedMembers,
      ),
    );
  }

  void expectedMembersChanged(int count) {
    final clamped = count.clamp(minRoommates, maxRoommates);
    emit(
      CreateHouseholdStateInitial(
        name: state.name,
        type: state.type,
        expectedMembers: clamped,
      ),
    );
  }

  void incrementMembers() {
    if (state.expectedMembers < maxRoommates) {
      expectedMembersChanged(state.expectedMembers + 1);
    }
  }

  void decrementMembers() {
    if (state.expectedMembers > minRoommates) {
      expectedMembersChanged(state.expectedMembers - 1);
    }
  }

  Future<void> submit({
    String? name,
    HouseholdType? type,
    int? expectedMembers,
  }) async {
    final targetName = (name ?? state.name).trim();
    final targetType = type ?? state.type;
    final targetMembers = expectedMembers ?? state.expectedMembers;

    final nameError = validateName(targetName);
    if (nameError != null) {
      emit(
        CreateHouseholdStateFailure(
          message: nameError,
          name: name ?? state.name,
          type: targetType,
          expectedMembers: targetMembers,
        ),
      );
      return;
    }

    final membersError = validateExpectedMembers(targetMembers);
    if (membersError != null) {
      emit(
        CreateHouseholdStateFailure(
          message: membersError,
          name: targetName,
          type: targetType,
          expectedMembers: targetMembers,
        ),
      );
      return;
    }

    final useCase = _resolveUseCase();
    if (useCase == null) {
      emit(
        CreateHouseholdStateFailure(
          message: 'Household service is unavailable. Please try again.',
          name: targetName,
          type: targetType,
          expectedMembers: targetMembers,
        ),
      );
      return;
    }

    emit(
      CreateHouseholdStateSubmitting(
        name: targetName,
        type: targetType,
        expectedMembers: targetMembers,
      ),
    );

    final result = await useCase(
      name: targetName,
      type: targetType,
      expectedMembers: targetMembers,
    );

    if (result.isSuccess && result.dataOrNull != null) {
      emit(
        CreateHouseholdStateSuccess(
          household: result.dataOrNull!,
          name: targetName,
          type: targetType,
          expectedMembers: targetMembers,
        ),
      );
    } else {
      emit(
        CreateHouseholdStateFailure(
          message:
              result.failureOrNull?.message ??
              'Could not create household. Please try again.',
          name: targetName,
          type: targetType,
          expectedMembers: targetMembers,
        ),
      );
    }
  }
}

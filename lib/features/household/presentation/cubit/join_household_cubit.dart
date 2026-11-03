// Cubit managing Join Household PIN entry & preview

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/usecases/join_household.dart';
import 'package:changa_app/features/household/domain/usecases/preview_household_by_pin.dart';

part 'join_household_state.dart';

class JoinHouseholdCubit extends Cubit<JoinHouseholdState> {
  static final RegExp _pinRegex = RegExp(r'^\d{6}$');

  final PreviewHouseholdByPin? _previewHouseholdByPin;
  final JoinHousehold? _joinHousehold;

  JoinHouseholdCubit({this._previewHouseholdByPin, this._joinHousehold})
    : super(const JoinHouseholdStateInitial());

  PreviewHouseholdByPin? _resolvePreviewUseCase() {
    if (_previewHouseholdByPin != null) return _previewHouseholdByPin;
    final sl = GetIt.instance;
    if (sl.isRegistered<PreviewHouseholdByPin>()) {
      return sl<PreviewHouseholdByPin>();
    }
    return null;
  }

  JoinHousehold? _resolveJoinUseCase() {
    if (_joinHousehold != null) return _joinHousehold;
    final sl = GetIt.instance;
    if (sl.isRegistered<JoinHousehold>()) {
      return sl<JoinHousehold>();
    }
    return null;
  }

  /// Triggered when 6 digits are entered in `PinInput`.
  Future<void> onPinCompleted(String rawPin) async {
    final cleanPin = rawPin.trim();
    if (!_pinRegex.hasMatch(cleanPin)) {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          message: 'Please enter a valid 6-digit household PIN.',
        ),
      );
      return;
    }

    final previewUseCase = _resolvePreviewUseCase();
    if (previewUseCase == null) {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          message: 'Household preview service is unavailable.',
        ),
      );
      return;
    }

    emit(JoinHouseholdStatePreviewLoading(pin: cleanPin));

    final result = await previewUseCase(cleanPin);
    if (result.isSuccess && result.dataOrNull != null) {
      emit(
        JoinHouseholdStatePreviewLoaded(
          pin: cleanPin,
          preview: result.dataOrNull!,
        ),
      );
    } else {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          message:
              result.failureOrNull?.message ??
              'No household found with that PIN. Please check the digits.',
        ),
      );
    }
  }

  /// Joins the household for the currently previewed (or provided) 6-digit PIN.
  Future<void> joinHousehold([String? pinOverride]) async {
    final cleanPin = (pinOverride ?? state.pin).trim();
    if (!_pinRegex.hasMatch(cleanPin)) {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          preview: state.preview,
          message: 'Please enter a valid 6-digit household PIN.',
        ),
      );
      return;
    }

    final joinUseCase = _resolveJoinUseCase();
    if (joinUseCase == null) {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          preview: state.preview,
          message: 'Household join service is unavailable.',
        ),
      );
      return;
    }

    final currentPreview = state.preview;
    emit(JoinHouseholdStateJoining(pin: cleanPin, preview: currentPreview));

    final result = await joinUseCase(cleanPin);
    if (result.isSuccess && result.dataOrNull != null) {
      emit(
        JoinHouseholdStateSuccess(
          household: result.dataOrNull!,
          pin: cleanPin,
          preview: currentPreview,
        ),
      );
    } else {
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          preview: currentPreview,
          message:
              result.failureOrNull?.message ??
              'Could not join household. Please try again.',
        ),
      );
    }
  }

  void reset() {
    emit(const JoinHouseholdStateInitial());
  }
}

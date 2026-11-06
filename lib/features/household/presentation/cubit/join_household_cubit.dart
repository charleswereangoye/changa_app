// Cubit managing Join Household PIN entry & preview

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/usecases/join_household.dart';
import 'package:changa_app/features/household/domain/usecases/preview_household_by_pin.dart';

part 'join_household_state.dart';

class JoinHouseholdCubit extends Cubit<JoinHouseholdState> {
  static final RegExp _pinRegex = RegExp(r'^\d{6}$');

  final PreviewHouseholdByPin? previewHouseholdByPin;
  final JoinHousehold? joinHouseholdUseCase;

  int _activeRequestId = 0;

  JoinHouseholdCubit({this.previewHouseholdByPin, JoinHousehold? joinHousehold})
    : joinHouseholdUseCase = joinHousehold,
      super(const JoinHouseholdStateInitial());

  /// Invalidates any active preview or in-flight lookup whenever the PIN input
  /// changes, while ignoring edits if a join request is already in-flight.
  void onPinChanged(String rawPin) {
    if (state is JoinHouseholdStateJoining || isClosed) return;

    final cleanPin = rawPin.trim();
    if (cleanPin == state.pin && state is JoinHouseholdStateInitial) {
      return;
    }

    if (cleanPin.length == 6 &&
        cleanPin == state.pin &&
        (state is JoinHouseholdStatePreviewLoading ||
            state is JoinHouseholdStatePreviewLoaded)) {
      return;
    }

    _activeRequestId++;
    emit(JoinHouseholdStateInitial(pin: cleanPin));
  }

  /// Triggered when 6 digits are entered in `PinInput`.
  Future<void> onPinCompleted(String rawPin) async {
    if (state is JoinHouseholdStateJoining || isClosed) return;

    final cleanPin = rawPin.trim();
    if (state is JoinHouseholdStatePreviewLoading && state.pin == cleanPin) {
      return;
    }

    if (!_pinRegex.hasMatch(cleanPin)) {
      _activeRequestId++;
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          message: 'Please enter a valid 6-digit household PIN.',
        ),
      );
      return;
    }

    final previewUseCase = previewHouseholdByPin;
    if (previewUseCase == null) {
      _activeRequestId++;
      emit(
        JoinHouseholdStateError(
          pin: cleanPin,
          message: 'Household preview service is unavailable.',
        ),
      );
      return;
    }

    final requestId = ++_activeRequestId;
    emit(JoinHouseholdStatePreviewLoading(pin: cleanPin));

    final result = await previewUseCase(cleanPin);

    if (isClosed || requestId != _activeRequestId || state.pin != cleanPin) {
      return;
    }

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

  /// Joins the household for the currently previewed 6-digit PIN.
  Future<void> joinHousehold([String? pinOverride]) async {
    if (state is JoinHouseholdStateJoining ||
        state is JoinHouseholdStatePreviewLoading ||
        isClosed) {
      return;
    }

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

    final joinUseCase = joinHouseholdUseCase;
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
    final requestId = ++_activeRequestId;
    emit(JoinHouseholdStateJoining(pin: cleanPin, preview: currentPreview));

    final result = await joinUseCase(cleanPin);

    if (isClosed || requestId != _activeRequestId) return;

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
    if (state is JoinHouseholdStateJoining || isClosed) return;
    _activeRequestId++;
    emit(const JoinHouseholdStateInitial());
  }
}

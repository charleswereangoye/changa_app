import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/pref_keys.dart';
import '../../../../core/services/preferences_service.dart';
import 'onboarding_state.dart';

/// Cubit managing the current slide of the onboarding carousel.
class OnboardingCubit extends Cubit<OnboardingState> {
  final PreferencesService? preferencesService;

  OnboardingCubit({this.preferencesService}) : super(const OnboardingState());

  void setPage(int index) {
    emit(state.copyWith(currentPage: index));
  }

  Future<void> completeOnboarding() async {
    if (preferencesService != null) {
      await preferencesService!.setBool(PrefKeys.onboardingSeen, true);
    }
  }
}

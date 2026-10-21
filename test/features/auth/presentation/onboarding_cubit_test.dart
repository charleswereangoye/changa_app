import 'package:flutter_test/flutter_test.dart';
import 'package:changa_app/features/auth/presentation/cubit/onboarding_cubit.dart';

void main() {
  group('OnboardingCubit', () {
    late OnboardingCubit cubit;

    setUp(() {
      cubit = OnboardingCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state has currentPage = 0 and isLastPage = false', () {
      expect(cubit.state.currentPage, 0);
      expect(cubit.state.isLastPage, isFalse);
    });

    test('setPage updates currentPage correctly', () {
      cubit.setPage(1);
      expect(cubit.state.currentPage, 1);
      expect(cubit.state.isLastPage, isFalse);

      cubit.setPage(2);
      expect(cubit.state.currentPage, 2);
      expect(cubit.state.isLastPage, isTrue);
    });
  });
}

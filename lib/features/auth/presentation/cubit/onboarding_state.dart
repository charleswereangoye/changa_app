import 'package:equatable/equatable.dart';

/// State representing the current onboarding slide index.
class OnboardingState extends Equatable {
  final int currentPage;

  const OnboardingState({this.currentPage = 0});

  bool get isLastPage => currentPage == 2;

  OnboardingState copyWith({int? currentPage}) {
    return OnboardingState(currentPage: currentPage ?? this.currentPage);
  }

  @override
  List<Object?> get props => [currentPage];
}

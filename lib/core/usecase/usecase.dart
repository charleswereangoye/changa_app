// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Generic base UseCase contracts (Future and Stream)

import '../error/result.dart';

/// Generic base contract for use cases returning a [Future] of [Result].
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Generic base contract for use cases returning a [Stream].
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Helper class when a usecase requires no parameters.
class NoParams {
  const NoParams();
}

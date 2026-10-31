import 'package:firebase_auth/firebase_auth.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/household/data/datasources/household_remote_datasource.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/household_preview.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/repositories/household_repository.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  final HouseholdRemoteDataSource _remoteDataSource;
  final FirebaseAuth? _firebaseAuth;
  final String? Function()? _currentUidResolver;

  HouseholdRepositoryImpl({
    required HouseholdRemoteDataSource remoteDataSource,
    FirebaseAuth? firebaseAuth,
    String? Function()? currentUidResolver,
  }) : _remoteDataSource = remoteDataSource,
       _firebaseAuth = firebaseAuth,
       _currentUidResolver = currentUidResolver;

  String _requireCurrentUid() {
    if (_currentUidResolver != null) {
      final uid = _currentUidResolver();
      if (uid != null && uid.isNotEmpty) return uid;
    }
    try {
      final uid = (_firebaseAuth ?? FirebaseAuth.instance).currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {
      // Ignored when FirebaseAuth is not initialized in unit tests
    }
    throw const AuthFailure('You must be signed in to perform this action.');
  }

  String? _tryGetCurrentUid() {
    try {
      return _requireCurrentUid();
    } catch (_) {
      return null;
    }
  }

  Failure _mapException(Object error) {
    if (error is Failure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const PermissionFailure();
        case 'not-found':
          return const NotFoundFailure();
        case 'unavailable':
        case 'network-request-failed':
          return const NetworkFailure();
        default:
          return UnknownFailure(
            error.message ?? 'A database error occurred. Please try again.',
          );
      }
    }
    return const UnknownFailure();
  }

  @override
  Stream<Household?> watchHousehold(String householdId) {
    return _remoteDataSource
        .watchHousehold(householdId)
        .map((model) => model?.toEntity());
  }

  @override
  Stream<List<Member>> watchMembers(String householdId) {
    return _remoteDataSource.watchMembers(householdId).asyncMap((models) async {
      final currentUid = _tryGetCurrentUid();
      if (currentUid != null &&
          models.isNotEmpty &&
          !models.any((m) => m.uid == currentUid)) {
        await _remoteDataSource.checkAndClearStaleHousehold(
          householdId: householdId,
          uid: currentUid,
        );
      }
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Result<Household>> createHousehold({
    required String name,
    required HouseholdType type,
    required int expectedMembers,
  }) async {
    try {
      final uid = _requireCurrentUid();
      final model = await _remoteDataSource.createHousehold(
        uid: uid,
        name: name,
        type: type,
        expectedMembers: expectedMembers,
      );
      return Result.success(model.toEntity());
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<HouseholdPreview>> previewHouseholdByPin(String pin) async {
    try {
      final preview = await _remoteDataSource.previewHouseholdByPin(pin);
      return Result.success(preview);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Household>> joinHousehold(String pin) async {
    try {
      final uid = _requireCurrentUid();
      final model = await _remoteDataSource.joinHousehold(uid: uid, pin: pin);
      return Result.success(model.toEntity());
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<String>> regeneratePin(String householdId) async {
    try {
      final newPin = await _remoteDataSource.regeneratePin(householdId);
      return Result.success(newPin);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> removeMember({
    required String householdId,
    required String uid,
  }) async {
    try {
      final callerUid = _requireCurrentUid();
      await _remoteDataSource.removeMember(
        householdId: householdId,
        callerUid: callerUid,
        targetUid: uid,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> transferAdmin({
    required String householdId,
    required String newAdminUid,
  }) async {
    try {
      final callerUid = _requireCurrentUid();
      await _remoteDataSource.transferAdmin(
        householdId: householdId,
        callerUid: callerUid,
        newAdminUid: newAdminUid,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<void>> leaveHousehold(String householdId) async {
    try {
      final uid = _requireCurrentUid();
      await _remoteDataSource.leaveHousehold(
        householdId: householdId,
        uid: uid,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }
}

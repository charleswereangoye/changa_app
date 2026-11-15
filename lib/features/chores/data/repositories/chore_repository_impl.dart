import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/data/chore_exceptions.dart';
import 'package:changa_app/features/chores/data/datasources/chore_remote_datasource.dart';
import 'package:changa_app/features/chores/data/datasources/swap_remote_datasource.dart';
import 'package:changa_app/features/chores/data/models/chore_model.dart';
import 'package:changa_app/features/chores/domain/entities/chore.dart';
import 'package:changa_app/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa_app/features/chores/domain/entities/swap_request.dart';
import 'package:changa_app/features/chores/domain/repositories/chore_repository.dart';

class ChoreRepositoryImpl implements ChoreRepository {
  ChoreRepositoryImpl(this._chores, this._swaps);

  final ChoreRemoteDataSource _chores;
  final SwapRemoteDataSource _swaps;

  @override
  Stream<List<Chore>> watchChoresForDay(String householdId, DateTime day) =>
      _chores.watchForDay(householdId, day).map(_toEntities);

  @override
  Stream<List<Chore>> watchAllChores(String householdId) =>
      _chores.watchAll(householdId).map(_toEntities);

  @override
  Future<Result<void>> createChore(NewChoreInput input) =>
      _guard(() => _chores.create(input));

  @override
  Future<Result<void>> updateChore(String householdId, Chore chore) =>
      _guard(() => _chores.update(householdId, ChoreModel.fromEntity(chore)));

  @override
  Future<Result<void>> deleteChore(
    String householdId,
    String choreId, {
    bool wholeSeries = false,
  }) => _guard(
    () => _chores.delete(householdId, choreId, wholeSeries: wholeSeries),
  );

  @override
  Future<Result<void>> completeChore(String householdId, String choreId) =>
      _guard(() => _chores.complete(householdId, choreId));

  @override
  Future<Result<void>> reassignChores({
    required String householdId,
    required String fromUid,
    required String toUid,
  }) => _guard(() => _chores.reassign(householdId, fromUid, toUid));

  @override
  Future<Result<void>> requestSwap({
    required String householdId,
    required String choreId,
    required String toUid,
    String? note,
  }) => _guard(
    () => _swaps.request(
      householdId: householdId,
      choreId: choreId,
      toUid: toUid,
      note: note,
    ),
  );

  @override
  Future<Result<void>> respondToSwap({
    required String householdId,
    required String requestId,
    required bool accept,
  }) => _guard(
    () => _swaps.respond(
      householdId: householdId,
      requestId: requestId,
      accept: accept,
    ),
  );

  @override
  Future<Result<void>> cancelSwap(String householdId, String requestId) =>
      _guard(() => _swaps.cancel(householdId, requestId));

  @override
  Stream<List<SwapRequest>> watchSwapRequests(String householdId, String uid) =>
      _swaps
          .watchIncoming(householdId, uid)
          .map((models) => models.map((m) => m.toEntity()).toList());

  List<Chore> _toEntities(List<ChoreModel> models) =>
      models.map((m) => m.toEntity()).toList();

  /// The only place that builds a Result or a Failure in this feature.
  Future<Result<void>> _guard(Future<void> Function() body) async {
    try {
      await body();
      return Result<void>.success(null);
    } on ChoreRuleException catch (e) {
      return Result<void>.failure(switch (e.kind) {
        ChoreRuleKind.validation => ValidationFailure(e.message),
        ChoreRuleKind.permission => PermissionFailure(e.message),
        ChoreRuleKind.notFound => NotFoundFailure(e.message),
      });
    } on FirebaseException catch (e) {
      return Result<void>.failure(_fromFirebase(e));
    } catch (_) {
      return Result<void>.failure(const UnknownFailure());
    }
  }

  Failure _fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const PermissionFailure('You don’t have permission to do that.');
      case 'unavailable':
      case 'network-request-failed':
      case 'deadline-exceeded':
        return const NetworkFailure();
      case 'not-found':
        return const NotFoundFailure('We couldn’t find that item.');
      default:
        return const UnknownFailure();
    }
  }
}

import 'package:changa/core/error/result.dart';
import 'package:changa/features/chores/domain/entities/chore.dart';
import 'package:changa/features/chores/domain/entities/new_chore_input.dart';
import 'package:changa/features/chores/domain/entities/swap_request.dart';

abstract class ChoreRepository {
  Stream<List<Chore>> watchChoresForDay(String householdId, DateTime day);

  /// Everything due from 14 days ago onwards. Feeds the Harmony Score.
  Stream<List<Chore>> watchAllChores(String householdId);

  /// A rotating chore creates all of its weekly instances at once.
  Future<Result<void>> createChore(NewChoreInput input);

  Future<Result<void>> updateChore(String householdId, Chore chore);

  Future<Result<void>> deleteChore(
    String householdId,
    String choreId, {
    bool wholeSeries = false,
  });

  /// Only the assignee can do this, and it cannot be undone.
  Future<Result<void>> completeChore(String householdId, String choreId);

  /// Hands a removed member's pending chores to someone else.
  Future<Result<void>> reassignChores({
    required String householdId,
    required String fromUid,
    required String toUid,
  });

  Future<Result<void>> requestSwap({
    required String householdId,
    required String choreId,
    required String toUid,
    String? note,
  });

  Future<Result<void>> respondToSwap({
    required String householdId,
    required String requestId,
    required bool accept,
  });

  Future<Result<void>> cancelSwap(String householdId, String requestId);

  /// Open requests addressed to [uid].
  Stream<List<SwapRequest>> watchSwapRequests(String householdId, String uid);
}

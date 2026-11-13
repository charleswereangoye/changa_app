//  Cubit managing member administration & PIN changes

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:changa_app/core/error/failures.dart';
import 'package:changa_app/core/error/result.dart';
import 'package:changa_app/features/chores/domain/usecases/reassign_chores.dart';
import 'package:changa_app/features/debts/domain/usecases/get_outstanding_balance.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/leave_household.dart';
import 'package:changa_app/features/household/domain/usecases/regenerate_pin.dart';
import 'package:changa_app/features/household/domain/usecases/remove_member.dart';
import 'package:changa_app/features/household/domain/usecases/transfer_admin.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';

part 'manage_household_state.dart';

class ManageHouseholdCubit extends Cubit<ManageHouseholdState> {
  final WatchHousehold? watchHousehold;
  final WatchMembers? watchMembers;
  final GetUsersByIds? getUsersByIds;
  final RegeneratePin? regeneratePinUseCase;
  final RemoveMember? removeMemberUseCase;
  final TransferAdmin? transferAdminUseCase;
  final LeaveHousehold? leaveHouseholdUseCase;
  final GetOutstandingBalance? getOutstandingBalance;
  final ReassignChores? reassignChores;
  final HouseholdCubit? householdCubit;

  StreamSubscription<Household?>? _householdSubscription;
  StreamSubscription<List<Member>>? _membersSubscription;
  StreamSubscription<HouseholdState>? _globalCubitSubscription;

  Household? _household;
  List<Member> _members = const [];
  Map<String, String> _memberNames = const {};
  Map<String, int> _harmonyScores = const {};
  String? _householdId;
  String? _currentUid;
  int _session = 0;

  ManageHouseholdCubit({
    this.watchHousehold,
    this.watchMembers,
    this.getUsersByIds,
    RegeneratePin? regeneratePin,
    RemoveMember? removeMember,
    TransferAdmin? transferAdmin,
    LeaveHousehold? leaveHousehold,
    this.getOutstandingBalance,
    this.reassignChores,
    this.householdCubit,
    String? currentUid,
    Map<String, int> initialHarmonyScores = const {},
  }) : regeneratePinUseCase = regeneratePin,
       removeMemberUseCase = removeMember,
       transferAdminUseCase = transferAdmin,
       leaveHouseholdUseCase = leaveHousehold,
       _currentUid = currentUid?.trim(),
       _harmonyScores = Map<String, int>.unmodifiable(initialHarmonyScores),
       super(const ManageHouseholdStateInitial()) {
    _seedFromGlobalCubit();
  }

  void _seedFromGlobalCubit() {
    final global = householdCubit;
    if (global == null) return;

    final globalState = global.state;
    if (globalState is HouseholdStateLoaded) {
      _household = globalState.household;
      _householdId = globalState.household.id;
      _members = _sortMembers(
        globalState.members,
        globalState.household.adminUid,
      );
      _memberNames = Map<String, String>.of(globalState.memberNames);
      _currentUid ??=
          globalState.currentMember?.uid ?? globalState.household.adminUid;

      emit(
        ManageHouseholdStateLoaded(
          household: _household!,
          members: List<Member>.unmodifiable(_members),
          memberNames: Map<String, String>.unmodifiable(_memberNames),
          harmonyScores: Map<String, int>.unmodifiable(_harmonyScores),
          currentUid: _currentUid,
        ),
      );
    }

    _globalCubitSubscription = global.stream.listen((nextState) {
      if (isClosed) return;
      if (nextState is HouseholdStateLoaded &&
          (_householdId == null || _householdId == nextState.household.id)) {
        _household = nextState.household;
        _householdId = nextState.household.id;
        _members = _sortMembers(
          nextState.members,
          nextState.household.adminUid,
        );
        if (nextState.memberNames.isNotEmpty) {
          _memberNames = Map<String, String>.of(nextState.memberNames);
        }
        _currentUid ??=
            nextState.currentMember?.uid ?? nextState.household.adminUid;
        _emitLoadedState();
      }
    });
  }

  /// Seeds state directly (useful for widget tests and route initialization).
  void seedState({
    required Household household,
    required List<Member> members,
    Map<String, String> memberNames = const {},
    Map<String, int> harmonyScores = const {},
    String? currentUid,
  }) {
    if (isClosed) return;
    _household = household;
    _householdId = household.id;
    _members = _sortMembers(members, household.adminUid);
    _memberNames = Map<String, String>.of(memberNames);
    _harmonyScores = Map<String, int>.of(harmonyScores);
    _currentUid = currentUid ?? _currentUid ?? household.adminUid;

    emit(
      ManageHouseholdStateLoaded(
        household: household,
        members: List<Member>.unmodifiable(_members),
        memberNames: Map<String, String>.unmodifiable(_memberNames),
        harmonyScores: Map<String, int>.unmodifiable(_harmonyScores),
        currentUid: _currentUid,
      ),
    );
  }

  /// Subscribes to live household and member streams for [householdId].
  Future<void> load({
    String? householdId,
    String? currentUid,
    Map<String, String>? initialMemberNames,
    Map<String, int>? harmonyScores,
  }) async {
    if (isClosed) return;

    final resolvedHouseholdId =
        (householdId ??
                _householdId ??
                householdCubit?.state.household?.id ??
                '')
            .trim();
    if (currentUid != null && currentUid.trim().isNotEmpty) {
      _currentUid = currentUid.trim();
    }
    if (initialMemberNames != null && initialMemberNames.isNotEmpty) {
      _memberNames = {..._memberNames, ...initialMemberNames};
    }
    if (harmonyScores != null && harmonyScores.isNotEmpty) {
      _harmonyScores = {..._harmonyScores, ...harmonyScores};
    }

    if (resolvedHouseholdId.isEmpty) {
      emit(const ManageHouseholdStateError('No active household found.'));
      return;
    }

    final version = ++_session;
    final previousHouseholdSub = _householdSubscription;
    final previousMembersSub = _membersSubscription;
    _householdSubscription = null;
    _membersSubscription = null;
    _householdId = resolvedHouseholdId;

    if (state is! ManageHouseholdStateLoaded ||
        _household?.id != resolvedHouseholdId) {
      emit(const ManageHouseholdStateLoading());
    }

    await previousHouseholdSub?.cancel();
    await previousMembersSub?.cancel();
    if (isClosed || version != _session) return;

    final hWatcher = watchHousehold;
    final mWatcher = watchMembers;

    if (hWatcher == null && mWatcher == null) {
      if (_household != null) {
        _emitLoadedState();
      } else {
        emit(
          const ManageHouseholdStateError('Household streams are unavailable.'),
        );
      }
      return;
    }

    if (hWatcher != null) {
      _householdSubscription = hWatcher(resolvedHouseholdId).listen(
        (household) {
          if (isClosed || version != _session) return;
          if (household == null) {
            emit(
              const ManageHouseholdStateError('Household no longer exists.'),
            );
            return;
          }
          _household = household;
          _currentUid ??= household.adminUid;
          _members = _sortMembers(_members, household.adminUid);
          _emitLoadedState();
        },
        onError: (Object error) {
          if (isClosed || version != _session) return;
          emit(ManageHouseholdStateError(_mapErrorMessage(error)));
        },
      );
    }

    if (mWatcher != null) {
      _membersSubscription = mWatcher(resolvedHouseholdId).listen(
        (members) async {
          if (isClosed || version != _session) return;
          _members = _sortMembers(members, _household?.adminUid);
          await _resolveMemberNames(
            members.map((m) => m.uid).toList(),
            version,
          );
          if (isClosed || version != _session) return;
          _emitLoadedState();
        },
        onError: (Object error) {
          if (isClosed || version != _session) return;
          emit(ManageHouseholdStateError(_mapErrorMessage(error)));
        },
      );
    }
  }

  Future<void> _resolveMemberNames(List<String> uids, int version) async {
    final cleanUids = uids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (cleanUids.isEmpty) return;

    final fetcher = getUsersByIds;
    if (fetcher == null) return;

    final result = await fetcher(cleanUids);
    if (isClosed || version != _session) return;

    if (result.isSuccess && result.dataOrNull != null) {
      final updated = Map<String, String>.of(_memberNames);
      for (final user in result.dataOrNull!) {
        final trimmed = user.fullName.trim();
        updated[user.uid] = trimmed.isNotEmpty ? trimmed : 'Former member';
      }
      _memberNames = updated;
    }
  }

  /// Queries a member's outstanding debt balance (D4) before showing the
  /// Remove confirmation dialog.
  Future<int> fetchOutstandingBalance(String uid) async {
    final cleanUid = uid.trim();
    final targetHouseholdId = (_household?.id ?? _householdId ?? '').trim();
    final balanceUseCase = getOutstandingBalance;

    if (cleanUid.isEmpty ||
        targetHouseholdId.isEmpty ||
        balanceUseCase == null) {
      return 0;
    }

    final result = await balanceUseCase(
      householdId: targetHouseholdId,
      uid: cleanUid,
    );
    return result.dataOrNull ?? 0;
  }

  /// Regenerates the 6-digit household PIN (admin only).
  Future<Result<String>> regeneratePin() async {
    if (isClosed || state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('An action is already in progress.'),
      );
    }

    final activeHousehold = _household;
    final targetHouseholdId = (activeHousehold?.id ?? _householdId ?? '')
        .trim();
    final useCase = regeneratePinUseCase;

    if (targetHouseholdId.isEmpty || useCase == null) {
      const failure = UnknownFailure(
        'PIN regeneration service is unavailable.',
      );
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    _setSubmitting(true);

    final result = await useCase(targetHouseholdId);
    if (isClosed) return result;

    if (result.isSuccess && result.dataOrNull != null) {
      final newPin = result.dataOrNull!;
      if (activeHousehold != null) {
        _household = Household(
          id: activeHousehold.id,
          name: activeHousehold.name,
          type: activeHousehold.type,
          expectedMembers: activeHousehold.expectedMembers,
          pin: newPin,
          adminUid: activeHousehold.adminUid,
          createdAt: activeHousehold.createdAt,
        );
        householdCubit?.setHousehold(_household!, currentUid: _currentUid);
      }
      _emitLoadedState(
        isSubmitting: false,
        lastAction: ManageHouseholdAction.pinRegenerated,
        actionMessage: 'Household PIN regenerated.',
      );
      return result;
    } else {
      final message =
          result.failureOrNull?.message ??
          'Could not regenerate PIN. Please try again.';
      _emitActionFailure(message);
      return Result.failure(result.failureOrNull ?? UnknownFailure(message));
    }
  }

  /// Transfers the household admin role to [newAdminUid].
  Future<Result<void>> transferAdmin(String newAdminUid) async {
    if (isClosed || state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('An action is already in progress.'),
      );
    }

    final cleanTargetUid = newAdminUid.trim();
    final activeHousehold = _household;
    final targetHouseholdId = (activeHousehold?.id ?? _householdId ?? '')
        .trim();
    final useCase = transferAdminUseCase;

    if (cleanTargetUid.isEmpty) {
      const failure = ValidationFailure('Please select a member.');
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    if (targetHouseholdId.isEmpty || useCase == null) {
      const failure = UnknownFailure('Admin transfer service is unavailable.');
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    _setSubmitting(true);

    final result = await useCase(
      householdId: targetHouseholdId,
      newAdminUid: cleanTargetUid,
    );
    if (isClosed) return result;

    if (result.isSuccess) {
      if (activeHousehold != null) {
        _household = Household(
          id: activeHousehold.id,
          name: activeHousehold.name,
          type: activeHousehold.type,
          expectedMembers: activeHousehold.expectedMembers,
          pin: activeHousehold.pin,
          adminUid: cleanTargetUid,
          createdAt: activeHousehold.createdAt,
        );
      }
      _members = _sortMembers(
        _members.map((m) {
          if (m.uid == cleanTargetUid) {
            return Member(
              uid: m.uid,
              role: MemberRole.admin,
              credits: m.credits,
              joinedAt: m.joinedAt,
            );
          }
          if (m.role == MemberRole.admin) {
            return Member(
              uid: m.uid,
              role: MemberRole.member,
              credits: m.credits,
              joinedAt: m.joinedAt,
            );
          }
          return m;
        }).toList(),
        cleanTargetUid,
      );

      final targetName = state.displayNameFor(cleanTargetUid);
      _emitLoadedState(
        isSubmitting: false,
        lastAction: ManageHouseholdAction.adminTransferred,
        actionMessage: 'Admin role transferred to $targetName.',
      );
      return Result.success(null);
    } else {
      final message =
          result.failureOrNull?.message ??
          'Could not transfer admin role. Please try again.';
      _emitActionFailure(message);
      return result;
    }
  }

  /// Reassigns pending chores from [targetUid] to the admin (E8) and removes
  /// [targetUid] from the household.
  Future<Result<void>> removeMember(String targetUid) async {
    if (isClosed || state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('An action is already in progress.'),
      );
    }

    final cleanTargetUid = targetUid.trim();
    final activeHousehold = _household;
    final targetHouseholdId = (activeHousehold?.id ?? _householdId ?? '')
        .trim();
    final adminUid = (activeHousehold?.adminUid ?? _currentUid ?? '').trim();
    final removeUseCase = removeMemberUseCase;

    if (cleanTargetUid.isEmpty) {
      const failure = ValidationFailure('Please select a member to remove.');
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    if (cleanTargetUid == adminUid) {
      const failure = ValidationFailure(
        'The admin cannot remove themselves. Transfer admin rights first.',
      );
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    if (targetHouseholdId.isEmpty || removeUseCase == null) {
      const failure = UnknownFailure('Member removal service is unavailable.');
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    _setSubmitting(true);

    final targetName = state.displayNameFor(cleanTargetUid);

    // E8: Reassign pending chores from the removed member to the admin.
    final choreReassigner = reassignChores;
    if (choreReassigner != null && adminUid.isNotEmpty) {
      final reassignResult = await choreReassigner(
        householdId: targetHouseholdId,
        fromUid: cleanTargetUid,
        toUid: adminUid,
      );
      if (isClosed) return reassignResult;
      if (reassignResult.isFailure) {
        final message =
            reassignResult.failureOrNull?.message ??
            'Could not reassign pending chores. Please try again.';
        _emitActionFailure(message);
        return reassignResult;
      }
    }

    final removeResult = await removeUseCase(
      householdId: targetHouseholdId,
      uid: cleanTargetUid,
    );
    if (isClosed) return removeResult;

    if (removeResult.isSuccess) {
      _members = _members.where((m) => m.uid != cleanTargetUid).toList();
      _emitLoadedState(
        isSubmitting: false,
        lastAction: ManageHouseholdAction.memberRemoved,
        actionMessage: '$targetName was removed from the household.',
      );
      return Result.success(null);
    } else {
      final message =
          removeResult.failureOrNull?.message ??
          'Could not remove member. Please try again.';
      _emitActionFailure(message);
      return removeResult;
    }
  }

  /// Leaves the current household (for non-admin members).
  Future<Result<void>> leaveHousehold() async {
    if (isClosed || state.isSubmitting) {
      return Result.failure(
        const ValidationFailure('An action is already in progress.'),
      );
    }

    final targetHouseholdId = (_household?.id ?? _householdId ?? '').trim();
    final useCase = leaveHouseholdUseCase;

    if (targetHouseholdId.isEmpty || useCase == null) {
      const failure = UnknownFailure('Leave household service is unavailable.');
      _emitActionFailure(failure.message);
      return Result.failure(failure);
    }

    _setSubmitting(true);

    final result = await useCase(targetHouseholdId);
    if (isClosed) return result;

    if (result.isSuccess) {
      householdCubit?.clearHousehold();
      _emitLoadedState(
        isSubmitting: false,
        lastAction: ManageHouseholdAction.leftHousehold,
        actionMessage: 'You have left the household.',
      );
      return Result.success(null);
    } else {
      final message =
          result.failureOrNull?.message ??
          'Could not leave household. Please try again.';
      _emitActionFailure(message);
      return result;
    }
  }

  void clearFeedback() {
    if (isClosed) return;
    final current = state;
    if (current is ManageHouseholdStateLoaded) {
      emit(
        current.copyWith(
          lastAction: ManageHouseholdAction.none,
          clearActionMessage: true,
          clearErrorMessage: true,
        ),
      );
    }
  }

  List<Member> _sortMembers(List<Member> list, String? adminUid) {
    final copy = List<Member>.of(list);
    copy.sort((a, b) {
      final aIsAdmin = a.role == MemberRole.admin || a.uid == adminUid;
      final bIsAdmin = b.role == MemberRole.admin || b.uid == adminUid;
      if (aIsAdmin != bIsAdmin) {
        return aIsAdmin ? -1 : 1;
      }
      final joinedCmp = a.joinedAt.compareTo(b.joinedAt);
      return joinedCmp != 0 ? joinedCmp : a.uid.compareTo(b.uid);
    });
    return copy;
  }

  void _setSubmitting(bool submitting) {
    final current = state;
    if (current is ManageHouseholdStateLoaded) {
      emit(
        current.copyWith(
          isSubmitting: submitting,
          lastAction: ManageHouseholdAction.none,
          clearActionMessage: true,
          clearErrorMessage: true,
        ),
      );
    }
  }

  void _emitActionFailure(String message) {
    if (isClosed) return;
    final activeHousehold = _household;
    if (activeHousehold != null) {
      emit(
        ManageHouseholdStateLoaded(
          household: activeHousehold,
          members: List<Member>.unmodifiable(_members),
          memberNames: Map<String, String>.unmodifiable(_memberNames),
          harmonyScores: Map<String, int>.unmodifiable(_harmonyScores),
          currentUid: _currentUid,
          isSubmitting: false,
          lastAction: ManageHouseholdAction.none,
          errorMessage: message,
        ),
      );
    } else {
      emit(ManageHouseholdStateError(message));
    }
  }

  void _emitLoadedState({
    bool? isSubmitting,
    ManageHouseholdAction lastAction = ManageHouseholdAction.none,
    String? actionMessage,
  }) {
    if (isClosed) return;
    final activeHousehold = _household;
    if (activeHousehold == null) return;

    emit(
      ManageHouseholdStateLoaded(
        household: activeHousehold,
        members: List<Member>.unmodifiable(_members),
        memberNames: Map<String, String>.unmodifiable(_memberNames),
        harmonyScores: Map<String, int>.unmodifiable(_harmonyScores),
        currentUid: _currentUid,
        isSubmitting: isSubmitting ?? state.isSubmitting,
        lastAction: lastAction,
        actionMessage: actionMessage,
      ),
    );
  }

  String _mapErrorMessage(Object error) {
    if (error is Failure) return error.message;
    return 'Could not load household details. Please try again.';
  }

  @override
  Future<void> close() async {
    ++_session;
    await _householdSubscription?.cancel();
    await _membersSubscription?.cancel();
    await _globalCubitSubscription?.cancel();
    return super.close();
  }
}

//  Global HouseholdCubit managing current household and members

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:changa_app/core/constants/firestore_paths.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';

part 'household_state.dart';

typedef MemberNameMap = Map<String, String>;
typedef MemberNamesResolver = Future<MemberNameMap> Function(List<String> uids);
typedef CurrentUidResolver = String? Function();

class HouseholdCubit extends Cubit<HouseholdState> {
  final WatchHousehold? _watchHousehold;
  final WatchMembers? _watchMembers;
  final GetUsersByIds? _getUsersByIds;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _firebaseAuth;
  final MemberNamesResolver? _memberNamesResolver;
  final CurrentUidResolver? _currentUidResolver;

  StreamSubscription<Household?>? _householdSubscription;
  StreamSubscription<List<Member>>? _membersSubscription;

  Household? _latestHousehold;
  List<Member> _latestMembers = const [];
  MemberNameMap _cachedMemberNames = const {};
  String? _activeHouseholdId;
  String? _overrideUid;

  HouseholdCubit({
    this._watchHousehold,
    this._watchMembers,
    this._getUsersByIds,
    this._firestore,
    this._firebaseAuth,
    this._memberNamesResolver,
    this._currentUidResolver,
  }) : super(const HouseholdStateInitial());

  WatchHousehold? _resolveWatchHousehold() {
    if (_watchHousehold != null) return _watchHousehold;
    final sl = GetIt.instance;
    if (sl.isRegistered<WatchHousehold>()) {
      return sl<WatchHousehold>();
    }
    return null;
  }

  WatchMembers? _resolveWatchMembers() {
    if (_watchMembers != null) return _watchMembers;
    final sl = GetIt.instance;
    if (sl.isRegistered<WatchMembers>()) {
      return sl<WatchMembers>();
    }
    return null;
  }

  GetUsersByIds? _resolveGetUsersByIds() {
    if (_getUsersByIds != null) return _getUsersByIds;
    final sl = GetIt.instance;
    if (sl.isRegistered<GetUsersByIds>()) {
      return sl<GetUsersByIds>();
    }
    return null;
  }

  String? _resolveCurrentUid() {
    if (_overrideUid != null && _overrideUid!.isNotEmpty) {
      return _overrideUid;
    }
    final uidResolver = _currentUidResolver;
    if (uidResolver != null) {
      final uid = uidResolver();
      if (uid != null && uid.isNotEmpty) return uid;
    }
    try {
      final uid = (_firebaseAuth ?? FirebaseAuth.instance).currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {
      // Ignored in unit tests where FirebaseAuth is not initialized
    }
    return null;
  }

  Future<MemberNameMap> _fetchMemberNames(List<String> uids) async {
    final distinctUids = uids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (distinctUids.isEmpty) return const {};

    final customResolver = _memberNamesResolver;
    if (customResolver != null) {
      return customResolver(distinctUids);
    }

    final getUsersByIds = _resolveGetUsersByIds();
    if (getUsersByIds != null) {
      final result = await getUsersByIds(distinctUids);
      if (result.isSuccess && result.dataOrNull != null) {
        return {
          for (final user in result.dataOrNull!)
            user.uid: user.fullName.trim().isNotEmpty
                ? user.fullName.trim()
                : 'Former member',
        };
      }
    }

    try {
      final firestore = _firestore ?? FirebaseFirestore.instance;
      final snapshots = await Future.wait(
        distinctUids.map(
          (uid) => firestore.doc(FirestorePaths.user(uid)).get(),
        ),
      );

      final result = <String, String>{};
      for (var i = 0; i < distinctUids.length; i++) {
        final uid = distinctUids[i];
        final data = snapshots[i].data();
        final rawName = (data?[UserFields.fullName] as String?)?.trim();
        result[uid] = (rawName != null && rawName.isNotEmpty)
            ? rawName
            : 'Former member';
      }
      return result;
    } catch (_) {
      return {
        for (final uid in distinctUids)
          uid: _cachedMemberNames[uid] ?? 'Former member',
      };
    }
  }

  /// Sets the active household immediately (e.g. after creation or joining)
  /// and starts watching real-time updates for the household and its members.
  void setHousehold(Household household, {String? currentUid}) {
    if (currentUid != null && currentUid.isNotEmpty) {
      _overrideUid = currentUid;
    }
    final resolvedUid = _resolveCurrentUid() ?? household.adminUid;
    final initialMember =
        _findCurrentMember(_latestMembers, resolvedUid) ??
        Member(
          uid: resolvedUid,
          role: household.adminUid == resolvedUid
              ? MemberRole.admin
              : MemberRole.member,
          credits: 0,
          joinedAt: household.createdAt,
        );

    _latestHousehold = household;
    emit(
      HouseholdStateLoaded(
        household: household,
        members: _latestMembers.isNotEmpty ? _latestMembers : [initialMember],
        memberNames: _cachedMemberNames,
        currentMember: initialMember,
      ),
    );

    loadHousehold(household.id, currentUid: currentUid, showLoading: false);
  }

  /// Subscribes to real-time streams for `households/{householdId}` and its
  /// `members` subcollection, resolving member display names and the caller's
  /// own `Member` document.
  void loadHousehold(
    String householdId, {
    String? currentUid,
    bool showLoading = true,
  }) {
    final trimmedId = householdId.trim();
    if (trimmedId.isEmpty) {
      clearHousehold();
      return;
    }

    if (currentUid != null && currentUid.isNotEmpty) {
      _overrideUid = currentUid;
    }

    _cancelSubscriptions();
    _activeHouseholdId = trimmedId;

    if (showLoading) {
      emit(const HouseholdStateLoading());
    }

    final watchHousehold = _resolveWatchHousehold();
    final watchMembers = _resolveWatchMembers();

    if (watchHousehold == null || watchMembers == null) {
      if (_latestHousehold != null && _latestHousehold!.id == trimmedId) {
        _emitCombinedState();
      } else {
        emit(const HouseholdStateError('Household streams are not available.'));
      }
      return;
    }

    _householdSubscription = watchHousehold(trimmedId).listen(
      (household) {
        if (_activeHouseholdId != trimmedId) return;
        if (household == null) {
          _latestHousehold = null;
          _latestMembers = const [];
          emit(const HouseholdStateEmpty());
          return;
        }
        _latestHousehold = household;
        _emitCombinedState();
      },
      onError: (Object error) {
        emit(HouseholdStateError(error.toString()));
      },
    );

    _membersSubscription = watchMembers(trimmedId).listen(
      (members) async {
        if (_activeHouseholdId != trimmedId) return;
        _latestMembers = members;
        final uids = members.map((m) => m.uid).toList();
        _cachedMemberNames = await _fetchMemberNames(uids);
        if (_activeHouseholdId != trimmedId || isClosed) return;
        _emitCombinedState();
      },
      onError: (Object error) {
        emit(HouseholdStateError(error.toString()));
      },
    );
  }

  void _emitCombinedState() {
    final household = _latestHousehold;
    if (household == null) return;

    final uid = _resolveCurrentUid();
    final myMember = _findCurrentMember(_latestMembers, uid);

    emit(
      HouseholdStateLoaded(
        household: household,
        members: List<Member>.unmodifiable(_latestMembers),
        memberNames: Map<String, String>.unmodifiable(_cachedMemberNames),
        currentMember: myMember,
      ),
    );
  }

  Member? _findCurrentMember(List<Member> members, String? uid) {
    if (uid == null || uid.isEmpty) return null;
    for (final member in members) {
      if (member.uid == uid) return member;
    }
    return null;
  }

  void clearHousehold() {
    _cancelSubscriptions();
    _activeHouseholdId = null;
    _latestHousehold = null;
    _latestMembers = const [];
    _cachedMemberNames = const {};
    emit(const HouseholdStateEmpty());
  }

  void _cancelSubscriptions() {
    _householdSubscription?.cancel();
    _householdSubscription = null;
    _membersSubscription?.cancel();
    _membersSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}

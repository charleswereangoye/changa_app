// Global HouseholdCubit managing current household and members

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:changa_app/features/auth/domain/entities/app_user.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/household/domain/entities/household.dart';
import 'package:changa_app/features/household/domain/entities/member.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';

part 'household_state.dart';

typedef MemberNameMap = Map<String, String>;
typedef MemberNamesResolver = Future<MemberNameMap> Function(List<String> uids);
typedef CurrentUidResolver = String? Function();

class HouseholdCubit extends Cubit<HouseholdState> {
  final WatchHousehold? watchHousehold;
  final WatchMembers? watchMembers;
  final GetUsersByIds? getUsersByIds;
  final WatchUser? watchUser;
  final MemberNamesResolver? memberNamesResolver;
  final CurrentUidResolver? currentUidResolver;

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<Household?>? _householdSubscription;
  StreamSubscription<List<Member>>? _membersSubscription;

  Household? _latestHousehold;
  List<Member> _latestMembers = const [];
  MemberNameMap _cachedMemberNames = const {};
  String? _activeHouseholdId;
  String? _watchedUserUid;
  String? _overrideUid;
  int _loadGeneration = 0;
  int _namesRequestGeneration = 0;

  HouseholdCubit({
    this.watchHousehold,
    this.watchMembers,
    this.getUsersByIds,
    this.watchUser,
    AuthCubit? authCubit,
    this.memberNamesResolver,
    this.currentUidResolver,
  }) : super(const HouseholdStateInitial()) {
    if (authCubit != null) {
      bindAuthCubit(authCubit);
    }
  }

  /// Binds this cubit to [authCubit] so that logging in or restarting the app
  /// watches `users/{uid}.householdId` via `WatchUser` and signing out calls
  /// `clearHousehold()`.
  void bindAuthCubit(AuthCubit authCubit) {
    _authSubscription?.cancel();
    _handleAuthState(authCubit.state);
    _authSubscription = authCubit.stream.listen(_handleAuthState);
  }

  void _handleAuthState(AuthState authState) {
    if (isClosed) return;
    if (authState is Authenticated) {
      onAuthUserChanged(authState.user.uid);
    } else if (authState is Unauthenticated) {
      clearHousehold();
    }
  }

  /// Subscribes to `WatchUser(uid)` to reactively load or clear the user's
  /// household whenever `users/{uid}.householdId` changes.
  void onAuthUserChanged(String? uid) {
    if (isClosed) return;
    final cleanUid = uid?.trim() ?? '';
    if (cleanUid.isEmpty) {
      clearHousehold();
      return;
    }

    if (_watchedUserUid == cleanUid && _userSubscription != null) {
      return;
    }

    _cancelHouseholdSubscriptions();
    _userSubscription?.cancel();
    _userSubscription = null;
    _loadGeneration++;
    _namesRequestGeneration++;
    _watchedUserUid = cleanUid;
    _overrideUid = cleanUid;
    _activeHouseholdId = null;
    _latestHousehold = null;
    _latestMembers = const [];
    _cachedMemberNames = const {};

    final watcher = watchUser;
    if (watcher == null) {
      return;
    }

    _userSubscription = watcher(cleanUid).listen(
      (user) {
        if (isClosed || _watchedUserUid != cleanUid) return;
        final householdId = user?.householdId?.trim() ?? '';
        if (householdId.isEmpty) {
          _clearHouseholdStreamsOnly();
          return;
        }
        if (_activeHouseholdId != householdId) {
          loadHousehold(householdId, currentUid: cleanUid);
        }
      },
      onError: (Object error) {
        if (isClosed || _watchedUserUid != cleanUid) return;
        emit(HouseholdStateError(error.toString()));
      },
    );
  }

  String? _resolveCurrentUid() {
    if (_overrideUid != null && _overrideUid!.isNotEmpty) {
      return _overrideUid;
    }
    if (_watchedUserUid != null && _watchedUserUid!.isNotEmpty) {
      return _watchedUserUid;
    }
    final uidResolver = currentUidResolver;
    if (uidResolver != null) {
      final uid = uidResolver()?.trim();
      if (uid != null && uid.isNotEmpty) return uid;
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

    final customResolver = memberNamesResolver;
    if (customResolver != null) {
      return customResolver(distinctUids);
    }

    final usersFetcher = getUsersByIds;
    if (usersFetcher != null) {
      final result = await usersFetcher(distinctUids);
      if (result.isSuccess && result.dataOrNull != null) {
        return {
          for (final user in result.dataOrNull!)
            user.uid: user.fullName.trim().isNotEmpty
                ? user.fullName.trim()
                : 'Former member',
        };
      }
    }

    return {
      for (final uid in distinctUids)
        uid: _cachedMemberNames[uid] ?? 'Former member',
    };
  }

  /// Sets the active household immediately (e.g. after creation or joining)
  /// and starts watching real-time updates for the household and its members.
  void setHousehold(Household household, {String? currentUid}) {
    if (isClosed) return;

    final cleanCurrentUid = currentUid?.trim();
    if (cleanCurrentUid != null && cleanCurrentUid.isNotEmpty) {
      if (_overrideUid != null && _overrideUid != cleanCurrentUid) {
        _latestMembers = const [];
        _cachedMemberNames = const {};
      }
      _overrideUid = cleanCurrentUid;
    } else if (_watchedUserUid != null) {
      _overrideUid = _watchedUserUid;
    }

    if (_activeHouseholdId != null && _activeHouseholdId != household.id) {
      _latestMembers = const [];
      _cachedMemberNames = const {};
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
    _activeHouseholdId = household.id;
    emit(
      HouseholdStateLoaded(
        household: household,
        members: _latestMembers.isNotEmpty ? _latestMembers : [initialMember],
        memberNames: _cachedMemberNames,
        currentMember: initialMember,
      ),
    );

    loadHousehold(
      household.id,
      currentUid: cleanCurrentUid,
      showLoading: false,
      preserveInitialHousehold: true,
    );
  }

  /// Subscribes to real-time streams for `households/{householdId}` and its
  /// `members` subcollection, resolving member display names and the caller's
  /// own `Member` document.
  void loadHousehold(
    String householdId, {
    String? currentUid,
    bool showLoading = true,
    bool preserveInitialHousehold = false,
  }) {
    if (isClosed) return;

    final trimmedId = householdId.trim();
    if (trimmedId.isEmpty) {
      _clearHouseholdStreamsOnly();
      return;
    }

    final cleanUid = currentUid?.trim();
    final isHouseholdSwitch = _activeHouseholdId != trimmedId;
    final isCallerSwitch =
        cleanUid != null && cleanUid.isNotEmpty && _overrideUid != cleanUid;

    _cancelHouseholdSubscriptions();
    final loadGen = ++_loadGeneration;
    _namesRequestGeneration++;

    if (cleanUid != null && cleanUid.isNotEmpty) {
      _overrideUid = cleanUid;
    } else if (_watchedUserUid != null && _watchedUserUid!.isNotEmpty) {
      _overrideUid = _watchedUserUid;
    } else if (isHouseholdSwitch) {
      _overrideUid = null;
    }

    if (isHouseholdSwitch || isCallerSwitch) {
      if (!preserveInitialHousehold) {
        _latestHousehold = null;
      }
      _latestMembers = const [];
      _cachedMemberNames = const {};
    }

    _activeHouseholdId = trimmedId;

    if (showLoading) {
      emit(const HouseholdStateLoading());
    }

    final householdWatcher = watchHousehold;
    final membersWatcher = watchMembers;

    if (householdWatcher == null || membersWatcher == null) {
      if (_latestHousehold != null && _latestHousehold!.id == trimmedId) {
        _emitCombinedState();
      } else {
        emit(const HouseholdStateError('Household streams are not available.'));
      }
      return;
    }

    _householdSubscription = householdWatcher(trimmedId).listen(
      (household) {
        if (isClosed ||
            _activeHouseholdId != trimmedId ||
            loadGen != _loadGeneration) {
          return;
        }
        if (household == null) {
          _latestHousehold = null;
          _latestMembers = const [];
          _cachedMemberNames = const {};
          emit(const HouseholdStateEmpty());
          return;
        }
        _latestHousehold = household;
        _emitCombinedState();
      },
      onError: (Object error) {
        if (isClosed ||
            _activeHouseholdId != trimmedId ||
            loadGen != _loadGeneration) {
          return;
        }
        emit(HouseholdStateError(error.toString()));
      },
    );

    _membersSubscription = membersWatcher(trimmedId).listen(
      (members) async {
        if (isClosed ||
            _activeHouseholdId != trimmedId ||
            loadGen != _loadGeneration) {
          return;
        }
        _latestMembers = members;
        final uids = members.map((m) => m.uid).toList();
        final namesReqId = ++_namesRequestGeneration;
        final fetchedNames = await _fetchMemberNames(uids);

        if (isClosed ||
            _activeHouseholdId != trimmedId ||
            loadGen != _loadGeneration ||
            namesReqId != _namesRequestGeneration) {
          return;
        }
        _cachedMemberNames = fetchedNames;
        _emitCombinedState();
      },
      onError: (Object error) {
        if (isClosed ||
            _activeHouseholdId != trimmedId ||
            loadGen != _loadGeneration) {
          return;
        }
        emit(HouseholdStateError(error.toString()));
      },
    );
  }

  void _emitCombinedState() {
    if (isClosed) return;
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

  void _clearHouseholdStreamsOnly() {
    _cancelHouseholdSubscriptions();
    _loadGeneration++;
    _namesRequestGeneration++;
    _activeHouseholdId = null;
    _latestHousehold = null;
    _latestMembers = const [];
    _cachedMemberNames = const {};
    if (!isClosed) {
      emit(const HouseholdStateEmpty());
    }
  }

  /// Clears all household state, cached member names, caller overrides, and
  /// user subscriptions (called on sign-out).
  void clearHousehold() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _watchedUserUid = null;
    _overrideUid = null;
    _clearHouseholdStreamsOnly();
  }

  void _cancelHouseholdSubscriptions() {
    _householdSubscription?.cancel();
    _householdSubscription = null;
    _membersSubscription?.cancel();
    _membersSubscription = null;
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _userSubscription?.cancel();
    _userSubscription = null;
    _cancelHouseholdSubscriptions();
    return super.close();
  }
}

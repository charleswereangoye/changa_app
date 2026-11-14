// States for ManageHouseholdCubit

part of 'manage_household_cubit.dart';

enum ManageHouseholdAction {
  none,
  pinRegenerated,
  adminTransferred,
  memberRemoved,
  leftHousehold,
}

abstract class ManageHouseholdState extends Equatable {
  const ManageHouseholdState();

  Household? get household => null;
  List<Member> get members => const [];
  Map<String, String> get memberNames => const {};
  Map<String, int> get harmonyScores => const {};
  String? get currentUid => null;
  bool get isSubmitting => false;
  ManageHouseholdAction get lastAction => ManageHouseholdAction.none;
  String? get actionMessage => null;
  String? get errorMessage => null;

  bool get isAdmin {
    final activeHousehold = household;
    final uid = currentUid?.trim();
    if (activeHousehold != null &&
        uid != null &&
        uid.isNotEmpty &&
        activeHousehold.adminUid == uid) {
      return true;
    }
    if (uid != null && uid.isNotEmpty) {
      for (final member in members) {
        if (member.uid == uid) {
          return member.role == MemberRole.admin;
        }
      }
    }
    return false;
  }

  String displayNameFor(String uid) {
    final name = memberNames[uid]?.trim();
    if (name == null || name.isEmpty) {
      return 'Former member';
    }
    return name;
  }

  @override
  List<Object?> get props => [];
}

class ManageHouseholdStateInitial extends ManageHouseholdState {
  const ManageHouseholdStateInitial();
}

class ManageHouseholdStateLoading extends ManageHouseholdState {
  const ManageHouseholdStateLoading();
}

class ManageHouseholdStateLoaded extends ManageHouseholdState {
  @override
  final Household household;

  @override
  final List<Member> members;

  @override
  final Map<String, String> memberNames;

  @override
  final Map<String, int> harmonyScores;

  @override
  final String? currentUid;

  @override
  final bool isSubmitting;

  @override
  final ManageHouseholdAction lastAction;

  @override
  final String? actionMessage;

  @override
  final String? errorMessage;

  const ManageHouseholdStateLoaded({
    required this.household,
    this.members = const [],
    this.memberNames = const {},
    this.harmonyScores = const {},
    this.currentUid,
    this.isSubmitting = false,
    this.lastAction = ManageHouseholdAction.none,
    this.actionMessage,
    this.errorMessage,
  });

  ManageHouseholdStateLoaded copyWith({
    Household? household,
    List<Member>? members,
    Map<String, String>? memberNames,
    Map<String, int>? harmonyScores,
    String? currentUid,
    bool? isSubmitting,
    ManageHouseholdAction? lastAction,
    String? actionMessage,
    bool clearActionMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ManageHouseholdStateLoaded(
      household: household ?? this.household,
      members: members ?? this.members,
      memberNames: memberNames ?? this.memberNames,
      harmonyScores: harmonyScores ?? this.harmonyScores,
      currentUid: currentUid ?? this.currentUid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastAction: lastAction ?? this.lastAction,
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    household,
    members,
    memberNames,
    harmonyScores,
    currentUid,
    isSubmitting,
    lastAction,
    actionMessage,
    errorMessage,
  ];
}

class ManageHouseholdStateError extends ManageHouseholdState {
  final String message;

  const ManageHouseholdStateError(this.message);

  @override
  String? get errorMessage => message;

  @override
  List<Object?> get props => [message];
}

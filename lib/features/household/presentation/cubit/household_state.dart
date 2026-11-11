// States for HouseholdCubit

part of 'household_cubit.dart';

abstract class HouseholdState extends Equatable {
  const HouseholdState();

  Household? get household => null;
  List<Member> get members => const [];
  Map<String, String> get memberNames => const {};
  Member? get currentMember => null;
  Member? get myMember => currentMember;
  int get myCredits => currentMember?.credits ?? 0;
  bool get hasHousehold => household != null;

  bool get isAdmin {
    if (currentMember != null) {
      return currentMember!.role == MemberRole.admin;
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

class HouseholdStateInitial extends HouseholdState {
  const HouseholdStateInitial();
}

class HouseholdStateLoading extends HouseholdState {
  const HouseholdStateLoading();
}

class HouseholdStateEmpty extends HouseholdState {
  const HouseholdStateEmpty();
}

class HouseholdStateLoaded extends HouseholdState {
  @override
  final Household household;

  @override
  final List<Member> members;

  @override
  final Map<String, String> memberNames;

  @override
  final Member? currentMember;

  const HouseholdStateLoaded({
    required this.household,
    this.members = const [],
    this.memberNames = const {},
    this.currentMember,
  });

  HouseholdStateLoaded copyWith({
    Household? household,
    List<Member>? members,
    Map<String, String>? memberNames,
    Member? currentMember,
    bool clearCurrentMember = false,
  }) {
    return HouseholdStateLoaded(
      household: household ?? this.household,
      members: members ?? this.members,
      memberNames: memberNames ?? this.memberNames,
      currentMember: clearCurrentMember
          ? null
          : (currentMember ?? this.currentMember),
    );
  }

  @override
  List<Object?> get props => [household, members, memberNames, currentMember];
}

class HouseholdStateError extends HouseholdState {
  final String message;

  const HouseholdStateError(this.message);

  @override
  List<Object?> get props => [message];
}

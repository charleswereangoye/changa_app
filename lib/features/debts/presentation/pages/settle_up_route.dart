import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/pref_keys.dart';
import '../../../../core/enums/settlement_method.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../household/domain/usecases/watch_members.dart';
import '../../../profile/domain/services/preferences_service.dart';
import '../../../profile/domain/usecases/get_users_by_ids.dart';
import '../../../profile/domain/usecases/watch_user.dart';
import '../../domain/usecases/get_balance_summary.dart';
import '../../domain/usecases/settle_between.dart';
import '../cubit/settle_cubit.dart';
import 'settle_up_page.dart';

class SettleUpRoute extends StatelessWidget {
  const SettleUpRoute({super.key, required this.otherUid});

  final String otherUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateInitial || state is AuthStateLoading) {
          return _routeScaffold();
        }

        if (state is! Authenticated) {
          return _routeScaffold(
            message: 'Please sign in to settle shared balances.',
          );
        }

        if (otherUid.isEmpty || otherUid == state.user.uid) {
          return _routeScaffold(message: 'Choose a housemate to settle with.');
        }

        return _UserSettlement(
          key: ValueKey((state.user.uid, otherUid)),
          uid: state.user.uid,
          otherUid: otherUid,
        );
      },
    );
  }
}

class _UserSettlement extends StatefulWidget {
  const _UserSettlement({super.key, required this.uid, required this.otherUid});

  final String uid;
  final String otherUid;

  @override
  State<_UserSettlement> createState() => _UserSettlementState();
}

class _UserSettlementState extends State<_UserSettlement> {
  late final Stream<AppUser?> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = GetIt.instance<WatchUser>()(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _routeScaffold(
            message:
                'Your profile could not be loaded. Please try again later.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _routeScaffold();
        }

        final user = snapshot.data;
        if (user == null) {
          return _routeScaffold(
            message: 'Your profile is unavailable. Please sign in again.',
          );
        }

        final householdId = user.householdId;
        if (householdId == null || householdId.isEmpty) {
          return _routeScaffold(
            message: 'Join a household to settle shared balances.',
          );
        }

        return _HouseholdSettlement(
          key: ValueKey((householdId, widget.uid, widget.otherUid)),
          householdId: householdId,
          uid: widget.uid,
          otherUid: widget.otherUid,
        );
      },
    );
  }
}

class _HouseholdSettlement extends StatefulWidget {
  const _HouseholdSettlement({
    super.key,
    required this.householdId,
    required this.uid,
    required this.otherUid,
  });

  final String householdId;
  final String uid;
  final String otherUid;

  @override
  State<_HouseholdSettlement> createState() => _HouseholdSettlementState();
}

class _HouseholdSettlementState extends State<_HouseholdSettlement> {
  late final Future<SettlementMethod> _defaultMethod;
  late final Stream<Map<String, String>> _memberNames;

  @override
  void initState() {
    super.initState();

    final sl = GetIt.instance;
    _defaultMethod = _loadDefaultMethod();

    _memberNames = sl<WatchMembers>()(widget.householdId).asyncMap((
      members,
    ) async {
      final uids = members.map((member) => member.uid).toList();

      if (uids.isEmpty) {
        return <String, String>{};
      }

      final result = await sl<GetUsersByIds>()(uids);

      // Current members remain "Housemate" if their names cannot load.
      return <String, String>{
        for (final uid in uids) uid: 'Housemate',
        for (final user in result.dataOrNull ?? const <AppUser>[])
          if (user.fullName.trim().isNotEmpty) user.uid: user.fullName.trim(),
      };
    });
  }

  Future<SettlementMethod> _loadDefaultMethod() async {
    final raw = await GetIt.instance<PreferencesService>().getString(
      PrefKeys.defaultSettlementMethod,
      fallback: SettlementMethod.momo.name,
    );

    final method =
        SettlementMethod.values.asNameMap()[raw] ?? SettlementMethod.momo;

    return method == SettlementMethod.credits ? SettlementMethod.momo : method;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SettlementMethod>(
      future: _defaultMethod,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _routeScaffold(
            message:
                'Your payment preference could not be loaded. '
                'Please reopen this screen to try again.',
          );
        }

        if (!snapshot.hasData) {
          return _routeScaffold();
        }

        final sl = GetIt.instance;

        return BlocProvider<SettleCubit>(
          create: (_) => SettleCubit(
            getBalanceSummary: sl<GetBalanceSummary>(),
            settleBetween: sl<SettleBetween>(),
            householdId: widget.householdId,
            meUid: widget.uid,
            initialOtherUid: widget.otherUid,
            defaultMethod: snapshot.data!,
          )..load(),
          child: StreamBuilder<Map<String, String>>(
            stream: _memberNames,
            builder: (context, namesSnapshot) {
              return SettleUpPage(memberNames: namesSnapshot.data ?? const {});
            },
          ),
        );
      },
    );
  }
}

Widget _routeScaffold({String? message}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Settle Up')),
    body: Center(
      child: message == null
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
    ),
  );
}

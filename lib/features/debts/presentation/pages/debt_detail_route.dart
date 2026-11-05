import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../expenses/domain/usecases/watch_expenses.dart';
import '../../../profile/domain/usecases/watch_user.dart';
import '../../domain/usecases/send_nudge.dart';
import '../../domain/usecases/watch_debts_between.dart';
import '../cubit/debt_detail_cubit.dart';
import 'debt_detail_page.dart';

class DebtDetailRoute extends StatelessWidget {
  const DebtDetailRoute({super.key, required this.otherUid});

  final String otherUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateInitial || state is AuthStateLoading) {
          return const _RouteLoading();
        }

        if (state is! Authenticated) {
          return const _RouteMessage(
            'Please sign in to view your shared balances.',
          );
        }

        if (otherUid.isEmpty || otherUid == state.user.uid) {
          return const _RouteMessage(
            'Choose a housemate to view shared balances.',
          );
        }

        return _UserDebtRoute(
          key: ValueKey((state.user.uid, otherUid)),
          uid: state.user.uid,
          otherUid: otherUid,
        );
      },
    );
  }
}

class _UserDebtRoute extends StatefulWidget {
  const _UserDebtRoute({super.key, required this.uid, required this.otherUid});

  final String uid;
  final String otherUid;

  @override
  State<_UserDebtRoute> createState() => _UserDebtRouteState();
}

class _UserDebtRouteState extends State<_UserDebtRoute> {
  late final Stream<AppUser?> _userStream;
  late final Stream<AppUser?> _housemateStream;

  @override
  void initState() {
    super.initState();

    final watchUser = GetIt.instance<WatchUser>();
    _userStream = watchUser(widget.uid);
    _housemateStream = watchUser(widget.otherUid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _housemateStream,
      builder: (context, housemateSnapshot) {
        final fullName = housemateSnapshot.hasError
            ? null
            : housemateSnapshot.data?.fullName.trim();

        final loadingHousemate =
            housemateSnapshot.connectionState == ConnectionState.waiting;

        final name = fullName != null && fullName.isNotEmpty
            ? fullName
            : loadingHousemate
            ? 'Housemate'
            : 'Former member';

        return StreamBuilder<AppUser?>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _RouteMessage(
                'Your profile could not be loaded. Please try again later.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _RouteLoading();
            }

            final user = snapshot.data;

            if (user == null) {
              return const _RouteMessage(
                'Your profile is unavailable. Please sign in again.',
              );
            }

            final householdId = user.householdId;

            if (householdId == null || householdId.isEmpty) {
              return const _RouteMessage(
                'Join a household to view shared balances.',
              );
            }

            final sl = GetIt.instance;

            return BlocProvider<DebtDetailCubit>(
              key: ValueKey((householdId, widget.uid, widget.otherUid)),
              create: (_) => DebtDetailCubit(
                watchDebtsBetween: sl<WatchDebtsBetween>(),
                watchExpenses: sl<WatchExpenses>(),
                sendNudge: sl<SendNudge>(),
                householdId: householdId,
                meUid: widget.uid,
                otherUid: widget.otherUid,
              )..load(),
              child: DebtDetailPage(housemateName: name),
            );
          },
        );
      },
    );
  }
}

class _RouteLoading extends StatelessWidget {
  const _RouteLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt & Nudge')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _RouteMessage extends StatelessWidget {
  const _RouteMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debt & Nudge')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

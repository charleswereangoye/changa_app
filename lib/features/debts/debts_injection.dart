import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'data/datasources/debt_remote_datasource.dart';
import 'data/repositories/debt_repository_impl.dart';
import 'domain/repositories/debt_repository.dart';
import 'domain/usecases/get_outstanding_balance.dart';
import 'domain/usecases/send_nudge.dart';
import 'domain/usecases/settle_between.dart';
import 'domain/usecases/watch_debts_between.dart';
import 'domain/usecases/watch_debts_since.dart';
import 'domain/usecases/watch_pending_debts.dart';

final sl = GetIt.instance;

Future<void> initDebts() async {
  // Reuse shared Firebase instances if another feature registered them.
  if (!sl.isRegistered<FirebaseFirestore>()) {
    sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  if (!sl.isRegistered<FirebaseAuth>()) {
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  if (!sl.isRegistered<DebtRemoteDataSource>()) {
    sl.registerLazySingleton<DebtRemoteDataSource>(
      () => DebtRemoteDataSource(sl<FirebaseFirestore>()),
    );
  }

  if (!sl.isRegistered<DebtRepository>()) {
    sl.registerLazySingleton<DebtRepository>(
      () => DebtRepositoryImpl(sl<DebtRemoteDataSource>(), sl<FirebaseAuth>()),
    );
  }

  if (!sl.isRegistered<WatchPendingDebts>()) {
    sl.registerLazySingleton<WatchPendingDebts>(
      () => WatchPendingDebts(sl<DebtRepository>()),
    );
  }

  if (!sl.isRegistered<WatchDebtsSince>()) {
    sl.registerLazySingleton<WatchDebtsSince>(
      () => WatchDebtsSince(sl<DebtRepository>()),
    );
  }

  if (!sl.isRegistered<WatchDebtsBetween>()) {
    sl.registerLazySingleton<WatchDebtsBetween>(
      () => WatchDebtsBetween(sl<DebtRepository>()),
    );
  }

  if (!sl.isRegistered<SettleBetween>()) {
    sl.registerLazySingleton<SettleBetween>(
      () => SettleBetween(sl<DebtRepository>()),
    );
  }

  if (!sl.isRegistered<SendNudge>()) {
    sl.registerLazySingleton<SendNudge>(() => SendNudge(sl<DebtRepository>()));
  }

  if (!sl.isRegistered<GetOutstandingBalance>()) {
    sl.registerLazySingleton<GetOutstandingBalance>(
      () => GetOutstandingBalance(sl<DebtRepository>()),
    );
  }
}

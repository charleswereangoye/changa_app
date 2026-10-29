// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Dependency injection registration for Expenses feature

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/notifications/data/notification_writer.dart';

import 'data/datasources/expense_remote_datasource.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'domain/repositories/expense_repository.dart';
import 'domain/usecases/add_expense.dart';
import 'domain/usecases/delete_expense.dart';
import 'domain/usecases/update_expense_note.dart';
import 'domain/usecases/watch_expenses.dart';

final sl = GetIt.instance;

Future<void> initExpenses() async {
  // Remote data source. The writers are built here so the expense batch can
  // add its activity line and notifications to the same batch.
  if (!sl.isRegistered<ExpenseRemoteDataSource>()) {
    sl.registerLazySingleton<ExpenseRemoteDataSource>(() {
      final firestore = FirebaseFirestore.instance;
      return ExpenseRemoteDataSource(
        firestore: firestore,
        activityWriter: ActivityWriter(firestore: firestore),
        notificationWriter: NotificationWriter(firestore),
        currentUid: () => FirebaseAuth.instance.currentUser?.uid,
      );
    });
  }

  // Repository
  if (!sl.isRegistered<ExpenseRepository>()) {
    sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(remoteDataSource: sl()),
    );
  }

  // Use cases
  if (!sl.isRegistered<AddExpense>()) {
    sl.registerLazySingleton(() => AddExpense(sl()));
  }
  if (!sl.isRegistered<WatchExpenses>()) {
    sl.registerLazySingleton(() => WatchExpenses(sl()));
  }
  if (!sl.isRegistered<UpdateExpenseNote>()) {
    sl.registerLazySingleton(() => UpdateExpenseNote(sl()));
  }
  if (!sl.isRegistered<DeleteExpense>()) {
    sl.registerLazySingleton(() => DeleteExpense(sl()));
  }
}

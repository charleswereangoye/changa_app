import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:changa_app/features/activity/data/activity_writer.dart';
import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/chores/domain/usecases/reassign_chores.dart';
import 'package:changa_app/features/debts/domain/usecases/get_outstanding_balance.dart';
import 'package:changa_app/features/household/data/datasources/household_remote_datasource.dart';
import 'package:changa_app/features/household/data/repositories/household_repository_impl.dart';
import 'package:changa_app/features/household/domain/repositories/household_repository.dart';
import 'package:changa_app/features/household/domain/usecases/create_household.dart';
import 'package:changa_app/features/household/domain/usecases/join_household.dart';
import 'package:changa_app/features/household/domain/usecases/leave_household.dart';
import 'package:changa_app/features/household/domain/usecases/preview_household_by_pin.dart';
import 'package:changa_app/features/household/domain/usecases/regenerate_pin.dart';
import 'package:changa_app/features/household/domain/usecases/remove_member.dart';
import 'package:changa_app/features/household/domain/usecases/transfer_admin.dart';
import 'package:changa_app/features/household/domain/usecases/watch_household.dart';
import 'package:changa_app/features/household/domain/usecases/watch_members.dart';
import 'package:changa_app/features/household/presentation/cubit/create_household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/join_household_cubit.dart';
import 'package:changa_app/features/household/presentation/cubit/manage_household_cubit.dart';
import 'package:changa_app/features/profile/domain/usecases/get_users_by_ids.dart';
import 'package:changa_app/features/profile/domain/usecases/watch_user.dart';

void initHousehold(GetIt sl) {
  // Data sources
  if (!sl.isRegistered<HouseholdRemoteDataSource>()) {
    sl.registerLazySingleton<HouseholdRemoteDataSource>(
      () => HouseholdRemoteDataSourceImpl(
        firestore: sl.isRegistered<FirebaseFirestore>()
            ? sl<FirebaseFirestore>()
            : FirebaseFirestore.instance,
        activityWriter: sl.isRegistered<ActivityWriter>()
            ? sl<ActivityWriter>()
            : ActivityWriter(),
      ),
    );
  }

  // Repository
  if (!sl.isRegistered<HouseholdRepository>()) {
    sl.registerLazySingleton<HouseholdRepository>(
      () => HouseholdRepositoryImpl(
        remoteDataSource: sl<HouseholdRemoteDataSource>(),
        firebaseAuth: sl.isRegistered<FirebaseAuth>()
            ? sl<FirebaseAuth>()
            : FirebaseAuth.instance,
      ),
    );
  }

  // Use cases
  if (!sl.isRegistered<CreateHousehold>()) {
    sl.registerLazySingleton(() => CreateHousehold(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<PreviewHouseholdByPin>()) {
    sl.registerLazySingleton(
      () => PreviewHouseholdByPin(sl<HouseholdRepository>()),
    );
  }
  if (!sl.isRegistered<JoinHousehold>()) {
    sl.registerLazySingleton(() => JoinHousehold(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<RegeneratePin>()) {
    sl.registerLazySingleton(() => RegeneratePin(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<RemoveMember>()) {
    sl.registerLazySingleton(() => RemoveMember(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<TransferAdmin>()) {
    sl.registerLazySingleton(() => TransferAdmin(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<LeaveHousehold>()) {
    sl.registerLazySingleton(() => LeaveHousehold(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<WatchHousehold>()) {
    sl.registerLazySingleton(() => WatchHousehold(sl<HouseholdRepository>()));
  }
  if (!sl.isRegistered<WatchMembers>()) {
    sl.registerLazySingleton(() => WatchMembers(sl<HouseholdRepository>()));
  }

  // Cubits (B8 & B12)
  if (!sl.isRegistered<HouseholdCubit>()) {
    sl.registerLazySingleton<HouseholdCubit>(
      () => HouseholdCubit(
        watchHousehold: sl<WatchHousehold>(),
        watchMembers: sl<WatchMembers>(),
        getUsersByIds: sl.isRegistered<GetUsersByIds>()
            ? sl<GetUsersByIds>()
            : null,
        watchUser: sl.isRegistered<WatchUser>() ? sl<WatchUser>() : null,
        authCubit: sl.isRegistered<AuthCubit>() ? sl<AuthCubit>() : null,
      ),
    );
  }
  if (!sl.isRegistered<CreateHouseholdCubit>()) {
    sl.registerFactory<CreateHouseholdCubit>(
      () => CreateHouseholdCubit(createHousehold: sl<CreateHousehold>()),
    );
  }
  if (!sl.isRegistered<JoinHouseholdCubit>()) {
    sl.registerFactory<JoinHouseholdCubit>(
      () => JoinHouseholdCubit(
        previewHouseholdByPin: sl<PreviewHouseholdByPin>(),
        joinHousehold: sl<JoinHousehold>(),
      ),
    );
  }
  if (!sl.isRegistered<ManageHouseholdCubit>()) {
    sl.registerFactory<ManageHouseholdCubit>(
      () => ManageHouseholdCubit(
        watchHousehold: sl<WatchHousehold>(),
        watchMembers: sl<WatchMembers>(),
        getUsersByIds: sl.isRegistered<GetUsersByIds>()
            ? sl<GetUsersByIds>()
            : null,
        regeneratePin: sl<RegeneratePin>(),
        removeMember: sl<RemoveMember>(),
        transferAdmin: sl<TransferAdmin>(),
        leaveHousehold: sl<LeaveHousehold>(),
        getOutstandingBalance: sl.isRegistered<GetOutstandingBalance>()
            ? sl<GetOutstandingBalance>()
            : null,
        reassignChores: sl.isRegistered<ReassignChores>()
            ? sl<ReassignChores>()
            : null,
        householdCubit: sl.isRegistered<HouseholdCubit>()
            ? sl<HouseholdCubit>()
            : null,
      ),
    );
  }
}

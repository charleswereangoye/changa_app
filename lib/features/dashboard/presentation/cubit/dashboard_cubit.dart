// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Description: Cubit combining streams for the main Dashboard view

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardStateInitial());
}

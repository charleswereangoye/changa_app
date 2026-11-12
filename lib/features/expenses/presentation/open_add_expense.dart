import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:changa_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:changa_app/features/expenses/presentation/cubit/add_expense_state.dart';
import 'package:changa_app/features/expenses/presentation/pages/add_expense_page.dart';
import 'package:changa_app/features/household/presentation/cubit/household_cubit.dart';

Future<void> openAddExpense(BuildContext context) async {
  final household = context.read<HouseholdCubit>().state;
  final uid = context.read<AuthCubit>().state.user?.uid;
  final householdId = household.household?.id;

  if (householdId == null || uid == null || household.members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Join or create a household before adding an expense.'),
      ),
    );
    return;
  }

  final participants = [
    for (final member in household.members)
      ExpenseParticipant(
        uid: member.uid,
        name: household.displayNameFor(member.uid),
        credits: member.credits,
      ),
  ];

  await AddExpensePage.show(
    context,
    householdId: householdId,
    currentUid: uid,
    participants: participants,
  );
}

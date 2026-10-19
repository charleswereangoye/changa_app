// Owner: C - Person C (Expenses, Dashboard, Documentation)
// Screen: Home Dashboard Screen: harmony, balances, actions, recent activity

import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DashboardPage')),
      body: const Center(child: Text('DashboardPage Placeholder')),
    );
  }
}

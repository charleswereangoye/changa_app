// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Root App widget: MultiBlocProvider, MaterialApp.router, theme configuration

import 'package:flutter/material.dart';

class ChangaApp extends StatelessWidget {
  const ChangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Changa',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B4D3E),
      ),
      home: const Scaffold(
        body: Center(child: Text('Changa - Roommate Shared Living')),
      ),
    );
  }
}

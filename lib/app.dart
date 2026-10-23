import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

/// The root widget of the Changa application.
class ChangaApp extends StatelessWidget {
  const ChangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Changa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}

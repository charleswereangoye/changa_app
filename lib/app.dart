import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';

/// The root widget of the Changa application.
class ChangaApp extends StatelessWidget {
  const ChangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Changa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}

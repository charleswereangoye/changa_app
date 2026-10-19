// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Splash Screen: checks saved session and routes user

import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SplashPage')),
      body: const Center(child: Text('SplashPage Placeholder')),
    );
  }
}

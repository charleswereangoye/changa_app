// Owner: A - Person A (Foundation, Authentication, Profile)
// Screen: Login Screen: email, password, Google, forgot password link

import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LoginPage')),
      body: const Center(child: Text('LoginPage Placeholder')),
    );
  }
}

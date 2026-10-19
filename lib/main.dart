// Owner: A - Person A (Foundation, Authentication, Profile)
// Description: Main entrypoint: initializes services and runs the app

import 'package:flutter/material.dart';
import 'package:changa_app/app.dart';
import 'package:changa_app/injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const ChangaApp());
}

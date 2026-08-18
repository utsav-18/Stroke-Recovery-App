import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StrokeRecoveryApp());
}

class StrokeRecoveryApp extends StatelessWidget {
  const StrokeRecoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RehabTrack',
      theme: appTheme,
      home: const LoginScreen(),
    );
  }
}

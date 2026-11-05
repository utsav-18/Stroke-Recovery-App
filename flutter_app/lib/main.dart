import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  ApiService().setBaseUrl(AppConfig.apiBaseUrl);
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

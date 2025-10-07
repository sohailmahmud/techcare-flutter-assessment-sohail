import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/app_navigation.dart';

void main() {
  runApp(const FinTrackApp());
}

/// Root widget of the FinTrack application
/// Configures the MaterialApp with theme and initial route
class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppNavigationPage(),
    );
  }
}

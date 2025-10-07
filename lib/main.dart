import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'presentation/app_navigation.dart';
import 'presentation/transactions/bloc/transactions_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const FinTrackApp());
}

/// Root widget of the FinTrack application
/// Configures the MaterialApp with theme and initial route
class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TransactionsBloc>(),
      child: MaterialApp(
        title: 'Personal Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppNavigationPage(),
      ),
    );
  }
}

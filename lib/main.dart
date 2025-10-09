import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/router/app_router.dart';
import 'presentation/transactions/list/bloc/transactions_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await di.init();
  
  // Set up BLoC observer for debugging and monitoring
  Bloc.observer = AppBlocObserver();
  
  runApp(const FinTrackApp());
}

/// Root widget of the FinTrack application
/// Configures the MaterialApp with go_router for navigation
class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TransactionsBloc>(),
      child: MaterialApp.router(
        title: 'Personal Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
